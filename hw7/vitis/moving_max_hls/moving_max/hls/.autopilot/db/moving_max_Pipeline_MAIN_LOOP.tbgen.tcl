set moduleName moving_max_Pipeline_MAIN_LOOP
set isTopModule 0
set isCombinational 0
set isDatapathOnly 0
set isPipelined 1
set isPipelined_legacy 1
set pipeline_type loop_auto_rewind
set FunctionProtocol ap_ctrl_hs
set restart_counter_num 0
set isOneStateSeq 0
set ProfileFlag 0
set StallSigGenFlag 0
set isEnableWaveformDebug 1
set hasInterrupt 0
set DLRegFirstOffset 0
set DLRegItemOffset 0
set svuvm_can_support 1
set cdfgNum 4
set C_modelName {moving_max_Pipeline_MAIN_LOOP}
set C_modelType { void 0 }
set ap_memory_interface_dict [dict create]
dict set ap_memory_interface_dict in_data { MEM_WIDTH 32 MEM_SIZE 256 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 1 }
dict set ap_memory_interface_dict out_data { MEM_WIDTH 32 MEM_SIZE 256 MASTER_TYPE BRAM_CTRL MEM_ADDRESS_MODE WORD_ADDRESS PACKAGE_IO port READ_LATENCY 0 }
set C_modelArgList {
	{ window_load_6 int 32 regular  }
	{ window_load_5 int 32 regular  }
	{ window_load_4 int 32 regular  }
	{ window_load_3 int 32 regular  }
	{ window_load_2 int 32 regular  }
	{ window_load_1 int 32 regular  }
	{ window_load int 32 regular  }
	{ in_data int 32 regular {array 64 { 1 3 } 1 1 }  }
	{ out_data int 32 regular {array 64 { 0 3 } 0 1 }  }
}
set hasAXIMCache 0
set l_AXIML2Cache [list]
set AXIMCacheInstDict [dict create]
set C_modelArgMapList {[ 
	{ "Name" : "window_load_6", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "window_load_5", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "window_load_4", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "window_load_3", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "window_load_2", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "window_load_1", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "window_load", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "in_data", "interface" : "memory", "bitwidth" : 32, "direction" : "READONLY"} , 
 	{ "Name" : "out_data", "interface" : "memory", "bitwidth" : 32, "direction" : "WRITEONLY"} ]}
# RTL Port declarations: 
set portNum 20
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ window_load_6 sc_in sc_lv 32 signal 0 } 
	{ window_load_5 sc_in sc_lv 32 signal 1 } 
	{ window_load_4 sc_in sc_lv 32 signal 2 } 
	{ window_load_3 sc_in sc_lv 32 signal 3 } 
	{ window_load_2 sc_in sc_lv 32 signal 4 } 
	{ window_load_1 sc_in sc_lv 32 signal 5 } 
	{ window_load sc_in sc_lv 32 signal 6 } 
	{ in_data_address0 sc_out sc_lv 6 signal 7 } 
	{ in_data_ce0 sc_out sc_logic 1 signal 7 } 
	{ in_data_q0 sc_in sc_lv 32 signal 7 } 
	{ out_data_address0 sc_out sc_lv 6 signal 8 } 
	{ out_data_ce0 sc_out sc_logic 1 signal 8 } 
	{ out_data_we0 sc_out sc_logic 1 signal 8 } 
	{ out_data_d0 sc_out sc_lv 32 signal 8 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "window_load_6", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "window_load_6", "role": "default" }} , 
 	{ "name": "window_load_5", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "window_load_5", "role": "default" }} , 
 	{ "name": "window_load_4", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "window_load_4", "role": "default" }} , 
 	{ "name": "window_load_3", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "window_load_3", "role": "default" }} , 
 	{ "name": "window_load_2", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "window_load_2", "role": "default" }} , 
 	{ "name": "window_load_1", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "window_load_1", "role": "default" }} , 
 	{ "name": "window_load", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "window_load", "role": "default" }} , 
 	{ "name": "in_data_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":6, "type": "signal", "bundle":{"name": "in_data", "role": "address0" }} , 
 	{ "name": "in_data_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "in_data", "role": "ce0" }} , 
 	{ "name": "in_data_q0", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "in_data", "role": "q0" }} , 
 	{ "name": "out_data_address0", "direction": "out", "datatype": "sc_lv", "bitwidth":6, "type": "signal", "bundle":{"name": "out_data", "role": "address0" }} , 
 	{ "name": "out_data_ce0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "out_data", "role": "ce0" }} , 
 	{ "name": "out_data_we0", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "out_data", "role": "we0" }} , 
 	{ "name": "out_data_d0", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "out_data", "role": "d0" }}  ]}

set ArgLastReadFirstWriteLatency {
	moving_max_Pipeline_MAIN_LOOP {
		window_load_6 {Type I LastRead 0 FirstWrite -1}
		window_load_5 {Type I LastRead 0 FirstWrite -1}
		window_load_4 {Type I LastRead 0 FirstWrite -1}
		window_load_3 {Type I LastRead 0 FirstWrite -1}
		window_load_2 {Type I LastRead 0 FirstWrite -1}
		window_load_1 {Type I LastRead 0 FirstWrite -1}
		window_load {Type I LastRead 0 FirstWrite -1}
		in_data {Type I LastRead 0 FirstWrite -1}
		out_data {Type O LastRead -1 FirstWrite 4}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "69", "Max" : "69"}
	, {"Name" : "Interval", "Min" : "65", "Max" : "65"}
]}

set PipelineEnableSignalInfo {[
	{"Pipeline" : "0", "EnableSignal" : "ap_enable_pp0"}
]}

set Spec2ImplPortList { 
	window_load_6 { ap_none {  { window_load_6 in_data 0 32 } } }
	window_load_5 { ap_none {  { window_load_5 in_data 0 32 } } }
	window_load_4 { ap_none {  { window_load_4 in_data 0 32 } } }
	window_load_3 { ap_none {  { window_load_3 in_data 0 32 } } }
	window_load_2 { ap_none {  { window_load_2 in_data 0 32 } } }
	window_load_1 { ap_none {  { window_load_1 in_data 0 32 } } }
	window_load { ap_none {  { window_load in_data 0 32 } } }
	in_data { ap_memory {  { in_data_address0 mem_address 1 6 }  { in_data_ce0 mem_ce 1 1 }  { in_data_q0 mem_dout 0 32 } } }
	out_data { ap_memory {  { out_data_address0 mem_address 1 6 }  { out_data_ce0 mem_ce 1 1 }  { out_data_we0 mem_we 1 1 }  { out_data_d0 mem_din 1 32 } } }
}
