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

use work.acquireToHDMI_package.all;
use work.basicBuildingBlocks_package.all;
use work.scopeToHdmi_package.all;

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

    constant V_CENTER : integer := 400;
    constant V_SLOPE  : integer := -600;
    constant BRAM_ADDR_BITS : integer := 10;

    signal storeIntoBramFlag: STD_LOGIC;
    -- HDMI SIGNALS ----
    signal red, green, blue: STD_LOGIC_VECTOR(7 downto 0);
    signal trigVscr : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS - 1 downto 0);
    signal pixelHorz, pixelVert: STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS - 1 downto 0);
    signal ch1Wave, ch2Wave: STD_LOGIC;
    signal videoClk, videoClk5x, clkLocked: STD_LOGIC;
    signal vde, hsync, vsync, hdmiReset: STD_LOGIC;

    -- COUNTER + COMPARATOR CONTROLS --
    signal sample_mux_control, short_counter_control, long_counter_control, sample_counter_control, addr_counter_control : STD_LOGIC_VECTOR(1 downto 0);
    signal short_counts : STD_LOGIC_VECTOR(SHORT_DELAY_50Mhz_CONST_WIDTH - 1 downto 0);
    signal long_counts : STD_LOGIC_VECTOR(LONG_DELAY_50Mhz_CONST_WIDTH - 1 downto 0);
    signal sample_counts, SAMPLE_COMPARISON : STD_LOGIC_VECTOR(31 downto 0);
    signal short_timer_done, long_timer_done, sampling_done : STD_LOGIC;

    -- trigger logic signals --
    signal trig1_reg_control, trig2_reg_control : STD_LOGIC;
    signal trig1_curr_value_greater_than_thresh, trig2_curr_value_greater_than_thresh, trig1_last_less_than_thresh, trig2_last_less_than_thresh : STD_LOGIC;
    signal ch1_reg, ch2_reg, last_SLV1, last_SLV2 : STD_LOGIC_VECTOR(15 downto 0);
    signal ch1_cmp, ch2_cmp, last1_cmp, last2_cmp, trig_cmp : STD_LOGIC_VECTOR(15 downto 0);

    -- BRAM logic signals
    signal wrAddr, rdAddr : STD_LOGIC_VECTOR(BRAM_ADDR_BITS - 1 downto 0);
    signal pixelOffset : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS - 1 downto 0);
    signal trig1_event, trig2_event : STD_LOGIC;
    signal ch1dout, ch2dout : STD_LOGIC_VECTOR(15 downto 0);
    signal ch1Pixel, ch2Pixel : STD_LOGIC_VECTOR(VIDEO_WIDTH_IN_BITS - 1 downto 0);

    function sample_to_row(s : STD_LOGIC_VECTOR(15 downto 0)) return STD_LOGIC_VECTOR is
        variable prod : SIGNED(31 downto 0);
        variable pix  : SIGNED(31 downto 0);
    begin
        prod := signed(s) * to_signed(V_SLOPE, 16);
        pix := shift_right(prod, 16) + to_signed(V_CENTER, 32);
        return STD_LOGIC_VECTOR(pix(VIDEO_WIDTH_IN_BITS - 1 downto 0));
    end function;

begin
    -- control word assignments
    short_counter_control <= cw(SHORT_DELAY_COUNTER_CW_BIT_INDEX downto 0);
    long_counter_control <= cw(LONG_DELAY_COUNTER_CW_BIT_INDEX downto 2);
    sample_counter_control <= cw(7 downto 6);
    sample_mux_control <= cw(5 downto 4);
    addr_counter_control <= cw(DATA_STORAGE_CW_COUNTER_BIT_INDEX downto DATA_STORAGE_CW_COUNTER_BIT_INDEX - 1);
    trig1_reg_control <= cw(TRIG_CH1_WRITE_CW_BIT_INDEX);
    trig2_reg_control <= cw(TRIG_CH2_WRITE_CW_BIT_INDEX);

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
        port map (y3 => LOW_RATE, y2 => LOWEST_RATE, y1 => HIGH_RATE, y0 => HIGHEST_RATE, s=> sample_mux_control, f=> SAMPLE_COMPARISON);

    -- trigger stuff
    ch1Data16bitSLV <= ch1_reg;
    ch2Data16bitSLV <= ch2_reg;

    ch1_cmp <= (not ch1_reg(15)) & ch1_reg(14 downto 0);
    ch2_cmp <= (not ch2_reg(15)) & ch2_reg(14 downto 0);
    last1_cmp <= (not last_SLV1(15)) & last_SLV1(14 downto 0);
    last2_cmp <= (not last_SLV2(15)) & last_SLV2(14 downto 0);
    trig_cmp <= (not triggerVolt16bitSigned(15)) & STD_LOGIC_VECTOR(triggerVolt16bitSigned(14 downto 0));

    gReg1 : genericRegister
        generic map(N => 16)
        port map (clk => clk, resetn => resetn, load => trig1_reg_control, d => an7606data, q => ch1_reg);

    lReg1 : genericRegister
        generic map (N => 16)
        port map (clk => clk, resetn => resetn, load => trig1_reg_control, d => ch1_reg, q=> last_SLV1);

    gCompare1 : genericCompare
        generic map (N => 16)
        port map(x => ch1_cmp, y => trig_cmp, g => trig1_curr_value_greater_than_thresh, l => open, e => open);

    lCompare1 : genericCompare
        generic map (N => 16)
        port map(x => last1_cmp, y => trig_cmp, g => open, l => trig1_last_less_than_thresh, e => open);

    trig1_event <= trig1_curr_value_greater_than_thresh and trig1_last_less_than_thresh;
    sw(CH1_TRIG_SW_BIT_INDEX) <= trig1_event;

    gReg2 : genericRegister
        generic map(N => 16)
        port map (clk => clk, resetn => resetn, load => trig2_reg_control, d => an7606data, q => ch2_reg);

    lReg2 : genericRegister
        generic map (N => 16)
        port map (clk => clk, resetn => resetn, load => trig2_reg_control, d => ch2_reg, q=> last_SLV2);

    gCompare2 : genericCompare
        generic map (N => 16)
        port map(x => ch2_cmp, y => trig_cmp, g => trig2_curr_value_greater_than_thresh, l => open, e => open);

    lCompare2 : genericCompare
        generic map (N => 16)
        port map(x => last2_cmp, y => trig_cmp, g => open, l => trig2_last_less_than_thresh, e => open);

    trig2_event <= trig2_curr_value_greater_than_thresh and trig2_last_less_than_thresh;
    sw(CH2_TRIG_SW_BIT_INDEX) <= trig2_event;

    -- BRAM counter stuff
    addressCounter : genericCounter
        generic map (N => BRAM_ADDR_BITS)
        port map (clk => clk, resetn => resetn, c => addr_counter_control, d => (others => '0'), q=> wrAddr);

    addressComparator : genericCompare
        generic map (N => BRAM_ADDR_BITS)
        port map(x => WIDTH(BRAM_ADDR_BITS - 1 downto 0), y => wrAddr, g => open, l => open , e => sw(FULL_SW_BIT_INDEX));

    pixelOffset <= STD_LOGIC_VECTOR(unsigned(pixelHorz) - unsigned(L_EDGE));
    rdAddr <= pixelOffset(BRAM_ADDR_BITS - 1 downto 0);

    BRAM_A : blk_mem_gen_0
      PORT MAP (
        clka => clk,
        ena => '1',
        wea => cw(DATA_STORAGE_CH1_WRITE_CW_BIT_INDEX downto DATA_STORAGE_CH1_WRITE_CW_BIT_INDEX),
        addra => wrAddr,
        dina => an7606data,
        clkb => videoClk,
        enb => '1',
        addrb => rdAddr,
        doutb => ch1dout
      );

    BRAM_B: blk_mem_gen_0
      PORT MAP (
        clka => clk,
        ena => '1',
        wea => cw(DATA_STORAGE_CH2_WRITE_CW_BIT_INDEX downto DATA_STORAGE_CH2_WRITE_CW_BIT_INDEX),
        addra => wrAddr,
        dina => an7606data,
        clkb => videoClk,
        enb => '1',
        addrb => rdAddr,
        doutb => ch2dout
      );

    -- 2s to pixel
    ch1Pixel <= sample_to_row(ch1dout);
    ch2Pixel <= sample_to_row(ch2dout);
    trigVscr <= sample_to_row(STD_LOGIC_VECTOR(triggerVolt16bitSigned));

    ch1Comparator : genericCompare
        generic map (N => VIDEO_WIDTH_IN_BITS)
        port map(x => ch1Pixel, y => pixelVert, g => open, l => open, e => ch1Wave);

    ch2Comparator : genericCompare
        generic map (N => VIDEO_WIDTH_IN_BITS)
        port map(x => ch2Pixel, y => pixelVert, g => open, l => open, e => ch2Wave);

    -- HDMI SCOPE TO HDMI CODE COPIED --
    hdmiOen <= '1';
    vsg: videoSignalGenerator
        PORT MAP (clk => videoClk, resetn => resetn, hs => hsync, vs => vsync,
                    de => vde, pixelHorz => pixelHorz, pixelVert => pixelVert);

    sf: scopeFace
        PORT MAP (clk => videoClk,	resetn => resetn, pixelVert => pixelVert, pixelHorz => pixelHorz,
                 triggerTime => triggerTimePixel, triggerVolt => trigVscr, ch1 => Ch1Wave, ch1enb => '1',
                ch2 => ch2Wave, ch2enb => '1', red => red, green => green, blue => blue);

    hdmiReset <= not resetn;

    hdmi_inst: hdmi_tx_0
        PORT MAP (
            pix_clk => videoClk, pix_clkx5 => videoClk5x, rst => hdmiReset, hsync => hsync, vsync => vsync, vde => vde,
            pix_clk_locked => clkLocked, red => red, green => green, blue => blue, TMDS_DATA_P => tmdsDataP, TMDS_DATA_N => tmdsDataN,
            TMDS_CLK_P => tmdsClkP, TMDS_CLK_N => tmdsClkN, aux0_din => "0000", aux1_din => "0000", aux2_din => "0000", ade => '0');

    vc: clk_wiz_0
        PORT MAP (
            clk_in1 => clk,
            clk_out1 => videoClk,
            resetn => resetn,
            clk_out2 => videoClk5x,
            locked => clkLocked);

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

end behavior;
