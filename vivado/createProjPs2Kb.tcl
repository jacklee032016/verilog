# vivodo test project for PS2 Keyboard and UART TX
# UART TX: 19200:8
# PS2: 0~9; A~Z, some special chars

# Run this script to create the Vivado project files in the WORKING DIRECTORY
# If ::create_path global variable is set, the project is created under that path instead of the working dir

if {[info exists ::create_path]} {
	set DIR_DEST $::create_path
} else {
	set DIR_DEST [pwd]/../../works/ps2kb
}

puts "INFO: Creating new project in $DIR_DEST"

# Set the reference directory for source file relative paths (by default the value is script directory path)
set PROJ_NAME "Ps2Kb"

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir ".."

# Set the directory path for the original project from where this script was exported
set orig_proj_dir "[file normalize "$origin_dir/proj"]"

set DIR_SRC [pwd]/../
set repo_dir $origin_dir/repo

# Set the board part number
set part_num "xc7a200tsbg484-1"

# Create project
create_project $PROJ_NAME $DIR_DEST

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects $PROJ_NAME]
set_property "default_lib" "xil_defaultlib" $obj
set_property "part" "$part_num" $obj
set_property "simulator_language" "Mixed" $obj
set_property "target_language" "VHDL" $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize $repo_dir]" $obj

# Add conventional sources
add_files -quiet $DIR_SRC/uart/uart.v
add_files -quiet $DIR_SRC/uart/uart_tx.v
add_files -quiet $DIR_SRC/uart/uart_rx.v
add_files -quiet $DIR_SRC/uart/fifo.v
add_files -quiet $DIR_SRC/uart/baudrate_gen.v

add_files -quiet $DIR_SRC/ps2/ps2_rx.sv
add_files -quiet $DIR_SRC/ps2/ps2_key.sv
add_files -quiet $DIR_SRC/ps2/key2ascii.sv
# top level test module
add_files -quiet $DIR_SRC/ps2/ps2_key_test.sv

# Add IPs
#add_files -quiet [glob -nocomplain ../src/ip/*/*.xci]
#add_files -quiet [glob -nocomplain ../src/ip/*/*.xco]

# Add constraints
add_files -fileset constrs_1 -quiet $DIR_SRC/constraints

# Refresh IP Repositories
#update_ip_catalog

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 -part $part_num -flow {Vivado Synthesis 2014} -strategy "Flow_PerfOptimized_High" -constrset constrs_1
} else {
  set_property strategy "Flow_PerfOptimized_High" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2014" [get_runs synth_1]
}
set obj [get_runs synth_1]
set_property "part" "$part_num" $obj
set_property "steps.synth_design.args.fanout_limit" "400" $obj
set_property "steps.synth_design.args.fsm_extraction" "one_hot" $obj
set_property "steps.synth_design.args.keep_equivalent_registers" "1" $obj
set_property "steps.synth_design.args.resource_sharing" "off" $obj
set_property "steps.synth_design.args.no_lc" "1" $obj
set_property "steps.synth_design.args.shreg_min_size" "5" $obj

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 -part $part_num -flow {Vivado Implementation 2014} -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2014" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property "part" "$part_num" $obj
set_property "steps.write_bitstream.args.bin_file" "1" $obj

# set the current impl run
current_run -implementation [get_runs impl_1]

puts "INFO: Project created:$PROJ_NAME"

# Comment the following section, if there is no block design
# Create block design
#source $origin_dir/src/bd/bt_gpio.tcl

# Generate the wrapper
#set design_name [get_bd_designs]
#make_wrapper -files [get_files $design_name.bd] -top -import

#set obj [get_filesets sources_1]
#set_property "top" "bt_gpio_top" $obj

#puts "INFO: Block design created: $design_name.bd"
