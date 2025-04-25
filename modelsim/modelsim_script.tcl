vlib work
vlog ../testbench/tb.sv +incdir+../

vsim work.tb

add wave sim:/tb/HEX*
for {set i 0} {$i < 3} {incr i} {
	add wave -hexadecimal -expand sim:/tb/de10lite/assembler_packets\[$i\]
}

for {set i 0} {$i < 3} {incr i} {
	add wave -hexadecimal sim:/tb/de10lite/toplevel/rows\[$i\]/columns\[$i\]/genblk1/core/splitter/packet_in
	add wave sim:/tb/de10lite/toplevel/rows\[$i\]/columns\[$i\]/genblk1/core/splitter/node_dest_encoded
}


run -all

wave zoom full