--------------------------------------------------------------------
-- Name:	Chris Coulston
-- Date:	Feb 3, 2015
-- Modified:	Sept 2022
-- File:	acquireToHDMI_Datapath.vhdl
-- HW:		Lab 3
-- Crs:		ECE 383 and EENG 484
--
-- Purp: The complete datapath for the audio O'scope
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
use IEEE.NUMERIC_STD.ALL;

use work.acquireToHDMI_Package.all;			
use work.basicBuildingBlocks_package.all;		
use work.hdmi_package.all;

entity acquireToHDMI_datapath is
    PORT ( clk : in  STD_LOGIC;
           resetn : in  STD_LOGIC;
		   cw : in STD_LOGIC_VECTOR(CW_WIDTH -1 downto 0);
		   sw : out STD_LOGIC_VECTOR(DATAPATH_SW_WIDTH - 1 downto 0);
		   an7606data: in STD_LOGIC_VECTOR(15 downto 0);

           triggerVolt16bitSigned: in SIGNED(15 downto 0);
		   triggerTimePixel: in STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS-1 downto 0);
		   ch1Data16bitSLV, ch2Data16bitSLV: out STD_LOGIC_VECTOR(15 downto 0);
		   
		   tmdsDataP : out  STD_LOGIC_VECTOR (2 downto 0);
           tmdsDataN : out  STD_LOGIC_VECTOR (2 downto 0);
           tmdsClkP : out STD_LOGIC;
           tmdsClkN : out STD_LOGIC;
           hdmiOen:    out STD_LOGIC
		   );
end acquireToHDMI_datapath;

architecture behavior of acquireToHDMI_datapath is

    signal storeIntoBramFlag: STD_LOGIC;
    -- HDMI SIGNALS ----
    signal red, green, blue: STD_LOGIC_VECTOR(7 downto 0);
    signal trigTime, trigVscr : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS - 1 downto 0);
    signal pixelHorz, pixelVert: STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS - 1 downto 0);
    signal prevButton, currButton, activeButton : STD_LOGIC_VECTOR(2 downto 0);
    signal ch1Wave, ch2Wave: STD_LOGIC;
    signal videoClk, videoClk5x, clkLocked: STD_LOGIC;
    signal vde, hsync, vsync: STD_LOGIC;

    -- COUNTER + COMPARATOR CONTROLS --
    signal sample_mux_control, short_counter_control, long_counter_control, sample_counter_control : STD_LOGIC_VECTOR(1 downto 0);
    signal short_counts : STD_LOGIC_VECTOR(SHORT_DELAY_50Mhz_CONST_WIDTH - 1 downto 0);
    signal long_counts : STD_LOGIC_VECTOR(SHORT_DELAY_50Mhz_CONST_WIDTH - 1 downto 0);
    signal sample_counts, SAMPLE_COMPARISON : STD_LOGIC_VECTOR(31 downto 0);
    signal short_timer_done, long_timer_done, sampling_done : STD_LOGIC_VECTOR;

    -- trigger logic signals -- 
    signal trig1_reg_control, trig2_reg_control : STD_LOGIC; 
    signal trig1_curr_value_greater_than_thresh, trig2_curr_greater_than_thresh, trig1_last_less_than_thresh, trig2_last_less_than_thresh : STD_LOGIC;
    signal last_SLV1, last_SLV2 : STD_LOGIC_VECTOR(15 downto 0);

    
begin
    -- control word assignments
    short_counter_control <= cw(SHORT_DELAY_COUNTER_CW_BIT_INDEX downto 0);
    long_counter_control <= cw(LONG_DELAY_COUNTER_CW_BIT_INDEX downto 2);
    sample_counter_control <= cw(7 downto 6);
    sample_mux_control <= cw(5 downto 4);

    -- status word assignments
    sw(SHORT_COUNTER_SW_BIT_INDEX) <= short_timer_done;
    sw(LONG_COUNTER_SW_BIT_INDEX) <= long_timer_done;
    sw(SAMPLE_SW_BIT_INDEX) <= sampling_done;

    shortCounter : genericCounter
        generic map (N=> SHORT_DELAY_50Mhz_CONST_WIDTH)
        port map (clk => clk, resetn => resetn, c => short_counter_control, d => (others => '0'), q=> short_counts);

    longCounter : genericCounter
        generic map (N=> LONG_DELAY_50Mhz_CONST_WIDTH)
        port map (clk => clk, resetn => resetn, c => long_counter_control, d => (others => '0'), q=> long_counts);

    sampleCounter : genericCounter
        generic map (N=> 32)
        port map (clk => clk, resetn => resetn, c => sample_counter_control, d => (others => '0'), q=> sample_counts);

    shortComparator : genericCompare
        generic map (N => SHORT_DELAY_50Mhz_CONST_WIDTH)
        port map (x => SHORT_DELAY_50Mhz_COUNTS, y => short_counts, g => open, l => open, e => short_timer_done);

    longComparator : genericCompare
        generic map (N => LONG_DELAY_50Mhz_CONST_WIDTH)
        port map (x => LONG_DELAY_50Mhz_COUNTS, y => long_counts, g => open, l => open, e => long_timer_done);

    sampleComparator : genericCompare
        generic map (N => 32)
        port map (x => sample_counts, y => SAMPLE_COMPARISON, g => open, l => open, e => sampling_done);

    sampleMux : genericMux4x1
        generic map (N => 32)
        port map (y3 => LOW_RATE, y2 => LOWEST_RATE, y1 => HIGH_RATE, y0 => HIGHEST_RATE, s=> sample_mux_control, f=> SAMPLE_COMPARISON)

    gReg1 : genericRegister 
        generic map(N => 16)
        port map (clk => clk, resetn => resetn, load=>trig1_reg_control, d=an7606data, q=>ch1Data16bitSLV);

    lReg1 : genericRegister
        generic map (N => 16)
        port map (clk => clk, resetn=> resetn, load = trig1_reg_control, d=ch1Data16bitSLV, q=> last_SLV1);

    gReg1 : genericCompare
        generic map (N => 16)
        port map(x => ch1Data16bitSLV, y => triggerVolt16bitSigned, g => trig1_curr_value_greater_than_thresh, l => open , e => open);

    lReg1 : genericCompare
        generic map (N => 16)
        port map(x => last_SLV1, y => triggerVolt16bitSignedm, g => open, l => trig1_last_less_than_thresh, e => open);

    sw(CH1_TRIG_SW_BIT_INDEX) => trig1_curr_value_greater_than_thresh and trig1_last_less_than_thresh;

    gReg2 : genericRegister 
        generic map(N => 16)
        port map (clk => clk, resetn => resetn, load=>trig2_reg_control, d=an7606data, q=>ch2Data16bitSLV);

    lReg2 : genericRegister
        generic map (N => 16)
        port map (clk => clk, resetn=> resetn, load = trig2_reg_control, d=ch2Data16bitSLV, q=> last_SLV2);

    gReg2 : genericCompare
        generic map (N => 16)
        port map(x => ch2Data16bitSLV, y => triggerVolt16bitSigned, g => trig2_curr_value_greater_than_thresh, l => open , e => open);

    lReg2 : genericCompare
        generic map (N => 16)
        port map(x => last_SLV2, y => triggerVolt16bitSignedm, g => open, l => trig2_last_less_than_thresh, e => open);


    sw(CH2_TRIG_SW_BIT_INDEX) => trig2_curr_value_greater_than_thresh and trig2_last_less_than_thresh;

    -- HDMI SCOPE TO HDMI CODE COPIED --
    hdmiOen <= '1';
    vsg: videoSignalGenerator
        PORT MAP (clk => videoClk, resetn => resetn, hs => hsync, vs => vsync, 
                    de => vde, pixelHorz => pixelHorz, pixelVert => pixelVert);
                 

    sf: scopeFace
        PORT MAP (clk => videoClk,	resetn => resetn, pixelVert => pixelVert, pixelHorz => pixelHorz,
                 triggerTime => trigTime, triggerVolt => trigVscr, ch1 => Ch1Wave, ch1enb => '1', -- change c1 back to ch1Wave post testing
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

    -- Simple SR Latch to assist FSM
    process(clk)
    begin
        if(rising_edge(clk)) then
            if(resetn ='0') then
                storeIntoBramFlag <= '0';
            elsif (cw(SET_STORE_FLAG_CW_BIT_INDEX) = '1') then
                storeIntoBramFlag <= '1';
            elsif (cw(CLEAR_STORE_FLAG_CW_BIT_INDEX) = '1') then
                storeIntoBramFlag <= '0';
            end if;
        end if;
    end process;

    sw(STORE_INTO_BRAM_SW_BIT_INDEX) <= storeIntoBramFlag;
    
 
      
    vc: clk_wiz_0
        PORT MAP (
            clk_in1 => clk,
            clk_out1 => videoClk,
            resetn => resetn,
            clk_out2 => videoClk5x);



end behavior;
