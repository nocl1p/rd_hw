//==============================================================
//Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2026.1 (64-bit)
//Tool Version Limit: 2026.06
//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//
//==============================================================

`ifndef SV_MODULE_TOP_SV
`define SV_MODULE_TOP_SV


`timescale 1ns/1ps


`include "uvm_macros.svh"
import uvm_pkg::*;
import file_agent_pkg::*;
import moving_max_subsystem_pkg::*;
`include "moving_max_subsys_test_sequence_lib.sv"
`include "moving_max_test_lib.sv"


module sv_module_top;


    misc_interface              misc_if ( .clock(apatb_moving_max_top.AESL_clock), .reset(apatb_moving_max_top.AESL_reset) );
    assign apatb_moving_max_top.ap_start = misc_if.tb2dut_ap_start;
    assign misc_if.dut2tb_ap_done = apatb_moving_max_top.ap_done;
    assign misc_if.dut2tb_ap_ready = apatb_moving_max_top.ap_ready;
    initial begin
        uvm_config_db #(virtual misc_interface)::set(null, "uvm_test_top.top_env.*", "misc_if", misc_if);
    end


    initial begin
        run_test();
    end
endmodule
`endif
