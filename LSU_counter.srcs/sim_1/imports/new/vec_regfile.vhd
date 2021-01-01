----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06.11.2020 23:37:16
-- Design Name: 
-- Module Name: Vector regfile - Behavioral
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

use IEEE.NUMERIC_STD.ALL;


entity vec_regfile is
    Port (  clk 		: in  STD_LOGIC;
            reset 		: in  STD_LOGIC;
			start		: in  STD_LOGIC;
			vd			: in  STD_LOGIC_VECTOR(4  downto 0);
			vs1			: in  STD_LOGIC_VECTOR(4  downto 0);
			vs2			: in  STD_LOGIC_VECTOR(4  downto 0);
			LMUL		: in  STD_LOGIC_VECTOR(2  downto 0);
			SEW			: in  STD_LOGIC_VECTOR(1  downto 0);
			DATA_WR		: in  STD_LOGIC_VECTOR(31 downto 0);
			WE			: in  STD_LOGIC;
			DATA_RD		: out STD_LOGIC_VECTOR(31 downto 0);
			DONE        : out STD_LOGIC;
			DATA_INDEX  : out STD_LOGIC_VECTOR(31 downto 0)
		   );
end vec_regfile;

architecture Behavioral of vec_regfile is

-- Create a REG_ARRAY of 32 x 256
type reg_array is array (31 downto 0) of std_logic_vector(255 downto 0);
signal vec_reg 			:	reg_array;

signal count			:	STD_LOGIC_VECTOR(7 downto 0);
signal terminate		:	STD_LOGIC;
signal expire			:	STD_LOGIC;
signal terminal_count	:	STD_LOGIC_VECTOR(7 downto 0);

signal RAW_DATA_8       : STD_LOGIC_VECTOR(7 downto 0);
signal RAW_DATA_16      : STD_LOGIC_VECTOR(15 downto 0);

signal RAW_IDX_8        : STD_LOGIC_VECTOR(7 downto 0);
signal RAW_IDX_16       : STD_LOGIC_VECTOR(15 downto 0);

begin

writer : process(clk,reset)
-- Process Variable Definitions
	variable i 			: integer range 0 to 255;
	variable offset 	    : integer := 0;
	variable hi_bit			: integer := 31;
	variable lo_bit		    : integer := 0;
	variable v_index_offset : integer := 0;
	variable nElements      : integer := 8;
	variable ele_size       : integer := 32;

begin
	if(reset = '1') then
		for i in 0 to 31 loop
			vec_reg(i)	<= (others=>'0');
		end loop;

 	elsif(rising_edge(clk))   then
		if (WE = '1') then
			case(SEW) is 
				when "00"	=>	--8-bit
					ele_size  		:=    8;      -- size of each element
					nElements 		:=    32;      -- 32 elements in 1 vector reg
					v_index_offset  :=    to_integer(unsigned(count))/32;  -- count / 32
					offset     		:=    to_integer(unsigned(count) mod 32);  -- count modulo 32
					hi_bit    		:=    ((offset+1)*8) - 1; -- (offset+1) * 8
					lo_bit    		:=    (offset)*8; -- (offset) * 8
					---------------------------------------------------------------------------------
					vec_reg(to_integer(unsigned((vd))+(v_index_offset)))((hi_bit) downto (lo_bit)) <= DATA_WR(7 downto 0);
					---------------------------------------------------------------------------------
				when "01"    =>	--16-bit
					ele_size  		:=    16;      -- size of each element
					nElements 		:=    16;      -- 16 elements in 1 vector reg 
					v_index_offset  :=    to_integer(unsigned(count)/16);  -- count / 16  
					offset      	:= 	  to_integer(unsigned(count)) mod 16;  -- count modulo 16
					hi_bit    		:=    ((offset+1)*16) - 1; -- (offset+1) * 16
					lo_bit    		:=    (offset)*16; -- (offset) * 16       			
					---------------------------------------------------------------------------------
					vec_reg(to_integer(unsigned((vd))+(v_index_offset)))((hi_bit) downto (lo_bit)) <= DATA_WR(15 downto 0);			 
					---------------------------------------------------------------------------------
				when others=>
					ele_size  		:=    32;      -- size of each element
					nElements 		:=    8;      -- 8 elements in 1 vector reg   
					v_index_offset  :=    to_integer(unsigned(count)/8);  -- count / 8
					offset      	:= 	  to_integer(unsigned(count)) mod 8;  -- count modulo 8
					hi_bit    		:=    ((offset+1)*32) - 1; -- (offset+1) * 32
					lo_bit    		:=    (offset)*32; -- (offset) * 32 
					---------------------------------------------------------------------------------
					vec_reg(to_integer(unsigned((vd))+(v_index_offset)))((hi_bit) downto (lo_bit)) <= DATA_WR;			 				
					---------------------------------------------------------------------------------
			end case;
		end if;
	end if;
end process writer;
				
--Read Logic
reader: process (count,SEW,RAW_DATA_8,RAW_DATA_16,vd)
variable offset 	    : integer := 0;
variable hi_bit			: integer := 31;
variable lo_bit		    : integer := 0;
variable v_index_offset : integer := 0;
variable nElements      : integer := 8;
variable ele_size       : integer := 32;

begin
	case(SEW) is 
		when "00"	=>	--8-bit
			ele_size  		:=    8;      -- size of each element
			nElements 		:=    32;      -- 32 elements in 1 vector reg
			v_index_offset  :=    to_integer(unsigned(count))/32;  -- count / 32
			offset     		:=    to_integer(unsigned(count) mod 32);  -- count modulo 32
			hi_bit    		:=    ((offset+1)*8) - 1; -- (offset+1) * 8
			lo_bit    		:=    (offset)*8; -- (offset) * 8
			--------------------------------------------------------------------------------------
            RAW_DATA_8 <= vec_reg(to_integer(unsigned((vs1))+(v_index_offset)))((hi_bit) downto (lo_bit)) ;
            RAW_IDX_8  <= vec_reg(to_integer(unsigned((vs2))+(v_index_offset)))((hi_bit) downto (lo_bit)) ;
			-- Sign Extending Data and Index Reads
            if(RAW_DATA_8(7) = '1') then
                DATA_RD 	<= x"FFFFFF" & RAW_DATA_8;
            else
                DATA_RD		<= x"000000" & RAW_DATA_8;
            end if;
            if(RAW_IDX_8(7) = '1') then
				DATA_INDEX  <= x"FFFFFF" & RAW_IDX_8;
            else
				DATA_INDEX  <= x"000000" & RAW_IDX_8;
            end if;			
			--------------------------------------------------------------------------------------
		when "01"    =>
			ele_size  		:=    16;      -- size of each element
			nElements 		:=    16;      -- 16 elements in 1 vector reg 
			v_index_offset  :=    to_integer(unsigned(count)/16);  -- count / 16  
			offset      	:= 	  to_integer(unsigned(count)) mod 16;  -- count modulo 16
			hi_bit    		:=    ((offset+1)*16) - 1; -- (offset+1) * 16
			lo_bit    		:=    (offset)*16; -- (offset) * 16     			
			--------------------------------------------------------------------------------------
            RAW_DATA_16 <= vec_reg(to_integer(unsigned((vs1))+(v_index_offset)))((hi_bit) downto (lo_bit)) ;
            RAW_IDX_16  <= vec_reg(to_integer(unsigned((vs2))+(v_index_offset)))((hi_bit) downto (lo_bit)) ;
            if(RAW_DATA_16(15) = '1') then
                DATA_RD <= x"FFFF" & RAW_DATA_16;
            else
                DATA_RD <= x"0000" & RAW_DATA_16;
            end if;			
            if(RAW_IDX_16(15) = '1') then
				DATA_INDEX  <= x"FFFF" & RAW_IDX_16;
            else
				DATA_INDEX  <= x"0000" & RAW_IDX_16;
            end if;		
               --------------------------------------------------------------------------------------
          when others=>
			ele_size  		:=    32;      -- size of each element
			nElements 		:=    8;      -- 8 elements in 1 vector reg   
			v_index_offset  :=    to_integer(unsigned(count)/8);  -- count / 8
			offset      	:= 	  to_integer(unsigned(count)) mod 8;  -- count modulo 8
			hi_bit    		:=    ((offset+1)*32) - 1; -- (offset+1) * 32
			lo_bit    		:=    (offset)*32; -- (offset) * 32     
			--------------------------------------------------------------------------------------
			DATA_RD <= vec_reg(to_integer(unsigned((vs1))+(v_index_offset)))((hi_bit) downto (lo_bit)) ;
			DATA_INDEX <= vec_reg(to_integer(unsigned((vs2))+(v_index_offset)))((hi_bit) downto (lo_bit)) ;
			--------------------------------------------------------------------------------------				
	end case;
end process reader;
------------------------------------------------------------------------------------------------
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
termCount_Gen : process(SEW,LMUL)
begin
	case(SEW) is
		------------------------------------------------------------------------------------------------
		when "10"	=>	--32-bit
			case(LMUL)	is
				when "101"	=>	terminal_count <= x"00";		--LMUL = 1/8
				when "110"	=>	terminal_count <= x"01";        --LMUL = 1/4
				when "111"	=>	terminal_count <= x"03";        --LMUL = 1/2
				when "000"	=>	terminal_count <= x"07";        --LMUL = 1
				when "001"	=>	terminal_count <= x"0F";        --LMUL = 2
				when "010"	=>	terminal_count <= x"1F";        --LMUL = 4
				when "011"	=>	terminal_count <= x"3F";        --LMUL = 8
				when others	=>	terminal_count <= x"00";        --LMUL = Reserved
			end case;
		--------------------------------------------------------------------------------
		when "01"	=>	--16-bit
			case(LMUL)	is
				when "101"	=>	terminal_count <= x"01";		--LMUL = 1/8
				when "110"	=>	terminal_count <= x"03";        --LMUL = 1/4
				when "111"	=>	terminal_count <= x"07";        --LMUL = 1/2
				when "000"	=>	terminal_count <= x"0F";        --LMUL = 1
				when "001"	=>	terminal_count <= x"1F";        --LMUL = 2
				when "010"	=>	terminal_count <= x"3F";        --LMUL = 4
				when "011"	=>	terminal_count <= x"7F";        --LMUL = 8
				when others	=>	terminal_count <= x"00";        --LMUL = Reserved
			end case;
		------------------------------------------------------------------------------------------------
		when "00"	=>	--8-bit
			case(LMUL)	is
				when "101"	=>	terminal_count <= x"03";	--LMUL = 1/8
				when "110"	=>	terminal_count <= x"07";     --LMUL = 1/4
				when "111"	=>	terminal_count <= x"0F";     --LMUL = 1/2
				when "000"	=>	terminal_count <= x"1F";     --LMUL = 1
				when "001"	=>	terminal_count <= x"3F";     --LMUL = 2
				when "010"	=>	terminal_count <= x"7F";     --LMUL = 4
				when "011"	=>	terminal_count <= x"FF";     --LMUL = 8
				when others	=>	terminal_count <= x"00";     --LMUL = Reserved
			end case;	
		when others	=>	--Invalid Case
		------------------------------------------------------------------------------------------------
			terminal_count	<= x"00"	;	
		------------------------------------------------------------------------------------------------
	end case;
end process	termCount_Gen;

------------------------------------------------------------------------------------------------
expire <= '1' when (count = (terminal_count))	else	'0';
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
end Behavioral;

