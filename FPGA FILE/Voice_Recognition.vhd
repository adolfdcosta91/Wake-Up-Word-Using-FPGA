library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

		------------------------------- Top Level Entity --------------------------------
		--                                                                             --
		-- 									       --														    --
		--  This is an implementation of a backend of a speech recognition system.     --
		--  It takes 1000 samples from a voice signal in the frequency domain..        -- 
		--  Then it compares the signal with stored samples from training stage..      --
		--  It gives a weight for each probablity and makes a desicion based on..      --
		--  the value of the weights (m , k) and display in 7-segments and LEDs.       --
		--                                                                             --
		--                                                                             --
		---------------------------------------------------------------------------------
		
entity Voice_recognition is
    Generic (
        CLK_FREQ   : integer := 50e6;   -- set system clock frequency in Hz
        BAUD_RATE  : integer := 9600; -- baud rate value
        --BAUD_RATE  : integer :=115200;
		  PARITY_BIT : string  := "none");  -- legal values: "none", "even", "odd", "mark", "space"
    Port (
        CLK        : in  std_logic; -- system clock
        RST_N      : in  std_logic; -- low active synchronous reset
        -- UART INTERFACE
        UART_TXD   : out std_logic;
        UART_RXD   : in  std_logic;
        -- DEBUG INTERFACE
        BUSY       : out std_logic;
        FRAME_ERR  : out std_logic;
		  -- FSM States
		  state_one : out  std_logic := '0';
		  state_two : out std_logic := '0';
		  state_three : out std_logic := '0';
		  state_four : out std_logic := '0';
		  -- Data Display Interface 
		  data_led : out std_logic_vector(7 downto 0);
		  -- Writes "NO =" using 7 segments 
		  n : out std_logic_vector(6 downto 0);
		  o : out std_logic_vector(6 downto 0);
		  equal : out std_logic_vector(6 downto 0);
		  -- Final Result
		  result : out std_logic_vector(6 downto 0)
);
end Voice_recognition;


		---------------------------- Top Level Architecture -----------------------------
		--                                                                             --
		--  Consists of :                                                              --
		--   * It has one process reacts to (clk, data change, reset button)           --
		--   * Arrays of trained signals  for digits                                   --
		--   * FSM with 4 states 						       -- 										    --
		--         (receiving , distance calculation, decision, display)               --
		--                                                                             --
		---------------------------------------------------------------------------------
		
		
architecture FULL of Voice_recognition is

	 --------------------------------- Arrays ------------------------------------
    	type storage is array (999 downto 0) of integer;
    	type state_type IS (A, B, C, D);
	 
	 --------------------------------- Signals ------------------------------------
    	signal reset : std_logic;
    	signal state : state_type;   	
    	signal received : storage;
    	signal valid   : std_logic;
    	signal number_one : storage;
    	signal number_zero : storage;
    	signal data    : std_logic_vector(7 downto 0);
	 
	 
	 ------------------------- Black Magic Starts Here ------------------------------
	 
	 begin
	 
		reset <= not RST_N;
		
                number_zero <= (150,131,101,109,73,163,195,150,119,148,157,125,105,103,99,98,85,91,109,115,95,81,77,84,78,71,74,75,70,58,45,52,
		49,49,38,35,40,40,37,43,46,44,47,44,41,43,36,29,28,34,38,33,32,32,38,35,29,39,29,27,24,26,32,33,29,20,23,30,30,29,
		25,27,27,25,17,15,19,21,22,20,21,24,21,16,14,14,15,15,16,18,21,23,20,15,17,21,19,18,20,24,24,20,20,23,23,21,21,22,
		21,22,21,23,22,19,21,21,23,24,19,19,24,19,18,21,19,28,39,37,38,54,64,71,85,97,105,114,124,127,130,135,125,100,91,88,
		85,80,87,85,86,97,100,93,87,87,91,102,115,110,106,117,120,108,117,126,142,156,156,143,129,129,132,137,139,139,140,139,
		126,114,115,106,101,82,66,65,69,68,69,77,72,63,71,82,83,88,94,97,96,86,75,77,83,80,70,59,61,62,61,61,57,49,42,41,44,
		47,46,43,47,46,41,40,39,41,44,40,35,37,35,36,37,29,27,28,28,27,23,23,28,23,25,23,22,25,24,19,18,19,23,25,23,21,24,26,
		24,22,21,23,25,28,31,33,33,33,33,39,44,38,33,41,42,43,50,43,28,31,42,39,33,32,32,35,42,41,39,35,37,38,36,35,30,27,39,
		50,48,36,33,43,43,40,48,42,36,47,47,48,53,50,50,58,56,59,66,68,67,67,63,63,68,74,81,83,78,71,68,72,78,79,85,100,109,
		118,122,116,105,104,106,102,107,127,146,161,176,189,190,176,154,138,136,148,163,172,183,188,187,184,184,192,207,218,
		217,208,206,204,197,189,177,166,160,154,147,144,142,139,137,139,142,147,150,147,138,136,138,140,141,146,150,148,140,
		131,127,129,137,144,147,150,149,150,153,154,150,144,135,121,109,98,88,79,72,70,63,58,59,60,54,47,54,59,52,43,38,37,38,
		42,42,43,52,52,50,49,51,54,50,51,48,44,43,44,41,41,43,43,56,63,56,37,39,43,37,34,31,23,27,37,34,26,28,32,30,26,26,
		21,19,29,31,22,19,23,26,32,29,22,23,22,17,22,23,18,27,31,24,19,19,19,18,17,17,20,24,24,22,19,19,19,21,21,20,23,25,
		25,28,27,23,21,25,28,27,25,23,24,27,28,29,31,31,29,26,26,29,33,36,34,34,32,29,27,28,31,29,24,27,28,33,35,36,37,38,
		39,39,37,38,40,38,35,30,28,29,34,40,39,35,33,34,34,35,38,40,40,34,29,27,26,23,23,22,23,23,23,22,20,20,23,24,23,26,
		28,23,27,31,28,23,25,24,22,24,26,28,27,29,30,27,23,27,32,28,24,24,26,26,22,18,18,19,18,16,19,22,18,15,18,20,16,15,
		15,14,13,16,15,13,13,11,12,12,12,12,12,10,7,7,8,9,10,10,11,12,12,13,12,11,9,9,9,8,9,10,11,11,11,12,14,13,14,14,13,
		14,15,14,14,14,14,15,14,14,15,16,17,16,15,17,18,18,19,19,18,18,19,19,18,17,16,13,14,16,16,15,14,16,17,20,21,19,16,
		14,15,16,15,16,14,13,13,13,13,15,15,14,14,10,9,10,12,14,13,12,12,13,15,15,14,14,15,16,17,16,15,16,17,20,21,19,18,15,
		14,15,17,18,17,15,13,11,11,10,11,13,15,13,11,11,13,14,13,12,9,6,7,8,8,10,11,10,11,10,8,9,10,11,13,11,10,13,13,10,11,
		11,13,13,12,13,15,14,13,17,18,16,14,14,15,16,17,17,17,19,19,18,15,16,17,17,15,15,16,18,17,17,15,17,19,20,20,18,16,14,
		15,18,17,14,13,16,20,20,16,14,14,16,19,19,18,16,16,17,17,17,18,20,23,21,18,18,20,19,19,19,19,19,20,21,19,18,17,18,19,
		21,20,17,16,15,17,18,18,16,15,18,20,21,19,20,22,22,21,20,18,16,17,20,21,19,20,21,23,23,20,17,16,17,18,19,21,21,20,19,
		19,20,21,21,19,17,17,17,17,18,18,17,17,17,15,15,15,14,16,18,21,22,21,20,19,19,18,18,19,18,16,14,12,12,14,14,13,12,12,
		15,15,14,12,10,9,11,13,13,16,17,17,16,18,19,18,16,15,13,11,13,13,12,13,13,15,16,17,17,16,15,16,15,14,14,18,18,16,15,15,
		16,16,18,19,21,23,22,21,22,24,23,23,23,22,22,22,23,24,24,24,24,23,22,21,21,23,24,25,26,25,23,22,23,23);
		
		number_one <= (10,12,11,10,10,10,13,14,12,11,13,13,13,12,10,11,11,11,11,10,9,9,9,8,7,7,7,7,7,5,5,5,4,4,4,5,5,7,6,5,6,6,7,5,4,5,5,4,5,5,4,4,5,
		4,3,3,3,3,3,3,3,3,3,2,3,3,3,2,3,3,2,2,2,3,3,2,3,3,3,3,3,3,3,3,3,3,3,3,3,2,3,3,2,2,2,2,2,2,2,2,2,2,2,2,3,3,2,2,2,2,2,2,2,2,2,2,
		2,2,2,2,2,2,3,2,3,3,3,3,3,3,3,4,4,5,5,6,6,7,8,9,11,12,14,14,15,17,18,19,23,24,25,28,30,29,31,34,34,35,37,35,32,37,43,41,33,37,46,
		49,42,35,41,52,56,50,47,50,55,60,61,55,46,47,57,69,73,77,82,81,73,62,49,48,47,43,37,27,17,19,25,30,32,31,30,27,25,22,20,18,16,14,
		12,9,7,6,7,7,7,7,6,5,5,5,5,4,3,3,4,5,5,5,4,4,4,3,4,3,3,4,3,4,3,4,4,3,3,2,3,3,4,4,3,3,3,3,4,4,4,3,3,3,3,4,4,4,4,3,4,4,4,5,5,4,4,5,
		5,5,6,7,7,7,7,8,9,9,9,10,11,11,11,12,14,15,16,16,16,17,17,19,20,21,22,22,22,23,25,26,26,26,26,25,25,26,27,27,27,28,28,26,26,26,25,
		25,25,25,25,26,28,30,32,31,30,30,30,30,30,30,30,31,31,31,30,30,30,31,32,33,34,33,30,29,31,34,36,37,36,36,35,34,33,35,37,38,40,40,40,
		39,36,34,33,33,35,35,36,36,36,34,31,29,27,27,26,25,22,19,16,17,17,16,14,11,9,10,11,12,11,10,9,9,10,11,12,13,14,15,16,16,15,14,11,10,8,
		7,7,9,10,10,11,11,12,12,13,12,12,12,12,12,12,12,12,11,11,11,11,12,12,12,12,11,12,12,13,13,13,13,13,14,14,15,15,16,16,16,16,17,17,18,
		19,20,21,22,24,24,25,26,26,26,26,27,27,27,27,27,27,27,28,28,29,29,30,30,31,32,33,34,35,35,36,36,37,37,38,38,39,40,41,42,43,44,44,45,
		44,44,44,44,44,44,44,44,43,41,40,38,35,33,31,29,28,26,25,25,25,26,27,29,30,32,34,36,38,40,41,40,39,38,37,38,38,38,39,40,41,42,42,42,41,
		40,38,36,34,33,31,30,29,29,28,27,26,26,26,26,25,24,24,23,22,22,22,21,21,20,19,18,19,20,20,20,19,18,17,16,16,16,15,13,12,11,11,12,14,15,16,
		16,17,18,19,21,23,25,26,27,27,28,28,28,27,26,26,25,24,23,23,22,22,22,22,22,21,21,20,20,21,20,20,20,20,19,18,18,18,19,20,20,21,22,23,24,25,
		26,27,28,28,29,30,32,33,33,32,32,32,33,35,36,37,37,38,38,39,40,41,41,41,40,40,40,41,42,43,43,44,45,46,48,49,49,49,50,51,51,52,52,52,52,53,
		53,53,54,54,53,51,50,48,46,46,45,45,45,46,47,48,48,49,50,50,51,52,52,52,51,51,50,50,49,48,46,45,44,43,42,40,38,37,35,35,35,35,34,34,33,33,
		31,30,28,27,25,24,24,24,24,24,22,20,18,16,15,15,16,16,16,16,15,14,13,12,13,14,15,15,16,16,15,14,13,12,12,12,12,13,13,13,13,13,13,13,14,14,
		14,14,14,14,14,14,14,14,15,15,15,15,15,15,15,16,16,17,18,19,20,20,21,20,20,19,19,19,19,19,19,19,19,19,18,18,18,18,18,17,17,17,16,16,16,15,
		16,16,17,18,18,18,18,17,17,17,17,18,18,18,18,18,18,18,19,19,19,19,19,19,19,19,19,20,20,20,20,20,19,19,20,20,20,20,18,18,17,16,15,15,16,16,
		16,16,16,16,16,15,15,15,15,15,15,15,15,14,14,14,14,15,16,16,16,16,16,16,16,16,17,17,17,17,17,17,17,17,17,17,18,18,19,19,19,18,16,16,16,16,
		16,17,18,19,19,19,18,16,15,14,13,13,15,16,18,19,19,19,18,18,17,17,17,17,18,18,19,19,19,18,18,18,18,18,18,18,18,18,18,18,17,18,18,18,18,18,
		20,21,21,21,21,20,20,20,20,21,21,21,21,22,22,23,23,23,22,22,22,22,22,22,22,22,23,23,24,24,24,25,25,24,25,25,24,24,24,24,23);
		
		
		--------------------------------- Component Mapping ------------------------------------
		uart_i: entity work.UART
			 generic map (
				  CLK_FREQ    => CLK_FREQ,
				  BAUD_RATE   => BAUD_RATE,
				  PARITY_BIT  => PARITY_BIT)
			 port map (
				  CLK         => CLK,
				  RST         => reset,
				  -- UART INTERFACE
				  UART_TXD    => UART_TXD,
				  UART_RXD    => UART_RXD,
				  -- USER DATA OUTPUT INTERFACE
				  DATA_OUT    => data,
				  DATA_VLD    => valid,
				  FRAME_ERROR => FRAME_ERR,
				  -- USER DATA INPUT INTERFACE
				  DATA_IN     => data,
				  DATA_SEND   => valid,
				  BUSY        => BUSY);
		
		
		
		---------------------------- Voice Recognition Proeces ----------------------------------
		voice_recognition: process (clk,data,reset)
		
		variable index : integer := 0;
      		variable min_number : integer := 2;
		variable i, j , m, k: integer range 0 to 999;

		BEGIN
		
				--------------------------------------------
				--		FSM RESET                 --
				--------------------------------------------	
				If (reset = '1') THEN 

				 State <= A;
				 
				 state_one   <= '1';
				 state_two   <= '1';
				 state_three <= '1';
				 state_four  <= '1';
				 
		      		 i := 0;
				 j := 0;
				 m := 0;
				 k := 0;
				 
				 index := 0;
				 min_number := 2;
 				 data_led <= "00000000";
				 result <= "1111111" ;

				 ELSIF rising_edge(clk) THEN
				 
				 CASE State IS
				  
					--------------------------------------------
					--		 State 1                  --
					--	  Data Receiving and storage       --
					--------------------------------------------
					WHEN A => 
						state_one <= '0';
						state_two <= '1';
						state_three <= '1';
						state_four <= '1';
						
						if (index < 1000) and valid = '1' then 
							received(index) <= to_integer(unsigned(data));
							data_led <= data;
							index := index + 1;
						else if (index >= 1000) then
							state <= B;
							index := 0;
							end if;
						end if;
					--------------------------------------------
					--	          State 2                 --
					--	    Distance Calculation          --
					--------------------------------------------
					WHEN B => 
						 state_one <= '0';
						 state_two <= '0';
						 state_three <= '1';
						 state_four <= '1';
						 
						 if (i < 1000) then
						 
						 	 -- Number One --
							 if(received(i) = number_one(i)) then 
							 m := m+1;
							 end if; 
							 
							 -- Number Zero --
							 if (received(i) = number_zero(i)) then 
							 k := k+1;
							 end if; 
							 
							 i := i + 1;
							 
 						 else  
						 
							state <= C;
							i := 0;
							
						 end if;
					--------------------------------------------
					--	        State 3                   --
					--	 Comparing with Numbers Arrays    --
					--------------------------------------------
					WHEN C => 
						state_one <= '0';
						state_two <= '0';
						state_three <= '0';
						state_four <= '1';			
						
						if(m < k) then  min_number := 1; 
					   	end if;
						
						if (m > k) then min_number := 0;
						end if;
						
						state <= D;
						
					--------------------------------------------
					--		 State 4                  --
					--   Display Results On Seven Segments    --
					--------------------------------------------
					WHEN D=> 
						state_one <= '0';
						state_two <= '0';
						state_three <= '0';
						state_four <= '0';
						---------------------------------------------------
						n <= "1001000" ;
					   	o <= "0100011" ;
					   	equal <= not "1001000" ;
					   	result <= "1111111" ;
						---------------------------------------------------
						if (min_number = 0) then
						-- Display Zero
					 	    result <= "1000000";
				     		    data_led <= "01010101";
						end if;
						
						if (min_number = 1) then
						-- Display One
					            result <= "1111001" ;
						    data_led <= "10101010";
						end if;

						if (min_number /= 1 and min_number /= 0) then
						-- Display NOTHING
					            result <= "1111111" ;
						    data_led <= "11111111";
						end if;
						
						state_one <= '1';
					   	state_two <= '1';
					   	state_three <= '1';
					   	state_four <= '1';
						 
				        --------------------------------------------
					--	      State Default               --
					--------------------------------------------
					WHEN others =>
						State <= A;
						
				 END CASE;
				 
			 END IF;
			 
	END PROCESS;
	
END FULL;
