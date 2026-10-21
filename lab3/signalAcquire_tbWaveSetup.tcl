#################################################################################
# Simulator starts in: C:/Users/Chris/AppData/Roaming/Xilinx/Vivado
# Add this file as a simulation source in Vivado and it will automatically 
# load when you start a simulation.
#################################################################################
restart
remove_wave [get_waves *]

add_wave  -color green /signalAcquire_tb/uut/clk
add_wave  -color green /signalAcquire_tb/uut/resetn
add_wave  -color yellow /signalAcquire_tb/uut/btn

add_wave   -color aqua /signalAcquire_tb/uut/controlUnit/state
add_wave   -color purple	-radix unsigned /signalAcquire_tb/uut/datapath/shortCounter
add_wave   -color purple	-radix unsigned /signalAcquire_tb/uut/datapath/longCounter
add_wave   -color purple	-radix unsigned /signalAcquire_tb/uut/datapath/rfCounter

add_wave   -color orange -radix hex	/signalAcquire_tb/uut/an7606data
add_wave   -color orange 		/signalAcquire_tb/uut/an7606convst
add_wave   -color orange 		/signalAcquire_tb/uut/an7606cs
add_wave   -color orange 		/signalAcquire_tb/uut/an7606rd
add_wave   -color orange		/signalAcquire_tb/uut/an7606reset
add_wave   -color orange		/signalAcquire_tb/uut/an7606busy
add_wave   -color red -radix hex	/signalAcquire_tb/uut/cw
add_wave   -color maroon -radix hex	/signalAcquire_tb/uut/fsm_sw
add_wave   -color maroon -radix hex -name Trigger	/signalAcquire_tb/uut/convst

add_wave   -color gold -radix hex	/signalAcquire_tb/uut/datapath/regFile/Q0
add_wave   -color gold -radix hex	/signalAcquire_tb/uut/datapath/regFile/Q1
add_wave   -color gold -radix hex	/signalAcquire_tb/uut/datapath/regFile/Q2
add_wave   -color gold -radix hex	/signalAcquire_tb/uut/datapath/regFile/Q3
add_wave   -color gold -radix hex	/signalAcquire_tb/uut/datapath/regFile/Q4
add_wave   -color gold -radix hex	/signalAcquire_tb/uut/datapath/regFile/Q5
add_wave   -color gold -radix hex	/signalAcquire_tb/uut/datapath/regFile/Q6
add_wave   -color gold -radix hex	/signalAcquire_tb/uut/datapath/regFile/Q7


add_wave   -color gold -radix hex	/signalAcquire_tb/uut/rfData
add_wave   -color gold -radix hex	/signalAcquire_tb/uut/PL_LEDS


