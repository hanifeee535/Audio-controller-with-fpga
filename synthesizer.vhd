-----------------------------------------------------------------------------------------------------
-- Title: Logic Synthesis Exercise 09
-- Project: Synthesizer top level

-- Author Name: Md Soyabbir Abu Hanif, Tanvir Mahmud
-- Group Number: 07
------------------------------------------------------------------------------------------------------


-- Import necessary libraries
library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

--entity declaration

entity synthesizer is
   generic (
	clk_freq_g  :  integer := 12288000; --in hartz
	sample_rate_g : integer := 48000;
	data_width_g : integer := 16; --bits
	n_keys_g  : integer := 4
	    );

   port (
	clk :in std_logic;
	rst_n : in std_logic;
	keys_in :  in std_logic_vector (n_keys_g -1 downto 0);
	aud_bclk_out  : out  std_logic ;
	aud_data_out : out std_logic;
	aud_lrclk_out : out std_logic
	);
end  synthesizer;

 -- defining the architecture

architecture structural of  synthesizer is 

--constants
    constant  step_value_1_c :integer :=  1;
    constant  step_value_2_c :integer :=  2;
    constant  step_value_3_c :integer :=  4;
    constant  step_value_4_c :integer :=  8;

--signals for wave gen outputs:
    signal wave_out_1_s, wave_out_2_s,wave_out_3_s,wave_out_4_s : std_logic_vector  (data_width_g -1 downto 0);

    signal wave_out_s  : std_logic_vector ((data_width_g *n_keys_g) -1 downto 0);


--signals for multi port adder outputs

    signal adder_sum_out_s  : std_logic_vector  (data_width_g -1 downto 0);

--signal for audio controller output 
    

    signal aud_bclk_out_s , aud_lrclk_out_s , aud_data_out_s : std_logic; 

--declaration of components
 --wave gen
  component wave_gen
    generic (
      width_g : integer;
      step_g  : integer
    );
    port (
      clk             : in std_logic;
      rst_n           : in std_logic;
      sync_clear_n_in : in std_logic;
      value_out       : out std_logic_vector(width_g - 1 downto 0)
    );
  end component;

-- audio controller: 

  component audio_ctrl
    generic (
      ref_clk_freq_g : integer := 12288000;
      sample_rate_g  : integer := 48000;
      data_width_g   : integer := 16
    );
    port (
      clk              : in std_logic;
      rst_n            : in std_logic;
      left_data_in     : in std_logic_vector(data_width_g - 1 downto 0);
      right_data_in    : in std_logic_vector(data_width_g - 1 downto 0);
      aud_bclk_out     : out std_logic;
      aud_data_out     : out std_logic;
      aud_lrclk_out    : out std_logic
    );
  end component;



--multi port adder


  component  multi_port_adder
    generic (
        operand_width_g   : integer :=16;
        num_of_operands_g : integer :=4
         );
    port (
        clk         : in std_logic;
        rst_n       : in std_logic;
        operands_in : in std_logic_vector (operand_width_g * num_of_operands_g - 1 downto 0);
        sum_out     : out std_logic_vector (operand_width_g - 1 downto 0)
         );
end component;


     

begin 

-- instantiating the wave generators:


wave_gen_1  : wave_gen

    generic map (
	width_g => data_width_g,
	step_g  => step_value_1_c
	)
    port map (
	clk => clk,
	rst_n => rst_n,
	sync_clear_n_in => keys_in(0),
	value_out => wave_out_s ((data_width_g ) -1 downto 0)
	);

wave_gen_2  : wave_gen

    generic map (
	width_g => data_width_g,
	step_g  => step_value_2_c
	)
    port map (
	clk => clk,
	rst_n => rst_n,
	sync_clear_n_in => keys_in(1),
	value_out => wave_out_s ((2*data_width_g ) -1 downto data_width_g)
	);

wave_gen_3  : wave_gen

    generic map (
	width_g => data_width_g,
	step_g  => step_value_3_c
	)
    port map (
	clk => clk,
	rst_n => rst_n,
	sync_clear_n_in => keys_in(2),
	value_out =>  wave_out_s ((3*data_width_g ) -1 downto (2*data_width_g))
	);

wave_gen_4  : wave_gen

    generic map (
	width_g => data_width_g,
	step_g  => step_value_4_c
	)
    port map (
	clk => clk,
	rst_n => rst_n,
	sync_clear_n_in => keys_in(3),
	value_out => wave_out_s ((4*data_width_g ) -1 downto (3*data_width_g))
	);
     
--  instantiating the multi port adder

 adder: multi_port_adder

    generic map (

        operand_width_g   => data_width_g,
        num_of_operands_g => n_keys_g
         )
    port map (
        clk         => clk,
        rst_n       => rst_n,
        operands_in => wave_out_s ,
        sum_out     => adder_sum_out_s 
         );


--  instantiating audio control

Audio_control : audio_ctrl
    generic map (
      ref_clk_freq_g => clk_freq_g,
      sample_rate_g  => sample_rate_g,
      data_width_g   => data_width_g
    )
    port map (
      clk           => clk,
      rst_n         => rst_n,
      left_data_in  => adder_sum_out_s,
      right_data_in => adder_sum_out_s,
      aud_bclk_out  => aud_bclk_out_s,
      aud_data_out  => aud_data_out_s,
      aud_lrclk_out => aud_lrclk_out_s
    );


--assigning the shignals to the outputs

    aud_bclk_out <= aud_bclk_out_s;
    aud_lrclk_out <= aud_lrclk_out_s;
    aud_data_out <= aud_data_out_s;


end architecture  structural ; 

























