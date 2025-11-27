source vars.tcl

set fp [open $FILES_RTL_PATH r]
set file_data [read $fp]
close $fp

set FILES_RTL_LIST [split $file_data "\n"]

project_new NoC -overwrite

set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE 5CSXFC6D6F31C6
set_global_assignment -name TOP_LEVEL_ENTITY $TOPLEVEL

foreach rtl $FILES_RTL_LIST {
    set_global_assignment -name SYSTEMVERILOG_FILE ../../../rtl/$rtl
}

load_package flow
execute_flow -compile

project_close
