----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
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
    signal vde, hsync, vsync: STD_LOGIC;
    signal hdmiReset:  STD_LOGIC;

begin

    hdmiOen <= '1';
    vsg: videoSignalGenerator
        PORT MAP (clk => videoClk, resetn => resetn, hs => hsync, vs => vsync, 
                    de => vde, pixelHorz => pixelHorz, pixelVert => pixelVert);
                 

    sf: scopeFace
        PORT MAP (clk => videoClk,	resetn => resetn, pixelVert => pixelVert, pixelHorz => pixelHorz,
                 triggerTime => triggerTime, triggerVolt => triggerVolt, ch1 => Ch1Wave, ch1enb => '1', -- change c1 back to ch1Wave post testing
                ch2 => ch2Wave, ch2enb => '1', red => red, green => green, blue => blue);
                 
    hdmiReset <= not resetn;
    
    hdmi_inst: hdmi_tx_0
        PORT MAP (
            pix_clk => videoClk, pix_clkx5 => videoClk5x, rst => hdmiReset, hsync => hsync, vsync => vsync, vde => vde,
            pix_clk_locked => clkLocked, red => red, green => green, blue => blue, TMDS_DATA_P => tmdsDataP, TMDS_DATA_N => tmdsDataN,
            TMDS_CLK_P => tmdsClkP, TMDS_CLK_N => tmdsClkN, aux0_din => "0000", aux1_din => "0000", aux2_din => "0000", ade => '0');
            
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
    -- reset / set buttons
    process(sysClk) 
    begin 
        if rising_edge (sysClk) then
            if resetn = '0' then
                prevButton<= "111";
                currButton <= "111";
                activeButton <= "000";
            else
                prevButton <= currButton;
                currButton <= btn;
                activeButton <= currButton xor prevButton;
            end if;
        end if;
    end process;
    
    -- trigger button controls
    process(sysClk)
    begin 
        if rising_edge (sysClk) then
            if resetn = '0' then
                triggerTime <= "01001110110"; -- 630 (half of scereen width ish)
                triggerVolt <= "00101101000"; -- 360 (half of screen height)
            elsif activeButton(1) = '1' and currButton(1) = '1' then -- activeButton means it changed and currButton 1 means its been released
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
        end if;
    end process;

    ch1Wave <= '1' when  (pixelHorz = pixelVert) else '0';
    ch2Wave <= '1' when  (pixelVert = triggerVolt) else '0';

end structure;