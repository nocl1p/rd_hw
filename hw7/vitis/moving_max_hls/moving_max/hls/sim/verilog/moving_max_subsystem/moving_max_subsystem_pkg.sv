//==============================================================
//Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2026.1 (64-bit)
//Tool Version Limit: 2026.06
//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//
//==============================================================
`timescale 1ns/1ps 

`ifndef MOVING_MAX_SUBSYSTEM_PKG__SV          
    `define MOVING_MAX_SUBSYSTEM_PKG__SV      
                                                     
    package moving_max_subsystem_pkg;               
                                                     
        import uvm_pkg::*;                           
        import file_agent_pkg::*;                    
                                                     
        `include "uvm_macros.svh"                  
                                                     
        `include "moving_max_config.sv"           
        `include "moving_max_reference_model.sv"  
        `include "moving_max_scoreboard.sv"       
        `include "moving_max_subsystem_monitor.sv"
        `include "moving_max_virtual_sequencer.sv"
        `include "moving_max_pkg_sequence_lib.sv" 
        `include "moving_max_env.sv"              
                                                     
    endpackage                                       
                                                     
`endif                                               
