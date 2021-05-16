connect_debug_port u_ila_0/probe0 [get_nets [list {dec/FSM_onehot_r_reg[st][2]_3[0]}]]
connect_debug_port u_ila_0/probe1 [get_nets [list {dec/FSM_onehot_r_reg[st][2]_4[0]}]]
connect_debug_port u_ila_0/probe2 [get_nets [list {dec/FSM_onehot_r_reg[st][2]_0[0]}]]
connect_debug_port u_ila_0/probe3 [get_nets [list {dec/FSM_onehot_r_reg[st][2]_2[0]}]]
connect_debug_port u_ila_0/probe4 [get_nets [list {dec/FSM_onehot_r_reg[st][4]_0[0]} {dec/FSM_onehot_r_reg[st][4]_0[1]} {dec/FSM_onehot_r_reg[st][4]_0[2]} {dec/FSM_onehot_r_reg[st][4]_0[3]} {dec/FSM_onehot_r_reg[st][4]_0[4]} {dec/FSM_onehot_r_reg[st][4]_0[5]} {dec/FSM_onehot_r_reg[st][4]_0[6]} {dec/FSM_onehot_r_reg[st][4]_0[7]} {dec/FSM_onehot_r_reg[st][4]_0[8]} {dec/FSM_onehot_r_reg[st][4]_0[9]} {dec/FSM_onehot_r_reg[st][4]_0[10]} {dec/FSM_onehot_r_reg[st][4]_0[11]} {dec/FSM_onehot_r_reg[st][4]_0[12]} {dec/FSM_onehot_r_reg[st][4]_0[13]} {dec/FSM_onehot_r_reg[st][4]_0[14]} {dec/FSM_onehot_r_reg[st][4]_0[15]}]]
connect_debug_port u_ila_0/probe6 [get_nets [list {dec/FSM_onehot_r_reg[st][2]_5[0]}]]


connect_debug_port u_ila_0/probe1 [get_nets [list {dec/r_reg[load_adress]0__0[1]} {dec/r_reg[load_adress]0__0[2]} {dec/r_reg[load_adress]0__0[3]} {dec/r_reg[load_adress]0__0[4]} {dec/r_reg[load_adress]0__0[5]} {dec/r_reg[load_adress]0__0[6]} {dec/r_reg[load_adress]0__0[7]} {dec/r_reg[load_adress]0__0[8]} {dec/r_reg[load_adress]0__0[9]} {dec/r_reg[load_adress]0__0[10]} {dec/r_reg[load_adress]0__0[11]} {dec/r_reg[load_adress]0__0[12]} {dec/r_reg[load_adress]0__0[13]} {dec/r_reg[load_adress]0__0[14]}]]
connect_debug_port u_ila_0/probe3 [get_nets [list {dec/FSM_onehot_r_reg[st][2]_1[0]}]]
connect_debug_port u_ila_0/probe15 [get_nets [list {dec/r_reg[inst][1]_3}]]
connect_debug_port u_ila_0/probe16 [get_nets [list {dec/r_reg[inst][1]_4}]]
connect_debug_port u_ila_0/probe17 [get_nets [list {dec/r_reg[inst][2]_0}]]
connect_debug_port u_ila_0/probe18 [get_nets [list {dec/r_reg[inst][2]_1}]]
connect_debug_port u_ila_0/probe19 [get_nets [list {dec/r_reg[inst][2]_2}]]
connect_debug_port u_ila_0/probe22 [get_nets [list {dec/FSM_onehot_r_reg[st][0]_0}]]




create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_source_IBUF_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 5 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {dec/inst[0]} {dec/inst[1]} {dec/inst[2]} {dec/inst[3]} {dec/inst[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 16 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {dec/r_reg[PC][15][0]} {dec/r_reg[PC][15][1]} {dec/r_reg[PC][15][2]} {dec/r_reg[PC][15][3]} {dec/r_reg[PC][15][4]} {dec/r_reg[PC][15][5]} {dec/r_reg[PC][15][6]} {dec/r_reg[PC][15][7]} {dec/r_reg[PC][15][8]} {dec/r_reg[PC][15][9]} {dec/r_reg[PC][15][10]} {dec/r_reg[PC][15][11]} {dec/r_reg[PC][15][12]} {dec/r_reg[PC][15][13]} {dec/r_reg[PC][15][14]} {dec/r_reg[PC][15][15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 3 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {dec/r_reg[load_adress][8]_0[0]} {dec/r_reg[load_adress][8]_0[1]} {dec/r_reg[load_adress][8]_0[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 16 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {dec/r_reg[PC][15]_0[0]} {dec/r_reg[PC][15]_0[1]} {dec/r_reg[PC][15]_0[2]} {dec/r_reg[PC][15]_0[3]} {dec/r_reg[PC][15]_0[4]} {dec/r_reg[PC][15]_0[5]} {dec/r_reg[PC][15]_0[6]} {dec/r_reg[PC][15]_0[7]} {dec/r_reg[PC][15]_0[8]} {dec/r_reg[PC][15]_0[9]} {dec/r_reg[PC][15]_0[10]} {dec/r_reg[PC][15]_0[11]} {dec/r_reg[PC][15]_0[12]} {dec/r_reg[PC][15]_0[13]} {dec/r_reg[PC][15]_0[14]} {dec/r_reg[PC][15]_0[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 14 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {dec/r_reg[load_adress][15]_0[0]} {dec/r_reg[load_adress][15]_0[1]} {dec/r_reg[load_adress][15]_0[2]} {dec/r_reg[load_adress][15]_0[3]} {dec/r_reg[load_adress][15]_0[4]} {dec/r_reg[load_adress][15]_0[5]} {dec/r_reg[load_adress][15]_0[6]} {dec/r_reg[load_adress][15]_0[7]} {dec/r_reg[load_adress][15]_0[8]} {dec/r_reg[load_adress][15]_0[9]} {dec/r_reg[load_adress][15]_0[10]} {dec/r_reg[load_adress][15]_0[11]} {dec/r_reg[load_adress][15]_0[12]} {dec/r_reg[load_adress][15]_0[13]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {ram/WEA[0]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 13 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {ram/i[addr][0]} {ram/i[addr][1]} {ram/i[addr][2]} {ram/i[addr][3]} {ram/i[addr][4]} {ram/i[addr][5]} {ram/i[addr][6]} {ram/i[addr][7]} {ram/i[addr][8]} {ram/i[addr][9]} {ram/i[addr][10]} {ram/i[addr][11]} {ram/i[addr][12]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 8 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {ram/o[data][0]} {ram/o[data][1]} {ram/o[data][2]} {ram/o[data][3]} {ram/o[data][4]} {ram/o[data][5]} {ram/o[data][6]} {ram/o[data][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 8 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {ram/i[data][0]} {ram/i[data][1]} {ram/i[data][2]} {ram/i[data][3]} {ram/i[data][4]} {ram/i[data][5]} {ram/i[data][6]} {ram/i[data][7]}]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_source_IBUF_BUFG]
