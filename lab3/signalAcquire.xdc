set_property PACKAGE_PIN U18 [get_ports {clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {clk}]
create_clock -period 20.000 -waveform {0.000 10.000} [get_ports clk]

set_property PACKAGE_PIN N15 [get_ports resetn]
set_property IOSTANDARD LVCMOS33 [get_ports resetn]

set_property PACKAGE_PIN M14 [get_ports reg0Magnitude[0]]
set_property PACKAGE_PIN M15 [get_ports reg0Magnitude[1]]
set_property PACKAGE_PIN M16 [get_ports reg0Magnitude[2]]
set_property PACKAGE_PIN J16 [get_ports reg0Magnitude[3]]
set_property IOSTANDARD LVCMOS33 [get_ports reg0Magnitude[*]]

set_property PACKAGE_PIN R17 [get_ports btn[0]]
set_property IOSTANDARD LVCMOS33 [get_ports btn[0]]

set_property PACKAGE_PIN N16 [get_ports btn[1]]
set_property IOSTANDARD LVCMOS33 [get_ports btn[1]]

set_property PACKAGE_PIN T17 [get_ports btn[2]]
set_property IOSTANDARD LVCMOS33 [get_ports btn[2]]


set_property PACKAGE_PIN R14 [get_ports an7606convst]
set_property PACKAGE_PIN R14   [get_ports an7606convst] 
set_property PACKAGE_PIN W18   [get_ports {an7606od[0]}] 
set_property PACKAGE_PIN W19 [get_ports {an7606od[1]}]   
set_property PACKAGE_PIN P14 [get_ports {an7606od[2]}]    
set_property IOSTANDARD LVCMOS33 [get_ports an7606convst]
set_property IOSTANDARD LVCMOS33 [get_ports {an7606od[*]}]

set_property PACKAGE_PIN U15   [get_ports {an7606data[0]}] 
set_property PACKAGE_PIN U14 [get_ports {an7606data[1]}] 
set_property PACKAGE_PIN P16 [get_ports {an7606data[2]}] 
set_property PACKAGE_PIN P15 [get_ports {an7606data[3]}]  
set_property PACKAGE_PIN U17 [get_ports {an7606data[4]}]  ;# EX_IOx_9N
set_property PACKAGE_PIN T16 [get_ports {an7606data[5]}]  ;# EX_IOx_9P
set_property PACKAGE_PIN V18 [get_ports {an7606data[6]}]  ;# EX_IOx_10N
set_property PACKAGE_PIN W18 [get_ports {an7606data[7]}]  ;# EX_IOx_10P
set_property PACKAGE_PIN T15 [get_ports {an7606data[8]}]  ;# EX_IOx_11N
set_property PACKAGE_PIN T14 [get_ports {an7606data[9]}]  ;# EX_IOx_11P
set_property PACKAGE_PIN V13 [get_ports {an7606data[10]}] ;# EX_IOx_12N
set_property PACKAGE_PIN V13 [get_ports {an7606data[11]}] ;# EX_IOx_12P
set_property PACKAGE_PIN W13 [get_ports {an7606data[12]}] ;# EX_IOx_13N
set_property PACKAGE_PIN T14 [get_ports {an7606data[13]}] ;# EX_IOx_13P
set_property PACKAGE_PIN U12 [get_ports {an7606data[14]}] ;# EX_IOx_14N
set_property PACKAGE_PIN T12   [get_ports {an7606data[15]}] ;# EX_IOx_14P
set_property IOSTANDARD LVCMOS33 [get_ports {an7606data[*]}]
