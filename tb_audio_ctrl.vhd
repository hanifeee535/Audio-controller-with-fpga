-----------------------------------------------------------------------------------------------------
-- Title: Logic Synthesis Exercise 08
-- Project: Audio codec controller Test bench

-- Author Name: Md Soyabbir Abu Hanif, Tanvir Mahmud
-- Group Number: 07
------------------------------------------------------------------------------------------------------


-- Import necessary libraries
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


-- Entity  for the testbench
entity tb_audio_ctrl is
generic (
        width_g : integer := 16
    );
end tb_audio_ctrl;

-- Defining Architecture for the testbench

architecture testbench of tb_audio_ctrl is

  -- Constants and signals for clock and reset generation
  constant clk_period_c : time := 50 ns;  -- 20 MHz clock frequency 
  signal clk       : std_logic := '0'; -- Clock signal
  signal rst_n      : std_logic := '0'; -- Active-low reset signal
  signal sync_clear_n : std_logic := '1'; 

  -- Constants for waveform generator parameters
  constant step_value_left_c  : integer := 2;
  constant step_value_right_c : integer := 10;

  --  constants for audio controller parameters
  constant ref_clk_freq_c : integer := 20000000; 
  constant sample_rate_c  : integer := 48000;

  -- defining the waveform generator
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

--defining the audio controller: 

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

--defining the audio codec model:

  component audio_codec_model
    generic(
      data_width_g : integer := 16
           );
    port(
      rst_n : in std_logic;
      aud_data_in : in std_logic;
      aud_bclk_in : in std_logic;
      aud_lrclk_in : in std_logic;

      value_left_out : out std_logic_vector (data_width_g-1 downto 0);
      value_right_out : out std_logic_vector (data_width_g -1 downto 0)
        );
  end component;

  -- Signals for waveform generator outputs
   signal left_wave_out_s, right_wave_out_s : std_logic_vector(width_g-1 downto 0);

  -- Signals for audio codec model outputs
   signal value_left_out_model, value_right_out_model : std_logic_vector(width_g-1 downto 0);
   signal aud_data_out_s, aud_bclk_out_s, aud_lrclk_out_s : std_logic;

begin
  
    -- Creating the clock signal
    process
    begin
        clk <= not clk after clk_period_c / 2;
        wait for clk_period_c / 2; -- Add wait statement for simulation stability
    end process;

  -- Reset generation process

  process
    begin
        wait for 4 * clk_period_c;
        rst_n <= '1';
    end process;

--generating sync_clear reset
  process
  begin
    wait for 10 ms;  
    sync_clear_n <= '0';
    wait for 50 ns;  -- Keep reset low for 50 ns
    sync_clear_n <= '1';
    wait;
  end process;

  -- Instantiate waveform generators and connect to audio controller
  gen_left_wave_gen : wave_gen
    generic map (
      width_g  => width_g,  
      step_g   => step_value_left_c
    )
    port map (
      clk             => clk,
      rst_n           => rst_n,
      sync_clear_n_in => sync_clear_n,  -- 
      value_out       => left_wave_out_s
    );

  gen_right_wave_gen : wave_gen
    generic map (
      width_g  => width_g,  
      step_g   => step_value_right_c
    )
    port map (
      clk             => clk,
      rst_n           => rst_n,
      sync_clear_n_in => sync_clear_n,  -- 
      value_out       => right_wave_out_s
    );

  -- Instantiate the audio controller and audio codec model
  dut : audio_ctrl
    generic map (
      ref_clk_freq_g => ref_clk_freq_c,
      sample_rate_g  => sample_rate_c,
      data_width_g   => width_g
    )
    port map (
      clk           => clk,
      rst_n         => rst_n,
      left_data_in  => left_wave_out_s,
      right_data_in => right_wave_out_s,
      aud_bclk_out  => aud_bclk_out_s,
      aud_data_out  => aud_data_out_s,
      aud_lrclk_out => aud_lrclk_out_s
    );
-- Instantiate the audio codec model
  codec_model : audio_codec_model
    generic map (
      data_width_g => width_g
    )
    port map (
      rst_n          => rst_n,
      aud_data_in    => aud_data_out_s,
      aud_bclk_in    => aud_bclk_out_s,
      aud_lrclk_in  => aud_lrclk_out_s,
      value_left_out => value_left_out_model,
      value_right_out => value_right_out_model
    );

  
end testbench;
