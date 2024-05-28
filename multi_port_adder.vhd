-----------------------------------------------------------------------------------------------------
-- Title: Logic Syntheis Exercise 04
-- Project: Multiport Adder

-- Author Name: Md Soyabbir Abu Hanif, Tanvir Mahmud
-- Group Number: 07
------------------------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


-- Creating an entity as multi_port_adder
entity multi_port_adder is
    -- Declaring the generic integer type parameter without default values
    generic (
        operand_width_g   : integer :=16;
        num_of_operands_g : integer :=4
    );
    -- Declaring the ports
    port (
        clk         : in std_logic;
        rst_n       : in std_logic;
        operands_in : in std_logic_vector (operand_width_g * num_of_operands_g - 1 downto 0);
        sum_out     : out std_logic_vector (operand_width_g - 1 downto 0)
    );
end multi_port_adder;

-- Defining architecture
architecture structural of multi_port_adder is
    -- Defining the adder component
    component adder
	generic (
		 operand_width_g: integer 
		);
        port (
	    clk     : in std_logic;
	    rst_n   : in std_logic;
            a_in    : in  std_logic_vector (operand_width_g - 1 downto 0);
            b_in    : in  std_logic_vector (operand_width_g - 1 downto 0);
            sum_out : out std_logic_vector (operand_width_g downto 0)
        );
    end component;

    -- Introducing the type
    type new_array is array (0 to num_of_operands_g/2 - 1) of std_logic_vector (operand_width_g+1-1 downto 0);

    -- Declaring the signals
    signal subtotal : new_array;
    signal total    : std_logic_vector (operand_width_g+2 -1 downto 0);
begin
   -- Instantiating the first two adders
adder1 : adder
  generic map (
    operand_width_g   => operand_width_g
  )
  port map (
    clk     => clk,
    rst_n   => rst_n,
    a_in    => operands_in(operand_width_g*4 - 1 downto operand_width_g*3),
    b_in    => operands_in(operand_width_g*3 - 1 downto operand_width_g*2),
    sum_out => subtotal(0)
  );

adder2 : adder
  generic map (
    operand_width_g   => operand_width_g
  )
  port map (
    clk     => clk,
    rst_n   => rst_n,
    a_in    =>  operands_in(operand_width_g*2 - 1 downto operand_width_g),
    b_in    => operands_in(operand_width_g - 1 downto 0),
    sum_out => subtotal(1)
  );

-- Instantiating the 3rd adder
adder3 : adder
  generic map (
    operand_width_g   => operand_width_g+1
  )
  port map (
    clk     => clk,
    rst_n   => rst_n,
    a_in    => subtotal(0),
    b_in    => subtotal(1),
    sum_out => total
  );


    -- Connecting the total to the output_sum_out leaving two most significant bits
    sum_out <= total(operand_width_g-1 downto 0);

    -- Inserting the assert which ensures that the num_of_operands_g is always 4
    assert num_of_operands_g = 4
        report "num_of_operands_g must be 4"
        severity failure;

end architecture structural;


