vlib work
vlog ../tb/tb.sv +incdir+../

vsim work.tb

add wave tb/*
add wave tb/dut/peekId
add wave tb/dut/peekAddress
add wave tb/dut/x_coord
add wave tb/dut/y_coord
add wave tb/dut/canDisplay

log -r /*

run -all

wave zoom full