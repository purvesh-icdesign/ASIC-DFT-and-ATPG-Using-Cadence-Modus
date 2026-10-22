set_db init_lib_search_path /home/install/cadence/FOUNDRY/digital/45nm/LIBS/lib/max/
set_db lef_library /home/install/cadence/FOUNDRY/digital/45nm/LIBS/lef/gsclib045.fixed.lef

set_db library slow.lib

read_hdl {./counter.v}

elaborate

read_sdc ./constraints_top.sdc

#set attribute syn generic effort medium
#set attribute syn map effort medium
#set attribute syn opt effort medium

syn_generic
syn_map
syn_opt

write_hdl > counter_netlist.v

write_sdc > counter_tool.sdc

gui_show

report timing > counter_timing.rpt
report power > counter_power.rpt
report area > counter_cell.rpt
report gates > counter_gates.rpt
