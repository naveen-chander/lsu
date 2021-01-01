----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.01.2021 03:14:50
-- Design Name: 
-- Module Name: illegal - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity illegal is
    Port ( SEW  : in STD_LOGIC_VECTOR (1 downto 0);
           LMUL : in STD_LOGIC_VECTOR (2 downto 0);
           EEW  : in STD_LOGIC_VECTOR (1 downto 0);
           illegal: out std_logic);
end illegal;

architecture Behavioral of illegal is
constant SEW_8		: std_logic_vector(1 downto 0):="00";
constant SEW_16		: std_logic_vector(1 downto 0):="01";
constant SEW_32		: std_logic_vector(1 downto 0):="10";

constant EEW_8		: std_logic_vector(1 downto 0):="00";
constant EEW_16		: std_logic_vector(1 downto 0):="01";
constant EEW_32		: std_logic_vector(1 downto 0):="10";

constant LMUL_1by8	: std_logic_vector(2 downto 0):="101";
constant LMUL_1by4	: std_logic_vector(2 downto 0):="110";
constant LMUL_1by2	: std_logic_vector(2 downto 0):="111";
constant LMUL_1		: std_logic_vector(2 downto 0):="000";
constant LMUL_2		: std_logic_vector(2 downto 0):="001";
constant LMUL_4		: std_logic_vector(2 downto 0):="010";
constant LMUL_8		: std_logic_vector(2 downto 0):="011";



begin
process(SEW,LMUL,EEW)
begin
    case(SEW) is
        when SEW_8   =>	--8-bit
			case(LMUL) is
				when LMUL_4	=>-- LMUL=4
					if EEW = EEW_16 then
						illegal <=	'1';
					else
						illegal <=  '0';
					end if;
				when LMUL_8 =>
					if ((EEW =EEW_16) or (EEW =EEW_32)) then
						illegal <= '1';
					else
						illegal <= '0';
					end if;
				when others =>
					illegal <= '0';
			end case;
			
        when SEW_16   =>	--16-bit
			case(LMUL) is
				when LMUL_1by8	=>-- LMUL=1/8
					if EEW = EEW_8 then
						illegal <=	'1';
					else
						illegal <=  '0';
					end if;
				when LMUL_8 =>
					if EEW =EEW_32 then
						illegal <= '1';
					else
						illegal <= '0';
					end if;
				when others =>
					illegal <= '0';
			end case;
			
        when SEW_32   =>	--32-bit
			case(LMUL) is
				when LMUL_1by8	=>-- LMUL=1/8
					if EEW = EEW_8 or EEW = EEW_16 then
						illegal <=	'1';
					else
						illegal <=  '0';
					end if;
				when LMUL_1by4 =>
					if EEW =EEW_8  then
						illegal <= '1';
					else
						illegal <= '0';
					end if;
				when others =>
					illegal <= '0';
			end case;
		when others=>
			illegal <= '1';
	end case;
end process;

					

end Behavioral;
