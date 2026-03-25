# create_project.tcl — Recreate Vivado project for FPGA Platformer
# Usage: vivado -mode batch -source create_project.tcl

set project_name "fpga_platformer"
set project_dir  "vivado_build"
set part         "xc7a100tcsg324-1"
set top_module   "top_platformer"

# Get script directory for relative paths
set script_dir [file dirname [file normalize [info script]]]

# Create project
create_project $project_name [file join $script_dir $project_dir] -part $part -force

# Add source files
add_files -norecurse [glob [file join $script_dir src *.v]]

# Add constraints
add_files -fileset constrs_1 -norecurse [file join $script_dir constraints nexys4ddr.xdc]

# Set top module
set_property top $top_module [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

puts "========================================"
puts "Project created: $project_dir/$project_name.xpr"
puts "Top module: $top_module"
puts "Part: $part"
puts ""
puts "To open in GUI:"
puts "  vivado $project_dir/$project_name.xpr"
puts ""
puts "Then: Run Synthesis → Run Implementation → Generate Bitstream → Program"
puts "========================================"
