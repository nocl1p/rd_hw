//==============================================================
//Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2026.1 (64-bit)
//Tool Version Limit: 2026.06
//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//
//==============================================================

`ifndef MOVING_MAX_SUBSYSTEM_MONITOR_SV
`define MOVING_MAX_SUBSYSTEM_MONITOR_SV


class moving_max_subsystem_monitor extends uvm_component;

    moving_max_reference_model refm;
    moving_max_scoreboard scbd;

    `uvm_component_utils_begin(moving_max_subsystem_monitor)
    `uvm_component_utils_end


    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(moving_max_reference_model)::get(this, "", "refm", refm))
            `uvm_fatal(this.get_full_name(), "No refm from high level")
        `uvm_info(this.get_full_name(), "get reference model by uvm_config_db", UVM_MEDIUM)
        scbd = moving_max_scoreboard::type_id::create("scbd", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    function new (string name = "", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass
`endif
