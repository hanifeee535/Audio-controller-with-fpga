-----------------------------------------------------------------------------------------------------
-- Title: Logic Synthesis Exercise 05
-- Project: Multiport Adder Test bench

-- Author Name: Md Soyabbir Abu Hanif, Tanvir Mahmud
-- Group Number: 07
------------------------------------------------------------------------------------------------------

-- Including the libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.all;
-- Defining the entity
entity tb_multi_port_adder is
    generic (
        operand_width_g : integer := 3
    );
end tb_multi_port_adder;

-- Defining the behaviour in architecture:
architecture testbench of tb_multi_port_adder is

    -- Defining the constants:
    constant number_of_operands_c : integer := 4;
    constant duv_delay_c          : integer := 2;
    constant clk_period_c         : time := 10 ns;

    
-- Defining the signals:
    
    
    signal clk             : std_logic := '0'; -- Initial value is 0
    signal rst_n           : std_logic := '0'; -- Initial value is 0
    signal operands_r      : std_logic_vector((operand_width_g * number_of_operands_c - 1) downto 0);
    signal sum             : std_logic_vector(operand_width_g -1 downto 0);
    signal output_valid_r  : std_logic_vector(duv_delay_c+1-1 downto 0);

    -- Defining the files:
    file input_f        : text open READ_MODE is "input.txt";
    file ref_results_f  : text open READ_MODE is "ref_results.txt";
    file output_f       : text open WRITE_MODE is "output.txt";

    -- Declare the component for the multi_port_adder
    component multi_port_adder
        generic (
            operand_width_g   : integer := 16;
            num_of_operands_g : integer := 4
        );
        port (
            clk         : in std_logic;
            rst_n       : in std_logic;
            operands_in : in std_logic_vector (operand_width_g * num_of_operands_g - 1 downto 0);
            sum_out     : out std_logic_vector (operand_width_g - 1 downto 0)
        );
    end component;

--beginning the process

begin

    -- Creating the clock signal
    process
    begin
        clk <= not clk after clk_period_c / 2;
        wait for clk_period_c / 2; -- Add wait statement for simulation stability
    end process;

    -- Setting the reset signal value '1' after 4 clock cycles from the beginning of the simulation:
    process
    begin
        wait for 4 * clk_period_c;
        rst_n <= '1';
    end process;

    -- Instantiating the multiport adder
    multi_port_adder_I : multi_port_adder
        generic map (
            operand_width_g => operand_width_g,
            num_of_operands_g => number_of_operands_c
        )
        port map (
            clk => clk,
            rst_n => rst_n,
            operands_in => operands_r,
            sum_out => sum
        );

    -- Creating a synchronous process for reading input files (input_reader)
    process (clk, rst_n)
        type new_array is array (0 to number_of_operands_c-1) of integer;
        variable line_v : line;
        variable values_v : new_array;

    begin
        if rst_n = '0' then -- Defining the reset at rst_n=0
            operands_r <= (others => '0');
            output_valid_r <= (others => '0');

         
            elsif rising_edge(clk) then -- On rising clock edge
                -- Set the least significant bit of output_valid_r to '1' and shift left for delay
                output_valid_r <=  output_valid_r( 1 downto 0) & '1' ;

                if not endfile(input_f) then -- Read the next line of the input file when it is not reached at the end.
                    readline(input_f, line_v);

                    -- Read four values from the line
                    for i in 0 to (number_of_operands_c-1) loop
                        read(line_v, values_v(i));
                    end loop;

                    -- Assign values to operands_r
                    operands_r <= std_logic_vector(to_signed(values_v(0), operand_width_g) &
                                                   to_signed(values_v(1), operand_width_g) &
                                                   to_signed(values_v(2), operand_width_g) &
                                                   to_signed(values_v(3), operand_width_g));
                end if;
            end if;
      
    end process;

    -- Creating a synchronous process for the checker (checker)
    process (clk)
        
        variable line_in_r : line;
	variable output_line : line;
        variable output_r : integer;
        variable values_v : integer;
    begin
        if rising_edge(clk) then
            -- Check if MSB of output_valid_r is one
            if output_valid_r(duv_delay_c) = '1' then
                -- Read one line from the reference file
                if not endfile(ref_results_f) then
                    readline(ref_results_f, line_in_r);

                    -- Read one value from the line to a variable
                    read(line_in_r, output_r);

                    -- Add assert for checking correctness of the output
                    assert to_integer(signed(sum)) = output_r
                        report "Output does not match reference value"
                        severity note;

                    -- Write the output of the tested block to the output file
                    write(output_line, to_integer(signed(sum)));
                    writeline(output_f, output_line);

                else
                    -- If EOF is reached, inform of successful simulation
                    assert false
                        report "Simulation done"
                        severity note;
                end if;
            end if;
        end if;
    end process;

end testbench;


