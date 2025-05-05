vlib work
vlog ../tb/tb.sv +incdir+../

vsim work.tb

add wave tb/*

run -all

wave zoom full