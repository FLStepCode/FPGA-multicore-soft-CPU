vlib work
vlog ../tb/tb.sv +incdir+../

vsim work.tb

add wave tb/clk
add wave tb/rst_n
add wave -unsigned tb/peek*

run -all

wave zoom full