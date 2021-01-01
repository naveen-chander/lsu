----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.12.2020 10:21:16
-- Design Name: 
-- Module Name: lsu - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity lsu is
    Port  ( 
		   clk 				: in  STD_LOGIC;
           reset 			: in  STD_LOGIC;
		   start			: in  STD_LOGIC;							-- FSM Init
		   RS1				: in  STD_LOGIC_VECTOR(31 DOWNTO 0);		-- Scalar Reg Store Data
		   RS2				: in  STD_LOGIC_VECTOR(31 DOWNTO 0);		-- ScalarReg Store Addr/Data
		   IMM				: in  STD_LOGIC_VECTOR(31 DOWNTO 0);		-- S.ext Immediate Value
		   SEW				: in  STD_LOGIC_VECTOR(1 DOWNTO 0);			-- Single Elemnt Width
		   WIDTH			: in  STD_LOGIC_VECTOR(1 DOWNTO 0);			-- Single Elemnt Width
		   LMUL				: in  STD_LOGIC_VECTOR(2 DOWNTO 0);			-- Vector LENGTH Multiplicity
		   MOP    			: in  STD_LOGIC_VECTOR(1 DOWNTO 0);			-- Load Store type {Scalar + vector}
		   S_VECn           : in  STD_LOGIC;                            -- Scalar /Vectorn
		   MASK             : in  STD_LOGIC;                            -- =0 if Mask=>Do not Store this incoming element
		   V_DATA_WR		: in  STD_LOGIC_VECTOR(31 DOWNTO 0);		-- Data From Vector RegFile
		   V_OFFSET			: in  STD_LOGIC_VECTOR(31 DOWNTO 0);		-- Offsets From Vector RegFile
           D_CS 			: in  STD_LOGIC;							-- For PortA and PortB Enable
           D_WE 			: in  STD_LOGIC;							-- Data Write Enable
           D_RE 			: in  STD_LOGIC;							-- Data Write Enable
		   ILLEGAL			: out STD_LOGIC;							-- Illegal Instruction
		   DONE				: out STD_LOGIC;
           DATA_RD			: out STD_LOGIC_VECTOR(31 downto 0)  		-- Read Data (Common port for Vec and Scal)
		   );
end lsu;

architecture Behavioral of lsu is
COMPONENT DMEM
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb : IN STD_LOGIC;
    enb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;

--Signals
signal count			:	STD_LOGIC_VECTOR(7 downto 0);
signal terminate		:	STD_LOGIC;
signal expire			:	STD_LOGIC;
signal ENA  			:	STD_LOGIC;
signal WE   			:	STD_LOGIC;
signal OE   			:	STD_LOGIC;
signal terminal_count	:	STD_LOGIC_VECTOR(7 downto 0);
signal ADDER_OUT		: 	STD_LOGIC_VECTOR(32 downto 0);
signal DADDR    		: 	STD_LOGIC_VECTOR(10 downto 0);
signal vec_offset1    	: 	STD_LOGIC_VECTOR(31 downto 0);
signal vec_offset    	: 	STD_LOGIC_VECTOR(31 downto 0);
signal base_addr    	: 	STD_LOGIC_VECTOR(31 downto 0);
signal adder_a         	: 	STD_LOGIC_VECTOR(31 downto 0);
signal adder_b         	: 	STD_LOGIC_VECTOR(31 downto 0);
signal D_DIN         	: 	STD_LOGIC_VECTOR(31 downto 0);
signal count32         	: 	STD_LOGIC_VECTOR(31 downto 0);
signal DMEM_offset     	: 	STD_LOGIC_VECTOR(31 downto 0);
signal DMEM_offset64    : 	STD_LOGIC_VECTOR(63 downto 0);
signal EEW              :   STD_LOGIC_VECTOR(1 downto 0);

begin
-- Instantiate DMEM
DMEM_0: DMEM port map(
clka 	=> clk,
ena     => ENA,
wea(0)  => WE,
addra   => DADDR,
dina    => D_DIN,
clkb    => clk,
enb     => OE,
addrb   => DADDR,
doutb   => DATA_RD);


--------EEW Logic
EEW <= SEW when MOP = "11"  else
       WIDTH; 
 -- 8-bit Synchronous Counter
process(clk,reset)
begin
    if(reset = '1') then
        count <= (others=>'0');
	elsif(rising_edge(clk))	then
		if(terminate	= '1') then
			count <= (others=>'0');
		else
			count <= count+1;
		end if;
	end if;
end process counter;

-----------------------------------
-- Terminal Count Generation
termCount_Gen : process(EEW,LMUL)
begin
	case(EEW) is
		------------------------------------------------------------------------------------------------
		when "10"	=>	--32-bit
			case(LMUL)	is
				when "101"	=>	terminal_count <= x"00";  illegal	<=	'0';	--LMUL = 1/8
				when "110"	=>	terminal_count <= x"01";  illegal	<=	'0';    --LMUL = 1/4
				when "111"	=>	terminal_count <= x"03";  illegal	<=	'0';    --LMUL = 1/2
				when "000"	=>	terminal_count <= x"07";  illegal	<=	'0';    --LMUL = 1
				when "001"	=>	terminal_count <= x"0F";  illegal	<=	'0';    --LMUL = 2
				when "010"	=>	terminal_count <= x"1F";  illegal	<=	'0';    --LMUL = 4
				when "011"	=>	terminal_count <= x"3F";  illegal	<=	'0';    --LMUL = 8
				when others	=>	terminal_count <= x"00";  illegal	<=	'1';    --LMUL = Reserved
			end case;
		------------------------------------------------------------------------------------------------
		when "01"	=>	--16-bit
			case(LMUL)	is
				when "101"	=>	terminal_count <= x"01";	illegal	<=	'0';	--LMUL = 1/8
				when "110"	=>	terminal_count <= x"03";    illegal	<=	'0';    --LMUL = 1/4
				when "111"	=>	terminal_count <= x"07";    illegal	<=	'0';    --LMUL = 1/2
				when "000"	=>	terminal_count <= x"0F";    illegal	<=	'0';    --LMUL = 1
				when "001"	=>	terminal_count <= x"1F";    illegal	<=	'0';    --LMUL = 2
				when "010"	=>	terminal_count <= x"3F";    illegal	<=	'0';    --LMUL = 4
				when "011"	=>	terminal_count <= x"7F";    illegal	<=	'0';    --LMUL = 8
				when others	=>	terminal_count <= x"00";    illegal	<=	'1';    --LMUL = Reserved
			end case;
		------------------------------------------------------------------------------------------------
		when "00"	=>	--8-bit
			case(LMUL)	is
				when "101"	=>	terminal_count <= x"03";   illegal	<=	'0';	--LMUL = 1/8
				when "110"	=>	terminal_count <= x"07";   illegal	<=	'0';    --LMUL = 1/4
				when "111"	=>	terminal_count <= x"0F";   illegal	<=	'0';    --LMUL = 1/2
				when "000"	=>	terminal_count <= x"1F";   illegal	<=	'0';    --LMUL = 1
				when "001"	=>	terminal_count <= x"3F";   illegal	<=	'0';    --LMUL = 2
				when "010"	=>	terminal_count <= x"7F";   illegal	<=	'0';    --LMUL = 4
				when "011"	=>	terminal_count <= x"FF";   illegal	<=	'0';    --LMUL = 8
				when others	=>	terminal_count <= x"00";   illegal	<=	'1';    --LMUL = Reserved
			end case;	
		when others	=>	--Invalid Case
		------------------------------------------------------------------------------------------------
			terminal_count	<= x"00"	;	illegal <=	'1';
		------------------------------------------------------------------------------------------------
	end case;
end process	termCount_Gen;

------------------------------------------------------------------------------------------------
expire <= '1' when (count = terminal_count)	else	'0';
------------------------------------------------------------------------------------------------
terminate_gen: process(expire,start,reset,count)
begin
	if( (reset = '1') or (not(start) = '1') or (expire = '1') ) then
		terminate	<=	'1';
	else
		terminate	<=	'0';
	end if;
end process terminate_gen;

done <= terminate;

------------------------------------------------------------------------------------------------
dmem_offset_gen : process(mask,count,RS2,V_OFFSET,IMM,S_VECn,RS1,MOP)
begin
	if(S_VECn	=	'1')	then
	   if(IMM(31) = '1') then  
	       DMEM_offset64	<=x"FFFFFFFF"&IMM;
	   else
	       DMEM_offset64 <= x"00000000"&IMM;
	   end if;
	elsif(Mask = '0') then	
		DMEM_offset64	<=	(others=>'0');
	else
		case (MOP) is	
			when "00"	=>	--Unit Stride Access
				DMEM_offset64	<= x"00000000000000"& std_logic_vector(shift_left(unsigned(count),2));
			when "10"	=>	--Strided Access.
				DMEM_offset64	<= RS2*count32;
			when "11"	=>	--Strided Access
				DMEM_offset64	<= V_OFFSET*count32;
			when others=>
				DMEM_offset64	<=	(others=>'0');
		end case;
	end if;
end process;
DMEM_Offset <= DMEM_offset64(31 downto 0);
ADDER_OUT	 <=	('0'&RS1) + (DMEM_offset(31)&DMEM_offset);
count32		 <= x"000000"&count;	
DADDR 	     <= ADDER_OUT(12 downto 2);
ENA          <= D_CS;
WE           <= D_WE;  
OE           <= D_RE;   
D_DIN		 <= RS2 when (S_VECn = '1') else
				V_DATA_WR;                        

end Behavioral;