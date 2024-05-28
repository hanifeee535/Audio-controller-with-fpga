-----------------------------------------------------------------------------------------------------
-- Title: Logic Syntheis Exercise 07
-- Project: Audio_ctrl

-- Author Name: Md Soyabbir Abu Hanif, Tanvir Mahmud
-- Group Number: 07
------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


--creating the entity
entity audio_ctrl is 

   --declaring the generics with default values
   generic (
      ref_clk_freq_g : integer := 12288000; --in HZ
      sample_rate_g  : integer := 48000; --in HZ
      data_width_g   : integer := 16 --bits
      );

   --defining the ports for entity
   port (
      clk	   : in std_logic;
      rst_n  	   : in std_logic;
      left_data_in : in std_logic_vector (data_width_g -1 downto 0);
      right_data_in: in std_logic_vector (data_width_g -1 downto 0);
   
      aud_bclk_out : out std_logic;
      aud_data_out : out  std_logic;
      aud_lrclk_out: out std_logic
      );
end audio_ctrl ;


--defining the architecture

architecture rtl of audio_ctrl is 

      constant bclk_range_c : integer := (ref_clk_freq_g / (2*sample_rate_g *2*data_width_g));  -- bit clock frequency
      constant lrclk_range_c : integer := (bclk_range_c *2*data_width_g);  -- left right  clock frequency
      constant sample_range_c : integer := (lrclk_range_c*2);
      constant  bclk_cycle_range_c : integer := bclk_range_c*2; --Left right clock frequency

    --defining the signals:
      signal bclk_counter_r : integer range 0 to bclk_range_c-1 ;
      signal lrclk_counter_r : integer range 0 to lrclk_range_c-1;
      signal  sample_cycle_counter_r : integer range 0 to  sample_range_c-1;
      signal bclk_cycle_counter_r : integer range 0 to bclk_cycle_range_c-1;

      signal left_data_register_r : std_logic_vector ((data_width_g ) -1 downto 0);
      signal right_data_register_r : std_logic_vector (data_width_g -1 downto 0);

      signal aud_bclk_s : std_logic ;
      signal aud_lrclk_s  : std_logic;
      signal aud_data_s : std_logic;
      --signal data_capture_flag_s : std_logic;
      --signal data_feeding_flag_s : std_logic;

begin 

     

--process for clock generation : bit clock and left right data clock
      process (clk, rst_n)
	begin 
	  
 	  if rst_n ='0' then  --Asynchronous reset
	      bclk_counter_r <= bclk_range_c-1;
	      lrclk_counter_r <= lrclk_range_c-1;
	      sample_cycle_counter_r <=  sample_range_c-1;
	      bclk_cycle_counter_r <=  bclk_cycle_range_c-1;

	      --data_capture_flag_s <= '0';
	      --data_feeding_flag_s <= '0';

	      aud_bclk_s <= '0';
	      aud_lrclk_s <= '0';
	      aud_data_s <= '0';


	      left_data_register_r <= (others => '0') ;
	      right_data_register_r <= (others => '0') ;		

	  elsif rising_edge(clk) then --Synchronous process for clock generation and data feeding 

		--bclk counter configuration		
		if bclk_counter_r = bclk_range_c-1 then 
		     bclk_counter_r <= 0;
		     aud_bclk_s <= not aud_bclk_s; --Inverting bit clock counter on rising edge
		 else  
		      bclk_counter_r <= bclk_counter_r +1;
		end if; 


  		--lrclk counter configuration    		
		if lrclk_counter_r = lrclk_range_c-1 then  
		   lrclk_counter_r <=0;
		elsif lrclk_counter_r = bclk_range_c-1 then
		   aud_lrclk_s <= not aud_lrclk_s; --Inverting left right clock
		    lrclk_counter_r <= lrclk_counter_r +1;
		 
	        else 
		    lrclk_counter_r <= lrclk_counter_r +1;
		end if ; 


		--data capturing counter configuration with sample cycle counter
		if  sample_cycle_counter_r = sample_range_c-1  then  

		     sample_cycle_counter_r <= 0;

		else 
		      sample_cycle_counter_r <=  sample_cycle_counter_r +1;

		end if ; 


		--data feeding counter configuration with bclk cycle range
		if  bclk_cycle_counter_r = bclk_cycle_range_c-1  then  

		     bclk_cycle_counter_r <= 0;
		else 
		      bclk_cycle_counter_r <=  bclk_cycle_counter_r +1;

		end if ; 

		 -- data capturing  
		   if  sample_cycle_counter_r =  bclk_range_c-2  then 
		     	left_data_register_r <= left_data_in;
		     	right_data_register_r <= right_data_in;	
		  end if;

		 -- data feeding 
		if  bclk_cycle_counter_r = bclk_range_c  then

			
		   if aud_lrclk_s = '1' then 
           	   
 	             	aud_data_s <= left_data_register_r(data_width_g - 1); --msb first
                	left_data_register_r <= left_data_register_r(data_width_g - 2 downto 0) & '0'; --shift left
                   else
                	aud_data_s <= right_data_register_r(data_width_g - 1); --msb first
                	right_data_register_r <= right_data_register_r(data_width_g - 2 downto 0)& '0'; --shift left
            	    end if;
                 end if;





	    end if;

	end process;






	aud_bclk_out  <= aud_bclk_s;
   
	aud_data_out  <= aud_data_s;
        aud_lrclk_out <= aud_lrclk_s;
 
   
end rtl;


