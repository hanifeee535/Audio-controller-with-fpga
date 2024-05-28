-----------------------------------------------------------------------------------------------------
-- Title: Logic Synthesis Exercise 08
-- Project: Audio codec model

-- Author Name: Md Soyabbir Abu Hanif, Tanvir Mahmud
-- Group Number: 07
------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--creating the entity

entity audio_codec_model is

   --declaring the generic parameters
   
   generic (
      data_width_g : integer := 16 --in bits
          );

--defining the ports
   port(
      rst_n : in std_logic;
      aud_data_in : in std_logic;
      aud_bclk_in : in std_logic;
      aud_lrclk_in : in std_logic;

      value_left_out : out std_logic_vector (data_width_g-1 downto 0);
      value_right_out : out std_logic_vector (data_width_g -1 downto 0)
        );

end audio_codec_model;

architecture rtl of audio_codec_model is 

    type state_type is (wait_for_input, read_left, read_right);
    
    signal state_r : state_type; --register for the state
    signal aud_data_count_r :  integer range data_width_g -1 downto 0; 
    signal bclk_count_r :  integer range data_width_g -1 downto 0;    
   
    signal left_data_r : std_logic_vector (data_width_g -1 downto 0); --Audio data storing register
    signal right_data_r : std_logic_vector (data_width_g -1 downto 0); --Audio data storing register
    signal value_left_out_r : std_logic_vector (data_width_g -1 downto 0); --Audio data storing register
    signal value_right_out_r : std_logic_vector (data_width_g -1 downto 0); --Audio data storing register

begin 

--process for state transitions:
  
 process (aud_bclk_in,  rst_n)

 begin 

    if rst_n = '0' then --asynchronous reset
	state_r <= wait_for_input; --reset to the init state

	---defining the state outputs
	value_left_out_r <= (others => '0');
	value_right_out_r  <= (others => '0'); 
 
	left_data_r <= (others => '0');
	right_data_r  <= (others => '0');
 
	aud_data_count_r <= data_width_g -2 ;       
        
    elsif rising_edge(aud_bclk_in) then
	--updating the countrer
	if  aud_data_count_r = data_width_g -1 then
	     aud_data_count_r <= 0;

	else 
	     

	    aud_data_count_r  <= aud_data_count_r + 1;
	 end if;

	--state logic 
	  case state_r is

	      when wait_for_input =>

	         left_data_r <= (others => '0');
	         right_data_r  <= (others => '0');

	         -- state transition logic
		 if aud_lrclk_in  = '1' then
		     state_r <= read_left; --transition to read left
		      
		 else 
		      state_r  <= wait_for_input ; --stay in the same state 
		      
	         end if;

	      when  read_left => 


		   ---defining the state output 
		  
		if  aud_data_count_r = 15 then
		  right_data_r <=right_data_r(data_width_g -2 downto 0)& aud_data_in;
	          --value_left_out  <= (others => '0');
		else
		  left_data_r <=left_data_r(data_width_g -2 downto 0)& aud_data_in;
	         -- right_data_r  <= (others => '0');
		end if ;

		--state transition logic
		  if aud_lrclk_in  = '1' then
		     state_r <= read_left; --stay in the same state
		     		 
		  else 
		      state_r  <= read_right; --transition to the read right
		      
	         end if;

	      when  read_right => 

		--definng the state output 

		if  aud_data_count_r =15 then
		  value_left_out_r  <= left_data_r ;
		  value_right_out_r  <= right_data_r ;
		  left_data_r <=left_data_r(data_width_g -2 downto 0)& aud_data_in;
	          --value_right_out  <= (others => '0');
		else
		  right_data_r<=right_data_r(data_width_g -2 downto 0)& aud_data_in;
	          --value_left_out  <= (others => '0');
		end if ;

		---state transition logic
		  if aud_lrclk_in  = '1' then
		     state_r <= read_left; --transition to left
		    		 
		  else 
		      state_r  <= read_right; --stay in the same state
		     
	         end if;

	      when others => 
		  null; 
	   end case;
	end if;
end process;
--assigning the signals: 
value_left_out  <= value_left_out_r ;
value_right_out  <= value_right_out_r ;

end rtl;
          
