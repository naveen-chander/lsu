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
--use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vec_regfile is
    Port (  clk 		: in  STD_LOGIC;
            reset 		: in  STD_LOGIC;
			start		: in  STD_LOGIC;
			vd			: in  STD_LOGIC_VECTOR(4  downto 0);
			LMUL		: in  STD_LOGIC_VECTOR(2  downto 0);
			SEW			: in  STD_LOGIC_VECTOR(1  downto 0);
			EEW			: in  STD_LOGIC_VECTOR(1  downto 0);
			DATA_WR		: in  STD_LOGIC_VECTOR(31 downto 0);
			WE			: in  STD_LOGIC;
			DATA_RD		: out STD_LOGIC_VECTOR(31 downto 0);
			DATA_INDEX  : out STD_LOGIC_VECTOR(31 downto 0)
		   );
end vector_regfile;

architecture Behavioral of vector_regfile is

-- Create a REG_ARRAY of 32 x 256
type reg_array is array (31 downto 0) of std_logic_vector(255 downto 0);
signal vec_reg 			:	reg_array;

signal count			:	STD_LOGIC_VECTOR(7 downto 0);
signal terminate		:	STD_LOGIC;
signal expire			:	STD_LOGIC;
signal terminal_count	:	STD_LOGIC_VECTOR(7 downto 0);




begin
reg_write : process(clk,reset)
variable i 			: integer range 0 to 255;
variable nElements 	: integer range 0 to 32;
variable offset 	: integer range 0 to 31;
variable hi_bit		: integer range 0 to 255;
variable lo_bit		: integer range 0 to 255;
begin
	if(reset <= '1') then
		for i in 0 to 32 loop
			vec_reg(i)	<= (others=>'0');
		end loop;
	elsif(rising_edge(clk))
		
 -- 8-bit Synchronous Counter
process(clk)
begin
	if(rising_edge(clk))	then
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
				when "101"	=>	terminal_count <= x"01";	illegal	<=	'0';	--LMUL = 1/8
				when "110"	=>	terminal_count <= x"02";    illegal	<=	'0';    --LMUL = 1/4
				when "111"	=>	terminal_count <= x"04";    illegal	<=	'0';    --LMUL = 1/2
				when "000"	=>	terminal_count <= x"08";    illegal	<=	'0';    --LMUL = 1
				when "001"	=>	terminal_count <= x"10";    illegal	<=	'0';    --LMUL = 2
				when "010"	=>	terminal_count <= x"20";    illegal	<=	'0';    --LMUL = 4
				when "011"	=>	terminal_count <= x"40";    illegal	<=	'0';    --LMUL = 8
				when others	=>	terminal_count <= x"01";    illegal	<=	'1';    --LMUL = Reserved
			end case;
		------------------------------------------------------------------------------------------------
		when "01"	=>	--16-bit
			case(LMUL)	is
				when "101"	=>	terminal_count <= x"02";	illegal	<=	'0';	--LMUL = 1/8
				when "110"	=>	terminal_count <= x"04";    illegal	<=	'0';    --LMUL = 1/4
				when "111"	=>	terminal_count <= x"08";    illegal	<=	'0';    --LMUL = 1/2
				when "000"	=>	terminal_count <= x"10";    illegal	<=	'0';    --LMUL = 1
				when "001"	=>	terminal_count <= x"20";    illegal	<=	'0';    --LMUL = 2
				when "010"	=>	terminal_count <= x"40";    illegal	<=	'0';    --LMUL = 4
				when "011"	=>	terminal_count <= x"80";    illegal	<=	'0';    --LMUL = 8
				when others	=>	terminal_count <= x"01";    illegal	<=	'1';    --LMUL = Reserved
			end case;
		------------------------------------------------------------------------------------------------
		when "00"	=>	--8-bit
			case(LMUL)	is
				when "101"	=>	terminal_count <= x"04";	illegal	<=	'0';	--LMUL = 1/8
				when "110"	=>	terminal_count <= x"08";    illegal	<=	'0';    --LMUL = 1/4
				when "111"	=>	terminal_count <= x"10";    illegal	<=	'0';    --LMUL = 1/2
				when "000"	=>	terminal_count <= x"20";    illegal	<=	'0';    --LMUL = 1
				when "001"	=>	terminal_count <= x"40";    illegal	<=	'0';    --LMUL = 2
				when "010"	=>	terminal_count <= x"80";    illegal	<=	'0';    --LMUL = 4
				when "011"	=>	terminal_count <= x"80";    illegal	<=	'0';    --LMUL = 8
				when others	=>	terminal_count <= x"01";    illegal	<=	'1';    --LMUL = Reserved
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

------------------------------------------------------------------------------------------------
end Behavioral;

