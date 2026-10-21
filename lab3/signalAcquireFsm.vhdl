--------------------------------------------------------------------
-- Name:	Chris Coulston
-- Date:	Feb 3, 2015 
-- Modified:	Fall 2022
-- File:	lab2_fsm.vhdl
-- HW:	Lab2
--	Crs:	ECE 383
--
-- Purp: The control unit for the audio O'scope
--
-- Documentation:	No help, though I used an example from my Digital
--						Design text book.
--
-- Academic Integrity Statement: I certify that, while others may have 
-- assisted me in brain storming, debugging and validating this program, 
-- the program itself is my own work. I understand that submitting code 
-- which is the work of other individuals is a violation of the honor   
-- code.  I also understand that if I knowingly give my original work to 
-- another individual is also a violation of the honor code. 
------------------------------------------------------------------------- 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.signalAcquire_Package.all;			-- include your library here with added components ac97, ac97cmd

entity signalAcquire_Fsm is
    PORT (  clk : in  STD_LOGIC;
            resetn : in  STD_LOGIC;
            sw: in STD_LOGIC_VECTOR(SW_WIDTH - 1 downto 0);
            cw: out STD_LOGIC_VECTOR (CW_WIDTH - 1 downto 0));
end signalAcquire_Fsm;

architecture Behavioral of signalAcquire_Fsm is

	signal state: state_type;
    constant HOLD : STD_LOGIC_VECTOR(1 downto 0) := "00";
    constant LOAD : STD_LOGIC_VECTOR(1 downto 0) := "01";
    constant COUNT_UP : STD_LOGIC_VECTOR(1 downto 0) := "10";
    constant RESET_COUNTER : STD_LOGIC_VECTOR(1 downto 0) := "11";

	signal SHORT_DELAY_DONE_SW, READ_ALL_CHANNELS_SW, LONG_DELAY_DONE_SW, START_CONV_SW, BUSY_SW : STD_LOGIC;

begin

    -- defining intuitive names for the status word bits to make interperting the
    -- logic in the state_process much easier and thus, you'll make fewer errors.
    SHORT_DELAY_DONE_SW <= sw(SHORT_DELAY_DONE_SW_BIT_INDEX);
    LONG_DELAY_DONE_SW <= sw(LONG_DELAY_DONE_SW_BIT_INDEX);
    READ_ALL_CHANNELS_SW <= sw(ALL_CHANNELS_HAVE_BEEN_READ_SW_BIT_INDEX);
    START_CONV_SW <= sw(START_CONV_SW_BIT_INDEX);
    BUSY_SW <= sw(BUSY_SW_BIT_INDEX);
    
	-------------------------------------------------------------------------------
	-------------------------------------------------------------------------------
	state_proces: process(clk)  
	begin
		if (rising_edge(clk)) then
			if (resetn = '0') then 
				state <= RESET_STATE;
			else 
				case state is
                    when RESET_STATE =>
                        state <= long_delay;
                    when long_delay =>
                        if LONG_DELAY_DONE_SW = '1' then
                            state <= reset_AD7606;
                        else
                            state <= long_delay;
                        end if;
                    when reset_AD7606 =>
                        if SHORT_DELAY_DONE_SW = '1' then 
                            state <= wait_trigger;
                        else
                            state <= reset_AD7606;
                        end if;
                    when wait_trigger =>
                        if START_CONV_SW = '1' then
                            state <= assert_convst;
                        else
                            state <= wait_trigger;
                        end if;
                    when assert_convst =>
                        if SHORT_DELAY_DONE_SW = '1' then
                            state <= wait_busy_0;
                        else 
                            state <= assert_convst;
                        end if;
                    when wait_busy_0 =>
                        if BUSY_SW = '0' then -- busy acttive high
                            state <= wait_busy_0;
                        else
                            state <= wait_busy_1;
                        end if;
                    when wait_busy_1 =>
                        if BUSY_SW = '1' then
                            state <= wait_busy_1;
                        else
                            state <= wait_valid_data;
                        end if;
                    when wait_valid_data =>
                        if SHORT_DELAY_DONE_SW = '1' then
                            state <= latch;
                        else
                            state <= wait_valid_data;
                        end if;
                    when latch =>
                        state <= pause_between_channels;
                    when pause_between_channels =>
                        if SHORT_DELAY_DONE_SW = '1' then
                            state <= clear_short_counter;
                        else 
                            state <= pause_between_channels;
                        end if;
                    when clear_short_counter =>
                        if READ_ALL_CHANNELS_SW = '1' then
                            state <= wait_trigger;
                        else 
                            state <= wait_valid_data;
                        end if;
				end case;
			end if;
		end if;
	end process;

    -------------------------------------------------------------------------------
    -- LPT: List all the bits of your control word and define their purpose.
    --      cw              Purpose
    -- 7 an7606convst
    -- 6 an7606cs
    -- 5 an7606rs
    -- 4 an7606rsest
    -- 3 longDelay
    -- 2 shortDelay
    -- 1 rfCounter
    -- 0 rfWrite
    -- LPT: Add the truth table for any BBB which are used in the datapath
    --  counter control     Function
    --
    -------------------------------------------------------------------------------
	output_process: process (state)
	begin
	    case state is
                when RESET_STATE =>            cw <= "1110" & RESET_COUNTER & RESET_COUNTER & RESET_COUNTER & "0";
                when long_delay =>             cw <= "1110" & COUNT_UP & RESET_COUNTER & HOLD & "0";
                when reset_AD7606 =>           cw <= "1111" & RESET_COUNTER & COUNT_UP & HOLD & "0";
                when wait_trigger =>           cw <= "1110" & HOLD & RESET_COUNTER & HOLD & "0";
                when assert_convst =>          cw <= "0110" & HOLD & COUNT_UP & HOLD & "0";
                when wait_busy_0 =>            cw <= "1110" & HOLD & RESET_COUNTER & HOLD & "0";
                when wait_busy_1 =>            cw <= "1110" & HOLD & HOLD & RESET_COUNTER & "0";
                when wait_valid_data =>        cw <= "1000" & HOLD & COUNT_UP & HOLD & "0";
                when latch =>                  cw <= "1100" & HOLD & RESET_COUNTER & HOLD & "1";
                when pause_between_channels => cw <= "1100" & HOLD & COUNT_UP & HOLD & "0";
                when clear_short_counter =>    cw <= "1100" & HOLD & RESET_COUNTER & COUNT_UP & "0";
		end case;
	end process;
end Behavioral;



