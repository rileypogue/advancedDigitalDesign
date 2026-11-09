--------------------------------------------------------------------
-- Name:	Chris Coulston
-- Date:	Feb 3, 2015
-- File:	acquireToHDMI_fsm.vhdl
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
use work.acquireToHDMI_package.all;					-- include your library here with added components ac97, ac97cmd


entity acquireToHDMI_fsm is
    PORT (  clk : in  STD_LOGIC;
            resetn : in  STD_LOGIC;
            sw: in STD_LOGIC_VECTOR(SW_WIDTH - 1 downto 0);
            cw: out STD_LOGIC_VECTOR (CW_WIDTH - 1 downto 0));
end acquireToHDMI_fsm;

architecture Behavioral of acquireToHDMI_fsm is

	signal state: state_type;	-- define the state_type in your package file	
    	signal 	FORCED_MODE_SW,
		SINGLE_MODE_SW,
		STORE_SW,
		TRIGGER_SW,
		SAMPLE_SW,
		FULL_SW,
		SHORT_SW,
		LONG_SW,
		BUSY_SW,
		CH1_TRIGGER_SW,
		CH2_TRIGGER_SW: STD_LOGIC;
		
begin

    FORCED_MODE_SW	<= sw(FORCED_MODE_SW_BIT_INDEX);
    SINGLE_MODE_SW	<= sw(SINGLE_MODE_SW_BIT_INDEX);
    STORE_SW 		<= sw(STORE_INTO_BRAM_SW_BIT_INDEX);
    TRIGGER_SW		<= sw(TRIGGER_SW_BIT_INDEX);
    SAMPLE_SW 		<= sw(SAMPLE_SW_BIT_INDEX);
    FULL_SW 		<= sw(FULL_SW_BIT_INDEX);
    SHORT_SW 		<= sw(SHORT_COUNTER_SW_BIT_INDEX);
    LONG_SW		    <= sw(LONG_COUNTER_SW_BIT_INDEX);
    BUSY_SW 		<= sw(AN7606_BUSY_SW_BIT_INDEX);
    CH1_TRIGGER_SW 	<= sw(CH1_TRIG_SW_BIT_INDEX);
    CH2_TRIGGER_SW 	<= sw(CH2_TRIG_SW_BIT_INDEX);

    
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
						state <= LONG_DELAY_STATE;
					when LONG_DELAY_STATE => 
						if LONG_SW = '1' then
							state <= RESET_AD7606;
						end if;
					when RESET_AD7606 =>
						if SHORT_SW = '1' then
							state <= WAIT_FORCED;
						end if;
                    
                    when WAIT_FORCED =>
                        if FORCED_MODE_SW = '1' then
                            if SINGLE_MODE_SW = '1' then
                                state <= SET_STORE_FLAG;
                            end if;
                        else
                            state <= BEGIN_CONVERSION;
                        end if;
                    
				    when SET_STORE_FLAG =>
						state <= BEGIN_CONVERSION;

					when CLEAR_STORE_FLAG =>
						state <= BEGIN_CONVERSION;

					when BEGIN_CONVERSION =>
						state <= ASSERT_CONVST;

					when ASSERT_CONVST => 
						if SHORT_SW = '1' then
							state <= BUSY_0;
						end if;

					when BUSY_0 =>
						if BUSY_SW = '1' then
							state <= BUSY_1;
						end if;

					when BUSY_1 =>
						if BUSY_SW = '0' then
							state <= READ_CH_1_LOW;
						end if;
					
					when READ_CH_1_LOW =>
						if (STORE_SW = '0' and SHORT_SW = '1') then
							state <= WRITE_CH_1_TRIG;
						elsif (STORE_SW = '1' and SHORT_SW = '1') then
							state <= WRITE_CH_1_BRAM;
						end if;

					when WRITE_CH_1_TRIG => 
						state <= READ_CH_1_HIGH;

					when WRITE_CH_1_BRAM =>
						state <= READ_CH_1_HIGH;

					when READ_CH_1_HIGH =>
						if SHORT_SW = '1' then
							state <= RESET_SHORT;
						end if; 

					when RESET_SHORT =>
						state <= READ_CH_2_LOW;

					when READ_CH_2_LOW =>
						if (STORE_SW = '0' and SHORT_SW = '1') then
							state <= WRITE_CH_2_TRIG;
						elsif (STORE_SW = '1' and SHORT_SW = '1') then
							state <= WRITE_CH_2_BRAM;
						end if;

					when WRITE_CH_2_TRIG => 
						state <= READ_CH_2_HIGH;

					when WRITE_CH_2_BRAM =>
						state <= READ_CH_2_HIGH;

					when READ_CH_2_HIGH =>
						if SHORT_SW = '1' then
							state <= WAIT_SAMPLE;
						end if;


                    when WAIT_SAMPLE =>
                        if FULL_SW = '1' then
                            state <= BRAM_FULL;
                        elsif SAMPLE_SW = '1' then
                            if STORE_SW = '1' then
                                state <= BEGIN_CONVERSION;
                            elsif FORCED_MODE_SW = '1' then
                                state <= WAIT_FORCED;
                            elsif CH1_TRIGGER_SW = '1' then
                                state <= SET_STORE_FLAG;
                            else
                                state <= BEGIN_CONVERSION;
                            end if;
                        end if;

					when BRAM_FULL =>
						if ((FORCED_MODE_SW = '1') or SINGLE_MODE_SW = '1') then
							state <= WAIT_FORCED;
						elsif ((FORCED_MODE_SW = '0') or SINGLE_MODE_SW = '1') then
							state <= CLEAR_STORE_FLAG;
						end if;
						  
				end case;
			end if;
		end if;
	end process;

	-------------------------------------------------------------------------------
    -- Dedicated Control Word spreadsheet: last updated 11/8/26 at 4:10
    -------------------------------------------------------------------------------
	output_process: process (state)
	begin
		case state is		
            when RESET_STATE  =>        cw <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"11"&"11"&"00"&"11"&"00";
            when LONG_DELAY_STATE  =>   cw <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"00"&"00"&"00"&"10"&"11";
            when RESET_AD7606  =>       cw <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'1'&'1'&"00"&"00"&"00"&"00"&"10";
            when WAIT_FORCED  =>        cw <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"11"&"00"&"00"&"00"&"00";
            when SET_STORE_FLAG  =>     cw <= '0'&'1'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"00"&"00"&"00"&"00"&"00";
            when CLEAR_STORE_FLAG  =>   cw <= '1'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"00"&"00"&"00"&"00"&"00";
            when BEGIN_CONVERSION  =>   cw <= '0'&'0'&'0'&'0'&'0'&'1'&'0'&'0'&'1'&'1'&'1'&'0'&"00"&"11"&"00"&"00"&"11";            
            when ASSERT_CONVST  =>      cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'0'&'1'&'1'&'0'&"00"&"10"&"00"&"00"&"10";
            when BUSY_0  =>             cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"00"&"10"&"00"&"00"&"11";
            when BUSY_1  =>             cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"00"&"10"&"00"&"00"&"00";
            when READ_CH_1_LOW  =>      cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&"00"&"10"&"00"&"00"&"10";
            when WRITE_CH_1_TRIG  =>    cw <= '0'&'0'&'0'&'1'&'1'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&"11"&"10"&"00"&"00"&"11";
            when WRITE_CH_1_BRAM  =>    cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'1'&'1'&'0'&'0'&'0'&"00"&"10"&"00"&"00"&"11";
            when READ_CH_1_HIGH  =>     cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'1'&'0'&'0'&"00"&"10"&"00"&"00"&"10";
            when RESET_SHORT  =>        cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'1'&'0'&'0'&"00"&"10"&"00"&"00"&"11";
            when READ_CH_2_LOW  =>      cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&"00"&"10"&"00"&"00"&"10";
            when WRITE_CH_2_TRIG  =>    cw <= '0'&'0'&'1'&'0'&'1'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&"11"&"10"&"00"&"00"&"11";
            when WRITE_CH_2_BRAM  =>    cw <= '0'&'0'&'0'&'0'&'1'&'0'&'1'&'0'&'1'&'0'&'0'&'0'&"10"&"10"&"00"&"00"&"11";
            when READ_CH_2_HIGH  =>     cw <= '0'&'0'&'0'&'0'&'1'&'0'&'0'&'0'&'1'&'1'&'0'&'0'&"00"&"10"&"00"&"00"&"10";
            when WAIT_SAMPLE  =>        cw <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"00"&"10"&"00"&"00"&"11";
            when BRAM_FULL  =>          cw <= '0'&'0'&'0'&'0'&'0'&'0'&'0'&'0'&'1'&'1'&'1'&'0'&"00"&"11"&"00"&"00"&"00";
        end case;
	end process;	                       

end Behavioral;



