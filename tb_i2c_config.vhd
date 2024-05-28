
-----------------------------------------------------------------------------------------------------
-- Title: Logic Syntheis Exercise 12
-- Project: I2C bus controller Testbench

-- Author Name: Md Soyabbir Abu Hanif, Tanvir Mahmud
-- Group Number: 07
------------------------------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------
-- Empty entity
-------------------------------------------------------------------------------

entity tb_i2c_config is
end tb_i2c_config;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture testbench of tb_i2c_config is

  -- Number of parameters to expect
  constant n_params_c     : integer := 15;
  constant n_leds_c : integer := 4;
  constant i2c_freq_c     : integer := 20000;
  constant ref_freq_c     : integer := 50000000;
  constant clock_period_c : time    := 20 ns;

  -- Every transmission consists several bytes and every byte contains given
  -- amount of bits. 
  constant n_bytes_c       : integer := 3;
  constant bit_count_max_c : integer := 8;

-- Reference parameter values for comparing 
   constant  device_addr_ref_c  : std_logic_vector (bit_count_max_c -1 downto 0) := "00110100"; --slave address and  write bit 
   type ref_array is array (0 to  n_params_c -1)  of std_logic_vector (bit_count_max_c -1 downto 0); 


    constant register_address_ref_c : ref_array  := (
        "00011101", "00100111", "00100010", "00101000", "00101001",
        "01101001", "01101010", "01000111", "01101011", "01101100",
        "01001011", "01001100", "01101110", "01101111", "01010001"
    );

    constant register_value_ref_c : ref_array := (
        "10000000", "00000100", "00001011", "00000000", "10000001",
        "00001000", "00000000", "11100001", "00001001", "00001000",
        "00001000", "00001000", "10001000", "10001000", "11110001"
    );

-- array to store the received register address
   signal received_register_addr_r : ref_array;
   signal received_values_r : ref_array;
   signal received_slave_addr_r : ref_array;
   signal received_bits_r  : std_logic_vector (bit_count_max_c-1 downto 0); 
   





  -- Signals fed to the DUV
  signal clk   : std_logic := '0';  -- Remember that default values supported
  signal rst_n : std_logic := '0';      -- only in synthesis

  -- The DUV prototype
  component i2c_config
    generic (
      ref_clk_freq_g : integer;
      i2c_freq_g     : integer;
      n_params_g     : integer;
	  n_leds_g : integer);
    port (
      clk              : in    std_logic;
      rst_n            : in    std_logic;
      sdat_inout       : inout std_logic;
      sclk_out         : out   std_logic;
      param_status_out : out   std_logic_vector(n_leds_g-1 downto 0);
      finished_out     : out   std_logic
      );
  end component;

  -- Signals coming from the DUV
  signal sdat         : std_logic := 'Z';
  signal sclk         : std_logic;
  signal param_status : std_logic_vector(n_leds_c-1 downto 0);
  signal finished     : std_logic;

  -- To hold the value that will be driven to sdat when sclk is high.
  signal sdat_r : std_logic;

-- not acknowledge flag register 
   signal  nack_flag  : std_logic; 
  -- Counters for receiving bits and bytes
  signal bit_counter_r  : integer range -1 to bit_count_max_c-1;
  signal byte_counter_r : integer range 0 to n_bytes_c-1;
  signal parameter_count_r :integer range 0 to  n_params_c ; 

  -- States for the FSM
  type   states is (wait_start, read_byte, send_ack, wait_stop, Finnished);
  signal curr_state_r : states;

  -- Previous values of the I2C signals for edge detection
  signal sdat_old_r : std_logic;
  signal sclk_old_r : std_logic;
  
begin  -- testbench

  clk   <= not clk after clock_period_c/2;
  rst_n <= '1'     after clock_period_c*4;

  -- Assign sdat_r when sclk is active, otherwise 'Z'.
  -- Note that sdat_r is usually 'Z'
  with sclk select
    sdat <=
    sdat_r when '1',
    'Z'    when others;


  -- Component instantiation
  i2c_config_1 : i2c_config
    generic map (
      ref_clk_freq_g => ref_freq_c,
      i2c_freq_g     => i2c_freq_c,
      n_params_g     => n_params_c,
	  n_leds_g => n_leds_c)
    port map (
      clk              => clk,
      rst_n            => rst_n,
      sdat_inout       => sdat,
      sclk_out         => sclk,
      param_status_out => param_status,
      finished_out     => finished);

  -----------------------------------------------------------------------------
  -- The main process that controls the behavior of the test bench
  fsm_proc : process (clk, rst_n)
  begin  -- process fsm_proc
    if rst_n = '0' then                 -- asynchronous reset (active low)

      curr_state_r <= wait_start;

      sdat_old_r <= '0';
      sclk_old_r <= '0';

      byte_counter_r <= 0;
      bit_counter_r  <= bit_count_max_c - 1;
      nack_flag <= '1'; 
      sdat_r <= 'Z';
      received_bits_r  <= (others => '0');
	--received values initially zero 
      for  i in 0 to  n_params_c-1 loop 
     
      	received_values_r (i) <= (others => '0');  
       end loop; 
	--received  register address initially zero 
      for  i in 0 to  n_params_c-1 loop 
     
      	received_register_addr_r (i) <= (others => '0');  
       end loop; 

	--received slave address initially zero 
      for  i in 0 to  n_params_c-1 loop 
     
      	received_slave_addr_r (i) <= (others => '0');  
       end loop; 

      
    elsif clk'event and clk = '1' then  -- rising clock edge

      -- The previous values are required for the edge detection
      sclk_old_r <= sclk;
      sdat_old_r <= sdat;


      -- Falling edge detection for acknowledge control
      -- Must be done on the falling edge in order to be stable during
      -- the high period of sclk
      if sclk = '0' and sclk_old_r = '1' then

        -- If we are supposed to send ack
        if curr_state_r = send_ack then

		if  parameter_count_r = 2  and  byte_counter_r  = 2 then 
		--will send a nack signal  once. then nack flag will be zero forever
			if  nack_flag =  '1' then --nack send  only when parameter = 2 and  byte counter = 0. 
		    
                  		sdat_r <= '1';
                  		nack_flag <= '0';
			else  
                   		sdat_r <= '0';
			end if; 
          	else 		

          		-- Send ack (low = ACK, high = NACK)
            		sdat_r <= '0';
		end if ; 

         else

          -- Otherwise, sdat is in high impedance state.
          sdat_r <= 'Z';
          
        end if;
        
      end if;


      -------------------------------------------------------------------------
      -- FSM
      case curr_state_r is

        -----------------------------------------------------------------------
        -- Wait for the start condition
        when wait_start =>

          -- While clk stays high, the sdat falls
          if sclk = '1' and sclk_old_r = '1' and
            sdat_old_r = '1' and sdat = '0' then

            curr_state_r <= read_byte;

          end if;

          --------------------------------------------------------------------
          -- Wait for a byte to be read
        when read_byte =>

          -- Detect a rising edge
          if sclk = '1' and sclk_old_r = '0' then
		-- assigning the receive bits
	     received_bits_r  <= received_bits_r (bit_count_max_c-2 downto 0) & sdat; 
            if bit_counter_r /= 0 then


		

              -- Normally just receive a bit
              bit_counter_r <= bit_counter_r - 1;

            else

              -- When terminal count is reached, let's send the ack


              curr_state_r  <= send_ack;
              bit_counter_r <= bit_count_max_c - 1;
              
            end if;  -- Bit counter terminal count
            
          end if;  -- sclk rising clock edge

          --------------------------------------------------------------------
          -- Send acknowledge
        when send_ack =>
	        if  byte_counter_r  = 0 then -- will store into the  slave address  array
			received_slave_addr_r (parameter_count_r) <=  received_bits_r ;
	        elsif byte_counter_r  = 1 then  -- will store into received register address array
			received_register_addr_r(parameter_count_r) <=  received_bits_r ; 
	        elsif  byte_counter_r  = 2 then -- will store into the  receivevalue  array
			received_values_r (parameter_count_r) <=  received_bits_r ;
		end if; 

          -- Detect a rising edge
          if sclk = '1' and sclk_old_r = '0' then
	    if  sdat_r = '0' then 
            
            	if byte_counter_r /= n_bytes_c-1 then

              		-- Transmission continues
              		byte_counter_r <= byte_counter_r + 1;
              		curr_state_r   <= read_byte;
              
            	else

              		-- Transmission is about to stop
                        parameter_count_r <= parameter_count_r+1;
              		byte_counter_r <= 0;
              		curr_state_r   <= wait_stop;
              
            	end if;
		--- Strart transition again in the nack condition
	    elsif  sdat_r = '1' then
		byte_counter_r <= 0;
		curr_state_r   <= wait_start;
	    end if ; 

          end if;

          ---------------------------------------------------------------------
          -- Wait for the stop condition
        when wait_stop =>

          -- Stop condition detection: sdat rises while sclk stays high
          if sclk = '1' and sclk_old_r = '1' and
            sdat_old_r = '0' and sdat = '1' then
	    if parameter_count_r = n_params_c  then 
		 curr_state_r <= Finnished;
	   else 

            curr_state_r <= wait_start;
	    end if ; 
            
          end if;

	 when  Finnished =>
	     curr_state_r <= Finnished;

      end case;

    end if;
  end process fsm_proc;

  -----------------------------------------------------------------------------
  -- Asserts for verification
  -----------------------------------------------------------------------------


--process for checking slave address, register address and register values
process  (clk ) 

--procedure  for comparing  each received byte with the  reference bytes
procedure  compare_bytes  (received  : std_logic_vector (bit_count_max_c-1 downto 0) ;  reference  : std_logic_vector (bit_count_max_c-1 downto 0); error_report : string ) is 
begin 
   assert received  =   reference 
   report   error_report 
   severity failure; 
end procedure ; 

-- main process for checking each bytes 
begin 
if clk'event and clk = '1' then  -- rising clock edge
    if  (finished = '1') then 
	for  i in 0 to  n_params_c-1 loop
	
		--check slave address
		 compare_bytes (received_slave_addr_r (i), device_addr_ref_c, " Slave address is not correct"); 
		--check register address
		 compare_bytes (received_register_addr_r (i), register_address_ref_c (i),  " register address is not correct"); 
		--check register values
		 compare_bytes (received_values_r (i), register_value_ref_c (i),  " register value is not correct");
	end loop;
   end if; 
end if; 
end process;  





  -- SDAT should never contain X:s.
  assert sdat /= 'X' report "Three state bus in state X" severity error;

  -- End of simulation, but not during the reset
  assert finished = '0' or rst_n = '0' report
    "Simulation done" severity failure;
  
end testbench;

