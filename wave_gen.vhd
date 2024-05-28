-----------------------------------------------------------------------------------------------------
-- Title: Logic Synthesis Exercise 06
-- Project: Triangle wave generator

-- Author Name: Md Soyabbir Abu Hanif, Tanvir Mahmud
-- Group Number: 07
------------------------------------------------------------------------------------------------------

-- Including the libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

--defining the entity
entity wave_gen is
	--defining the generics
    generic (
        width_g : integer ; -- counter width
        step_g  : integer  -- step size
    );
	--defining the ports
    port (
        clk             : in std_logic;
        rst_n           : in std_logic;
        sync_clear_n_in : in std_logic;
        value_out       : out std_logic_vector (width_g -1 downto 0)
    );
end entity wave_gen;

--defining the architecture
architecture rtl of wave_gen is

   --constants declaration:
    constant  count_max_c : signed (width_g - 1 downto 0) := to_signed(((2**(width_g - 1) - 1) / step_g) * step_g , width_g);
    constant count_min_c : signed (width_g - 1 downto 0) := -count_max_c;

    --defining the signals
    signal counter_r    : signed (width_g - 1 downto 0) ;
    signal direction_r  : std_logic ; 

begin 
    process (clk, rst_n)
    begin 
        if rst_n = '0' then  --reset 
            counter_r <= (others => '0');
            direction_r <= '1'; -- Start counting upwards after reset
        elsif rising_edge(clk) then
            if sync_clear_n_in = '0' then   -- Keep output as zero when sync_clear_n is '0'
                counter_r <= (others => '0'); 
                direction_r <= '1';
            else
                -- Update count based on direction and step size
                if direction_r = '1' then
                    if counter_r = count_max_c then
                        counter_r  <= counter_r - step_g;  -- stay one clock cycle at max and then change direction
                        direction_r <=  '0';
                    else 
                        counter_r  <= counter_r + step_g;
                    end if;
                else
                    -- Change direction if limit is reached
                    if counter_r = count_min_c then
                        counter_r <= counter_r + step_g;  -- stay one clock cycle at min and then change direction
                        direction_r <= not direction_r;
                    else 
                        counter_r <= counter_r - step_g;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    value_out <= std_logic_vector (counter_r);

end rtl;


