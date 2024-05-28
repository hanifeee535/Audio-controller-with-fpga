
-----------------------------------------------------------------------------------------------------
-- Title: Logic Syntheis Exercise 03
-- Project: Generic Adder 

-- Author Name: Md Soyabbir Abu Hanif, Tanvir Mahmud
-- Group Number: 07
------------------------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;
--Declaring the entity as "adder"

entity adder is
-- declaring the generalized width of the operands i.e.: a_in, b_in,sum_out
	generic (
		 operand_width_g: integer 
		);
--Declaring the ports
	port (

		clk : in std_logic;
		rst_n : in std_logic;
		a_in : in std_logic_vector (operand_width_g -1 downto 0);
	        b_in : in std_logic_vector (operand_width_g -1 downto 0);
		sum_out : out std_logic_vector(operand_width_g downto 0));
end adder;

architecture rtl of adder is
	signal sum_reg : signed(operand_width_g downto 0); --the sum_reg will act as a temporary storage register to store the sum of two operands.
    
begin --rtl description
	
process (clk, rst_n)

begin 
	if rst_n = '0' then
 	--asynchronous reset in active low reset signal
	sum_reg <= (others => '0');
	

	elsif rising_edge(clk) then
	-- synchronous addition in every rising clock edge 
	sum_reg <= resize(signed(a_in), operand_width_g+1) + resize(signed(b_in), operand_width_g+1);
	end if;
        end process;
 	sum_out <= std_logic_vector(sum_reg);  --storing the sum value to the output variable sum_out
end rtl; 
	
