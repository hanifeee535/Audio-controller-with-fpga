

-----------------------------------------------------------------------------------------------------
-- Title: Logic Syntheis Exercise 11
-- Project: I2C buss controller  

-- Author Name: Md Soyabbir Abu Hanif, Tanvir Mahmud
-- Group Number: 07
------------------------------------------------------------------------------------------------------


--declaring  the libraries

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--entity declaration

entity i2c_config is 

   --defining the genrerics
   generic (
	ref_clk_freq_g: integer :=  50000000; --frequency of clock signal of block
	i2c_freq_g :  integer := 20000;-- i2c bus sclk frequency 
	n_params_g :  integer := 15; --number of configuration parameters
	n_leds_g   :  integer := 4  --number ofleds on the board
	    );

   --defining the ports
    port (	

	clk             : in std_logic;
	rst_n           : in std_logic;
	sdat_inout      : inout  std_logic;
	sclk_out        : out std_logic;
	param_status_out: out std_logic_vector (n_leds_g -1 downto 0);
	finished_out    : out std_logic
	  );
end i2c_config;   

--declaring the architecture 

architecture  rtl  of i2c_config is 


   
   --defining the constants
   constant  byte_width_c  : integer  := 8;  --data and address byte
   constant  device_addr_c  : std_logic_vector (byte_width_c -1 downto 0) := "00110100"; --slave address and  write bit 

   constant  sclk_counter_range_c  : integer := ref_clk_freq_g / (i2c_freq_g*2); 
   constant number_of_bytes_c : integer := 3;

  --defining new array to store the register address parameters and register value parameters
   type new_array is array (0 to  n_params_g-1)  of std_logic_vector (byte_width_c -1 downto 0); 


    constant register_address_param_c : new_array := (
        "00011101", "00100111", "00100010", "00101000", "00101001",
        "01101001", "01101010", "01000111", "01101011", "01101100",
        "01001011", "01001100", "01101110", "01101111", "01010001"
    );

    constant register_value_param_c : new_array := (
        "10000000", "00000100", "00001011", "00000000", "10000001",
        "00001000", "00000000", "11100001", "00001001", "00001000",
        "00001000", "00001000", "10001000", "10001000", "11110001"
    );


  ---defining the state machine
   type state_type is ( start, address_and_data_transfer, ack_wait, stop,  finished); 


   --counters and registers
   signal state_r  : state_type; 
   signal param_count_r  : integer range 0 to n_params_g  ;
   signal sclk_count_r : integer range 0 to  sclk_counter_range_c -1;
   signal  byte_count_r  : integer range  0  to  number_of_bytes_c ; 
   signal  bit_count_r   : integer range 0 to byte_width_c ; 

    --defining the signals
   signal sdat_out_s     : std_logic; 
   signal sclk_out_s     : std_logic;
   signal finished_out_s : std_logic; 
   signal param_status_r : std_logic_vector (n_leds_g downto 0);


begin 

   process (clk, rst_n) 

--procedure for transfering data or address msb first
procedure byte_transfer  (  data_vector : in std_logic_vector (byte_width_c-1 downto 0)  )  is 
   begin 
       
    
	if  (bit_count_r  = 0)  then  
	    if (sclk_out_s  = '0' and sclk_count_r  = 0 ) then 
		  bit_count_r <=  byte_width_c ; 
		  sdat_out_s <= 'Z';  --High impadance mode to receive acknowledgement signal from the bus
		  state_r  <= ack_wait;  --state transition to acknowlegdement wait state 
                  byte_count_r <=  byte_count_r  +1; 
	          
	    end if; 


	else 

	     if (sclk_out_s  =  '0' and sclk_count_r =  (sclk_counter_range_c  /2)) then 
		  sdat_out_s <=  data_vector (bit_count_r-1 ); 
		  bit_count_r <= bit_count_r -1;

	     end if;
        end if; 

end procedure; 



begin 

     if rst_n = '0' then --asynchronous reset
	 state_r <= start;
	 param_count_r <= 0;
	 sclk_count_r  <= 0;
	 byte_count_r  <= 0;
	 bit_count_r   <= 0;
	 sdat_out_s <= '1';
	 sclk_out_s  <= '1';
	 finished_out_s <= '0'; 
         param_status_r <= (others => '0') ;


     elsif rising_edge (clk) then

	 

 ---sclk generation 
	  
	  if  (sclk_count_r  =  sclk_counter_range_c -1) then 
		sclk_count_r  <= 0; 
		sclk_out_s  <= not sclk_out_s; 
		
	  else
		sclk_count_r  <= sclk_count_r +1; 
	  end if; 
		

 -- State logic 

	  case state_r  is 

		--start state
		when start =>
		     
	                --ready for transmission
	              bit_count_r   <= byte_width_c;
		   	  if (sclk_out_s = '1' and sclk_count_r = sclk_counter_range_c /2 ) then 
			     sdat_out_s  <= '0';
			     state_r  <= address_and_data_transfer; --transition to address and data transfer state.
			  end if; 
		    

		--address_and_data_transfer state 
		when address_and_data_transfer =>

		     if byte_count_r  =  0 then  --first byte sending including slave address and write command 
	   		  byte_transfer (device_addr_c ); 
	   	     end if; 

		     if  byte_count_r  = 1 then --second byte sending which includes register address 
			  byte_transfer (register_address_param_c (param_count_r)  ); 
	   	     end if;

		     if  byte_count_r  = 2 then  --Third byte sending which includes register values
			  byte_transfer (register_value_param_c (param_count_r) ); 
			  
		     end if ; 



		--acknowledgement wait state 	   
		when ack_wait => 

		      
		      if  (sclk_out_s = '1' and sclk_count_r = sclk_counter_range_c/2 ) then 

			  --If successful transfer:
		         if (sdat_inout <= '0' ) then  --sdat_inout = 0 means acknowledge signal

			     
 
			      if  byte_count_r  = 3 then  --go to stop
			      
			            param_count_r <=  param_count_r +1;

			            state_r <= stop;   
		              else  
		 	            state_r  <= address_and_data_transfer; --go back to transfer next byte

		              end if ; 		   


			--If transfer failed:
		        elsif sdat_inout <= '1' then  --not acknowledge condition 
			
	
		             state_r <= stop; --transfer to stop condition 
			     
		       end if ; 
		     
	              end if;

                --stop state 
		when stop =>

			--pulling sda to zero
		      	 if  (sclk_out_s = '0' and sclk_count_r = sclk_counter_range_c/2 ) then
		                 sdat_out_s <= '0';
			end if;  


		      	 if  (sclk_out_s = '1' and sclk_count_r = sclk_counter_range_c/2 ) then 
		             

                            if (param_count_r = n_params_g ) then --all parameter transmission is finished
		      		             
		                 sdat_out_s <= '0';
		            
		                 byte_count_r <= 0;
			         state_r <= finished; --tansision to finished state		             


				--go back to the start again to send next parameters
	                    else 
		                 sdat_out_s <= '1';
		            
		                 byte_count_r <= 0;
		                 state_r <= start;
	                   end if;

	             end if; 
		
		           
		when finished =>

		             
		             sclk_out_s  <= '1';
		             sdat_out_s <= '1';
		             finished_out_s  <= '1';
		end case; 
	 end if; 
end process; 
	  
sdat_inout       <= sdat_out_s;
sclk_out         <= sclk_out_s;
param_status_out <= std_logic_vector(to_unsigned(param_count_r, n_leds_g));
finished_out     <= finished_out_s ;


end rtl; 











