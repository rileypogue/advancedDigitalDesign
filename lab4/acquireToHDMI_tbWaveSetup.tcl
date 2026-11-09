#################################################################################
#Simulator TCL starts in: C:/Users/Chris/AppData/Roaming/Xilinx/Vivado
# cd C:/Users/Chris/Dropbox/Mycourses/EENG498/VHDL/lab03AcquireToHDMI    -- home
# cd C:/Users/coulston/Dropbox/Mycourses/EENG498/VHDL/lab03AcquireToHDMI -- office
# source acquireToHDMI_tbWaveSetup.tcl
#################################################################################
restart

set UUT   /acquireToHDMI_tb/uut
set DP    $UUT/datapath_inst
set CTRL  $UUT/control_inst

add_wave  -color green $UUT/clk
add_wave  -color green $UUT/resetn

set groupColor YELLOW
set TOP_ID [add_wave_group "topLevelIO"]
add_wave -into $TOP_ID -color $groupColor -radix unsigned $UUT/btn
add_wave -into $TOP_ID -color $groupColor $UUT/triggerCh1
add_wave -into $TOP_ID -color $groupColor $UUT/triggerCh2
add_wave -into $TOP_ID -color $groupColor -radix hex $DP/ch1_reg
add_wave -into $TOP_ID -color $groupColor -radix hex $DP/last_SLV1
add_wave -into $TOP_ID -color $groupColor $DP/trig1_curr_value_greater_than_thresh
add_wave -into $TOP_ID -color $groupColor $DP/trig1_last_less_than_thresh
add_wave -into $TOP_ID -color $groupColor $UUT/conversionPlusReadoutTime
add_wave -into $TOP_ID -color $groupColor $UUT/sampleTimerRollover

add_wave   -color aqua $CTRL/state

set groupColor PURPLE
set COUNT_ID [add_wave_group "Counters"]
# Add sample rate counter
add_wave -into $COUNT_ID -color $groupColor -radix unsigned $DP/short_counts
add_wave -into $COUNT_ID -color $groupColor -radix unsigned $DP/long_counts
add_wave -into $COUNT_ID -color $groupColor -radix unsigned $DP/sample_counts
add_wave -into $COUNT_ID -color $groupColor -radix unsigned $DP/SAMPLE_COMPARISON

set groupColor ORANGE
set AD7606_ID [add_wave_group "AD7606 Interface"]
add_wave -into $AD7606_ID -color $groupColor $UUT/an7606reset
add_wave -into $AD7606_ID -color $groupColor $UUT/an7606convst
add_wave -into $AD7606_ID -color $groupColor $UUT/an7606cs
add_wave -into $AD7606_ID -color $groupColor $UUT/an7606rd
add_wave -into $AD7606_ID -color $groupColor $UUT/an7606busy
add_wave -into $AD7606_ID -color $groupColor -radix hex $UUT/an7606data

set groupColor YELLOW
set BRAM_ID [add_wave_group "BRAM Interface"]
add_wave -into $BRAM_ID -color $groupColor -radix unsigned -name "Ch1 Write Address" $DP/wrAddr
add_wave -into $BRAM_ID -color $groupColor -radix unsigned -name "Read Address" $DP/rdAddr
add_wave -into $BRAM_ID -color $groupColor -name "Ch1 Write Enable" $DP/BRAM_A/wea
add_wave -into $BRAM_ID -color $groupColor -name "Ch2 Write Enable" $DP/BRAM_B/wea
set MEM $DP/BRAM_A/inst/native_mem_module.blk_mem_gen_v8_4_13_inst
for {set i 0} {$i < 4} {incr i} {
    add_wave -into $BRAM_ID -color $groupColor -radix hex -name "Ch1 mem\[$i\]" "$MEM/memory\[$i\]"
}



set groupColor BLUE
set HDMI_ID [add_wave_group "Video Interface"]
add_wave -into $HDMI_ID -color $groupColor -radix unsigned $DP/vsg/h_cnt
add_wave -into $HDMI_ID -color $groupColor -radix unsigned $DP/pixelHorz
add_wave -into $HDMI_ID -color $groupColor $DP/hsync
add_wave -into $HDMI_ID -color $groupColor -radix unsigned $DP/vsg/v_cnt
add_wave -into $HDMI_ID -color $groupColor -radix unsigned $DP/pixelVert
add_wave -into $HDMI_ID -color $groupColor $DP/vsync
add_wave -into $HDMI_ID -color $groupColor $DP/vde
add_wave -into $HDMI_ID -color red   -radix unsigned $DP/red
add_wave -into $HDMI_ID -color green -radix unsigned $DP/green
add_wave -into $HDMI_ID -color blue  -radix unsigned $DP/blue

set groupColor MAROON
set SW_ID [add_wave_group "Status Word"]
foreach item {
    {9 "FORCED MODE"}
    {8 "SINGLE MODE"}
    {7 "STORE INTO BRAM"}
    {6 "SAMPLE DONE"}
    {5 "BRAM FULL"}
    {4 "SHORT COUNTER DONE"}
    {3 "LONG COUNTER DONE"}
    {2 "AN7606 BUSY"}
    {1 "CH1 TRIG"}
    {0 "CH2 TRIG"}
} {
    lassign $item bit label
    add_wave -into $SW_ID -color $groupColor -name $label "$UUT/sw\[$bit\]"
}

set groupColor LIME
set CW_ID [add_wave_group "Control Word"]
foreach item {
    {21 "CLEAR STORE FLAG"}
    {20 "SET STORE FLAG"}
    {19 "TRIG CH2 WRITE"}
    {18 "TRIG CH1 WRITE"}
    {17 "CONVERSION PLUS READOUT"}
    {16 "SAMPLE TIMER ROLLOVER"}
    {15 "DATA STORAGE CH2 WRITE"}
    {14 "DATA STORAGE CH1 WRITE"}
    {13 "CONVST"}
    {12 "RD"}
    {11 "CS"}
    {10 "RESET AD7606"}
} {
    lassign $item bit label
    add_wave -into $CW_ID -color $groupColor -name $label "$UUT/cw\[$bit\]"
}
add_wave -into $CW_ID -color $groupColor -radix bin -name "DATA STORAGE COUNTER" "$UUT/cw\[9:8\]"
add_wave -into $CW_ID -color $groupColor -radix bin -name "SAMPLING COUNTER"     "$UUT/cw\[7:6\]"
add_wave -into $CW_ID -color $groupColor -radix bin -name "SAMPLING RATE SELECT" "$UUT/cw\[5:4\]"
add_wave -into $CW_ID -color $groupColor -radix bin -name "LONG DELAY COUNTER"  "$UUT/cw\[3:2\]"
add_wave -into $CW_ID -color $groupColor -radix bin -name "SHORT DELAY COUNTER" "$UUT/cw\[1:0\]"

set FORCED_CHECK01        500ns
set FORCED_CHECK02      700000ns
set FORCED_CHECK03    1311500ns
set FORCED_CHECK04    1340000ns
set FORCED_CHECK05    2900000ns
set FORCED_CHECK06    7360000ns

set FORCED_T01toT02    699500ns
set FORCED_T02toT03    611500ns
set FORCED_T03toT04     28500ns
set FORCED_T04toT05   1560000ns
set FORCED_T05toT06   4460000ns

set TRIGGER_CHECK01        500ns
set TRIGGER_CHECK02    1311200ns
set TRIGGER_CHECK03    1413820ns
set TRIGGER_CHECK04    7455000ns

set TRIGGER_T01toT02   1310700ns
set TRIGGER_T02toT03    102620ns
set TRIGGER_T03toT04   6041180ns