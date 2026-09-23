----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use work.scopeToHdmi_package.all;

entity scopeToHdmi is
    PORT ( sysClk : in  STD_LOGIC;
         resetn : in  STD_LOGIC;
         btn: in	STD_LOGIC_VECTOR(2 downto 0);
         tmdsDataP : out  STD_LOGIC_VECTOR (2 downto 0);
         tmdsDataN : out  STD_LOGIC_VECTOR (2 downto 0);
         tmdsClkP : out STD_LOGIC;
         tmdsClkN : out STD_LOGIC;
         hdmiOen:    out STD_LOGIC);
end scopeToHdmi;


architecture structure of scopeToHdmi is
    signal red, green, blue: STD_LOGIC_VECTOR(7 downto 0);

    signal triggerTime, triggerVolt: STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS - 1 downto 0);
    signal pixelHorz, pixelVert: STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS - 1 downto 0);
    signal prevButton, currButton, activeButton : STD_LOGIC_VECTOR(2 downto 0);
	    
    signal ch1Wave, ch2Wave: STD_LOGIC;

    signal videoClk, videoClk5x, clkLocked: STD_LOGIC;

begin


    vsg: videoSignalGenerator
        PORT MAP (clk => videoClk, <other stuff>	);
                 

    sf: scopeFace
        PORT MAP (clk => videoClk,	<other stuff>	);
                 

    hdmi_inst: hdmi_0
        PORT MAP (
            pix_clk => videoClk,	<other stuff>	);
            

    vc: clk_wiz_0
	PORT MAP( 
	    clk_out1 => videoClk,
	    clk_out2 => videoClk5x,
	    resetn => resetn,
	    locked => clkLocked,
	    clk_in1 => sysClk);

    ------------------------------------------------------------------------------
    -- Create a process which generates a 3-bit vector which shows if button
    -- has change state.  Use this change vector to determine if you should 
    -- increment/decrement the triggerTime or triggerVolt values
    ------------------------------------------------------------------------------
    process(sysClk) 
    begin 
        if rising_edge (sysClk) then
            if resetn = '0' then
                prevButton<= "111";
                currButton <= "111";
                activeButton <= "000";
                triggerTime <= "001001110110"; -- 630 (half of scereen width ish)
                triggerVolt <= "000101101000"; -- 360 (half of screen height)
            else
                prevButton <= currButton;
                currButton <= btn;
                activeButton <= currButton xor prevButton;
        end if;
    end process;
    
    process(sysClk)
    begin 
        if activeButton(1) = '1' and currButton(1) = '1' then -- activeButton means it changed and currButton 1 means its been released
            if currButton(0) = '0' then
                -- increment triggerVoltage by 10 if PL_KEY3 is pressed and realeased while holding PL_KEY2
                triggerVolt <= triggerVolt + "1010";
            else
                -- decrement triggerVoltage by 10 if  PL_KEY3 is press and released
                triggerVolt <= triggerVolt - "1010";
            end if;
        elsif activeButton(2) = '1' and currButton(2) = '1' then -- value has changed and button 1 is being released
            if currButton(0) = '0' then
                -- increment triggerTime by 10 if PL_KEY4 is pressed and released while holding PL_KEY2
                triggerTime <= triggerTime + "1010";
            else
                -- decrement triggerTime by 10 if PL_KEY4 is pressed (and not holding PL_KEY2)
                triggerTime <= triggerTime - "1010";
            end if;
        end if;
    end process;

    ch1Wave <= '1' when  (pixelHorz = pixelVert) else '0';
    ch2Wave <= '1' when  (pixelVert = triggerVolt) else '0';

end structure;
