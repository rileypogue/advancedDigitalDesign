library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.acquireToHDMI_package.all;
use work.scopeToHdmi_package.all;
use work.basicBuildingBlocks_package.all;


entity acquireToHDMI is
    PORT ( clk : in  STD_LOGIC;
           resetn : in  STD_LOGIC;
		   btn: in	STD_LOGIC_VECTOR(2 downto 0);
		   triggerCh1, triggerCh2: out STD_LOGIC;
		   conversionPlusReadoutTime: out STD_LOGIC;
		   sampleTimerRollover: out STD_LOGIC;

		   an7606data: in STD_LOGIC_VECTOR(15 downto 0);
		   an7606convst, an7606cs, an7606rd, an7606reset: out STD_LOGIC;
		   an7606od: out STD_LOGIC_VECTOR(2 downto 0);
		   an7606busy : in STD_LOGIC;

		   tmdsDataP : out  STD_LOGIC_VECTOR (2 downto 0);
           tmdsDataN : out  STD_LOGIC_VECTOR (2 downto 0);
           tmdsClkP : out STD_LOGIC;
           tmdsClkN : out STD_LOGIC;
           hdmiOen:    out STD_LOGIC
		   );
end acquireToHDMI;

architecture behavior of acquireToHDMI is

    signal cw: STD_LOGIC_VECTOR(CW_WIDTH -1 downto 0);
    signal sw: STD_LOGIC_VECTOR(SW_WIDTH -1 downto 0);
    signal dpSw : STD_LOGIC_VECTOR(DATAPATH_SW_WIDTH - 1 downto 0); --if shit fucked get rid of
    signal forcedMode: STD_LOGIC;
    signal prevButton, currButton, buttonActivity : STD_LOGIC_VECTOR(2 downto 0);

begin

    conversionPlusReadoutTime <= cw(CONVERSION_PLUS_READOUT_CW_BIT_INDEX);
    sampleTimerRollover <= cw(SAMPLE_TIMER_ROLLOVER_CW_BIT_INDEX);

    an7606convst <= cw(CONVST_CW_BIT_INDEX);
    an7606cs <= cw(CS_CW_BIT_INDEX);
    an7606rd <= cw(RD_CW_BIT_INDEX);
    an7606reset <= cw(RESET_AD7606_CW_BIT_INDEX);
    an7606od <= "000";

    ------------------------------------------------------------------------------
    -- Button Process
    ------------------------------------------------------------------------------
    process(clk)
    begin
        if(rising_edge(clk)) then
            if(resetn = '0') then
                currButton <= "000";
                prevButton <= "000";
                forcedMode <= '1';
            else
                currButton <= btn;
                prevButton <= currButton;
                if(buttonActivity(1) = '1') then
                    forcedMode <= not forcedMode;
                end if;
            end if;
        end if;
    end process;

    buttonActivity <= currButton and (not prevButton);

    sw(8 downto 3) <= dpSw(8 downto 3); -- added
    sw(1 downto 0) <= dpSw(1 downto 0); -- added
    sw(FORCED_MODE_SW_BIT_INDEX) <= forcedMode;
    sw(AN7606_BUSY_SW_BIT_INDEX) <= an7606busy;
    sw(SINGLE_MODE_SW_BIT_INDEX) <= buttonActivity(0);
    triggerCh1 <= sw(CH1_TRIG_SW_BIT_INDEX);
    triggerCh2 <= sw(CH2_TRIG_SW_BIT_INDEX);

 	datapath_inst: acquireToHDMI_datapath
        PORT MAP (
            clk => clk,
            resetn => resetn,
            cw => cw,
            sw => dpSw(DATAPATH_SW_WIDTH - 1 downto 0), -- change back to sw(datapath...) if shit breaks
            an7606data => an7606data,
            triggerVolt16bitSigned => (others => '0'),
            triggerTimePixel => (others => '0'),
            ch1Data16bitSLV => open,
            ch2Data16bitSLV => open,
            tmdsDataP => tmdsDataP,
            tmdsDataN => tmdsDataN,
            tmdsClkP => tmdsClkP,
            tmdsClkN => tmdsClkN,
            hdmiOen => hdmiOen);

	control_inst: acquireToHDMI_fsm
	   PORT MAP (
            clk => clk,
            resetn => resetn,
            sw => sw,
            cw => cw);

end behavior;