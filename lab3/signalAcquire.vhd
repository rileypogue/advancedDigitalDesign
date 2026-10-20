--------------------------------------------------------------------
-- Name:	Chris Coulston
-- Date:	Fall 2022
-- File:	signalAcquire.vhd
--
-- Purp: Tie the datapath and control unit together
--
-- Documentation:	No help
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.signalAcquire_Package.all;					-- Include any packages that are instantiated
use work.basicBuildingBlocks_package.all;

entity signalAcquire is
    PORT ( clk : in  STD_LOGIC;
           resetn : in  STD_LOGIC;
		   btn: in	STD_LOGIC_VECTOR(2 downto 0);
		   an7606data: in STD_LOGIC_VECTOR(15 downto 0);
		   an7606convst, an7606cs, an7606rd, an7606reset: out STD_LOGIC;
		   an7606od: out STD_LOGIC_VECTOR(2 downto 0);
		   an7606busy : in STD_LOGIC;
		   reg0Magnitude: out STD_LOGIC_VECTOR(3 downto 0));		   
end signalAcquire;

architecture behavior of signalAcquire is

    signal datapath_sw : STD_LOGIC_VECTOR(DATAPATH_SW_WIDTH - 1 downto 0);
    signal fsm_sw : STD_LOGIC_VECTOR(SW_WIDTH - 1 downto 0);
    signal cw : STD_LOGIC_VECTOR(CW_WIDTH - 1 downto 0);
    signal prevButton, currButton, activeButton : STD_LOGIC_VECTOR(2 downto 0);
    signal convst : STD_LOGIC := '0';
    signal rfData : STD_LOGIC_VECTOR(15 downto 0);
    signal PL_LEDS : STD_LOGIC_VECTOR(3 downto 0);

begin
    datapath : signalAcquire_Datapath 
        PORT MAP (clk => clk, resetn => resetn, cw => cw, 
              sw => datapath_sw, an7606data => an7606data, 
              rfAddr => "000", rfData => rfData);

    fsm_sw <= convst & an7606busy & datapath_sw; 

    controlUnit : signalAcquire_Fsm
        PORT MAP (clk => clk, resetn => resetn, sw => fsm_sw, cw => cw);

    an7606convst <= cw(CONVST_CW_BIT_INDEX);
    an7606cs <= cw(CS_CW_BIT_INDEX);
    an7606rd <= cw(RD_CW_BIT_INDEX);
    an7606reset <= cw(RESET_AD7606_CW_BIT_INDEX);

    reg0Magnitude <= PL_LEDS;
    an7606od <= "000";

    -- button processes, convert when any button has been pressed and released
    process(clk) 
    begin
        if rising_edge (clk) then
            if resetn = '0' then
                prevButton <= "000";
                currButton <= "000";
            else
                prevButton <= currButton;
                currButton <= btn;
                if prevButton(0) = '0' and btn(0) = '1'  then
                    convst <= '1';
                elsif activeButton(1) = '0' and btn(1) = '1' then
                    convst <= '1';
                elsif activeButton(2) = '0' and btn(2) = '1' then
                    convst <= '1';
                else
                    convst <= '0';
                end if;
            end if;
        end if;
    end process;


    -- PL BUTTON comparators
    comapare1 : genericCompare
        generic map (N=> 16)
        port map(x=> rfData, y => FIRST_THRESHOLD_CONSTANT, g => PL_LEDS(3), l => open, e=> open);

    comapare2 : genericCompare
        generic map (N=> 16)
        port map(x=> rfData, y => SECOND_THRESHOLD_CONSTANT, g => PL_LEDS(2), l => open, e=> open);

    comapare3 : genericCompare
        generic map (N=> 16)
        port map(x=> rfData, y => THIRD_THRESHOLD_CONSTANT, g => PL_LEDS(1), l => open, e=> open);

    comapare4 : genericCompare
        generic map (N=> 16)
        port map(x=> rfData, y => FOURTH_THRESHOLD_CONSTANT, g => PL_LEDS(0), l => open, e=> open);
end behavior;
