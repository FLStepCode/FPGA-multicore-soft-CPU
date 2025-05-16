project_new de1soc_onboard -overwrite

set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE 5CSEMA5F31C6
set_global_assignment -name TOP_LEVEL_ENTITY de1soc_onboard
set_global_assignment -name SYSTEMVERILOG_FILE de1soc_onboard.sv
set_global_assignment -name SEARCH_PATH "../../"
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files

#============================================================
# CLOCK
#============================================================
set_location_assignment PIN_AF14 -to CLOCK_50

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK_50

#============================================================
# SEG7
#============================================================
set_location_assignment PIN_AE26 -to HEX0_N[0]
set_location_assignment PIN_AE26 -to HEX0_N_0
set_location_assignment PIN_AE27 -to HEX0_N[1]
set_location_assignment PIN_AE27 -to HEX0_N_1
set_location_assignment PIN_AE28 -to HEX0_N[2]
set_location_assignment PIN_AE28 -to HEX0_N_2
set_location_assignment PIN_AG27 -to HEX0_N[3]
set_location_assignment PIN_AG27 -to HEX0_N_3
set_location_assignment PIN_AF28 -to HEX0_N[4]
set_location_assignment PIN_AF28 -to HEX0_N_4
set_location_assignment PIN_AG28 -to HEX0_N[5]
set_location_assignment PIN_AG28 -to HEX0_N_5
set_location_assignment PIN_AH28 -to HEX0_N[6]
set_location_assignment PIN_AH28 -to HEX0_N_6
set_location_assignment PIN_AJ29 -to HEX1_N[0]
set_location_assignment PIN_AJ29 -to HEX1_N_0
set_location_assignment PIN_AH29 -to HEX1_N[1]
set_location_assignment PIN_AH29 -to HEX1_N_1
set_location_assignment PIN_AH30 -to HEX1_N[2]
set_location_assignment PIN_AH30 -to HEX1_N_2
set_location_assignment PIN_AG30 -to HEX1_N[3]
set_location_assignment PIN_AG30 -to HEX1_N_3
set_location_assignment PIN_AF29 -to HEX1_N[4]
set_location_assignment PIN_AF29 -to HEX1_N_4
set_location_assignment PIN_AF30 -to HEX1_N[5]
set_location_assignment PIN_AF30 -to HEX1_N_5
set_location_assignment PIN_AD27 -to HEX1_N[6]
set_location_assignment PIN_AD27 -to HEX1_N_6
set_location_assignment PIN_AB23 -to HEX2_N[0]
set_location_assignment PIN_AB23 -to HEX2_N_0
set_location_assignment PIN_AE29 -to HEX2_N[1]
set_location_assignment PIN_AE29 -to HEX2_N_1
set_location_assignment PIN_AD29 -to HEX2_N[2]
set_location_assignment PIN_AD29 -to HEX2_N_2
set_location_assignment PIN_AC28 -to HEX2_N[3]
set_location_assignment PIN_AC28 -to HEX2_N_3
set_location_assignment PIN_AD30 -to HEX2_N[4]
set_location_assignment PIN_AD30 -to HEX2_N_4
set_location_assignment PIN_AC29 -to HEX2_N[5]
set_location_assignment PIN_AC29 -to HEX2_N_5
set_location_assignment PIN_AC30 -to HEX2_N[6]
set_location_assignment PIN_AC30 -to HEX2_N_6
set_location_assignment PIN_AD26 -to HEX3_N[0]
set_location_assignment PIN_AD26 -to HEX3_N_0
set_location_assignment PIN_AC27 -to HEX3_N[1]
set_location_assignment PIN_AC27 -to HEX3_N_1
set_location_assignment PIN_AD25 -to HEX3_N[2]
set_location_assignment PIN_AD25 -to HEX3_N_2
set_location_assignment PIN_AC25 -to HEX3_N[3]
set_location_assignment PIN_AC25 -to HEX3_N_3
set_location_assignment PIN_AB28 -to HEX3_N[4]
set_location_assignment PIN_AB28 -to HEX3_N_4
set_location_assignment PIN_AB25 -to HEX3_N[5]
set_location_assignment PIN_AB25 -to HEX3_N_5
set_location_assignment PIN_AB22 -to HEX3_N[6]
set_location_assignment PIN_AB22 -to HEX3_N_6
set_location_assignment PIN_AA24 -to HEX4_N[0]
set_location_assignment PIN_AA24 -to HEX4_N_0
set_location_assignment PIN_Y23  -to HEX4_N[1]
set_location_assignment PIN_Y23  -to HEX4_N_1
set_location_assignment PIN_Y24  -to HEX4_N[2]
set_location_assignment PIN_Y24  -to HEX4_N_2
set_location_assignment PIN_W22  -to HEX4_N[3]
set_location_assignment PIN_W22  -to HEX4_N_3
set_location_assignment PIN_W24  -to HEX4_N[4]
set_location_assignment PIN_W24  -to HEX4_N_4
set_location_assignment PIN_V23  -to HEX4_N[5]
set_location_assignment PIN_V23  -to HEX4_N_5
set_location_assignment PIN_W25  -to HEX4_N[6]
set_location_assignment PIN_W25  -to HEX4_N_6
set_location_assignment PIN_V25  -to HEX5_N[0]
set_location_assignment PIN_V25  -to HEX5_N_0
set_location_assignment PIN_AA28 -to HEX5_N[1]
set_location_assignment PIN_AA28 -to HEX5_N_1
set_location_assignment PIN_Y27  -to HEX5_N[2]
set_location_assignment PIN_Y27  -to HEX5_N_2
set_location_assignment PIN_AB27 -to HEX5_N[3]
set_location_assignment PIN_AB27 -to HEX5_N_3
set_location_assignment PIN_AB26 -to HEX5_N[4]
set_location_assignment PIN_AB26 -to HEX5_N_4
set_location_assignment PIN_AA26 -to HEX5_N[5]
set_location_assignment PIN_AA26 -to HEX5_N_5
set_location_assignment PIN_AA25 -to HEX5_N[6]
set_location_assignment PIN_AA25 -to HEX5_N_6

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N_0
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N_1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N_2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N_3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N_4
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N_5
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0_N_6
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N_0
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N_1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N_2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N_3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N_4
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N_5
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1_N_6
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N_0
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N_1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N_2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N_3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N_4
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N_5
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2_N_6
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N_0
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N_1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N_2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N_3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N_4
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N_5
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3_N_6
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N_0
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N_1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N_2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N_3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N_4
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N_5
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX4_N_6
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N_0
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N_1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N_2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N_3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N_4
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N_5
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX5_N_6

#============================================================
# KEY_N
#============================================================
set_location_assignment PIN_AA14 -to KEY_N[0]
set_location_assignment PIN_AA14 -to KEY_N_0
set_location_assignment PIN_AA15 -to KEY_N[1]
set_location_assignment PIN_AA15 -to KEY_N_1
set_location_assignment PIN_W15  -to KEY_N[2]
set_location_assignment PIN_W15  -to KEY_N_2
set_location_assignment PIN_Y16  -to KEY_N[3]
set_location_assignment PIN_Y16  -to KEY_N_3

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY_N[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY_N_0
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY_N[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY_N_1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY_N[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY_N_2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY_N[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY_N_3

#============================================================
# SW
#============================================================
set_location_assignment PIN_AB12 -to SW[0]
set_location_assignment PIN_AB12 -to SW_0
set_location_assignment PIN_AC12 -to SW[1]
set_location_assignment PIN_AC12 -to SW_1
set_location_assignment PIN_AF9  -to SW[2]
set_location_assignment PIN_AF9  -to SW_2
set_location_assignment PIN_AF10 -to SW[3]
set_location_assignment PIN_AF10 -to SW_3
set_location_assignment PIN_AD11 -to SW[4]
set_location_assignment PIN_AD11 -to SW_4
set_location_assignment PIN_AD12 -to SW[5]
set_location_assignment PIN_AD12 -to SW_5
set_location_assignment PIN_AE11 -to SW[6]
set_location_assignment PIN_AE11 -to SW_6
set_location_assignment PIN_AC9  -to SW[7]
set_location_assignment PIN_AC9  -to SW_7
set_location_assignment PIN_AD10 -to SW[8]
set_location_assignment PIN_AD10 -to SW_8
set_location_assignment PIN_AE12 -to SW[9]
set_location_assignment PIN_AE12 -to SW_9

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_0
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_1
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_2
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_3
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_4
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_5
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_6
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_7
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[8]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_8
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[9]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW_9


load_package flow
execute_flow -compile

project_close