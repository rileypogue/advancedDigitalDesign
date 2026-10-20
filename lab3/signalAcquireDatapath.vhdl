--------------------------------------------------------------------
-- Name:	Chris Coulston
-- Date:	Feb 3, 2015
-- Modified:	Sept 2022
-- File:	lab2_datapath.vhdl
-- HW:	Lab 2
--	Crs:	ECE 383 and EENG 498
--
-- Purp: The datapath for the audio O'scope
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
use work.basicBuildingBlocks_package.all;
use work.signalAcquire_Package.all; 

entity signalAcquire_Datapath is
    PORT (clk : in  STD_LOGIC;
           resetn : in  STD_LOGIC;
		   cw : in STD_LOGIC_VECTOR(CW_WIDTH -1 downto 0);
		   sw : out STD_LOGIC_VECTOR(DATAPATH_SW_WIDTH - 1 downto 0);
		   an7606data: in STD_LOGIC_VECTOR(15 downto 0);
		   rfAddr: in STD_LOGIC_VECTOR(2 downto 0);
		   rfData: out STD_LOGIC_VECTOR(15 downto 0) );
end signalAcquire_Datapath;

architecture behavior of signalAcquire_Datapath is

    signal short_counter_control : STD_LOGIC_VECTOR(1 downto 0);
    signal long_counter_control : STD_LOGIC_VECTOR(1 downto 0);
    signal rf_counter_control : STD_LOGIC_VECTOR(1 downto 0);
    signal short_counts: STD_LOGIC_VECTOR(SHORT_DELAY_50Mhz_CONST_WIDTH - 1 downto 0);
    signal long_counts : STD_LOGIC_VECTOR(LONG_DELAY_50Mhz_CONST_WIDTH - 1 downto 0);
    signal rf_counts: STD_LOGIC_VECTOR(3 downto 0);
    signal rf_counts_int : STD_uofjmAESI signal rf_control, short_timer_done, long_timer_done, rf_equals7 : STD_LOGIC;
    signal zeros : STD_LOGIC_VEuTOR(LONG_DELAY_50Mhz_CONST_WIDTH - 1 downto 0) := (others => '0');
begin
    -- we need 3 counters, 3 comparators, and reg file
    short_counter_control <= cw(4 downto 3);
    long_counter_control <= cw(6 downto 5);
    rf_counter_control <= cw(2 downto 1);
    
    sw <= rf_equals7 & short_timer_done & long_timer_done; 

    shortCounter : genericCounter
        generic map (N=> SHORT_DELAY_50Mhz_CONST_WIDTH)
        port map (clk => clk, resetn => resetn, c => short_counter_control, d => "00000000", q=> short_counts);


    longCounter : genericCounter
        generic map (N=> LONG_DELAY_50Mhz_CONST_WIDTH)
        port map (clk => clk, resetn => resetn, c => long_counter_control, d => zeros, q=> long_counts);

    rfCounter : genericCounter
        generic map (N=> 4)
        port map (clk => clk, resetn => resetn, c => rf_counter_control, d => "0000", q=> rf_counts);

    shortComparator : genericCompare
        generic map (N => SHORT_DELAY_50Mhz_CONST_WIDTH)
        port map (x => SHORT_DELAY_50Mhz_COUNTS, y => short_counts, g => open, l => open, e => short_timer_done);

    longComparator : genericCompare
        generic map (N => LONG_DELAY_50Mhz_CONST_WIDTH)
        port map (x => LONG_DELAY_50Mhz_COUNTS, y => long_counts, g => open, l => open, e => long_timer_done);

    rfComparator : genericCompare
        generic map (N => 4)
        port map (x => "0111", y => rf_counts, g => open, l => open, e => rf_equals7);

    rf_counts_int <= rf_counts(2 downto 0);

    regFile : generic8RegisterFile 
        generic map (N => 16)
        port map (clk => clk, resetn => resetn, write => rf_control, wrAddr => rf_counts_int, rdAddr => rfAddr, D => an7606data, Q => rfData); 

end behavior;
