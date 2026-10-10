//==============================================================
//Vitis HLS - High-Level Synthesis from C, C++ and OpenCL v2026.1 (64-bit)
//Tool Version Limit: 2026.06
//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
//
//==============================================================
`ifndef MOVING_MAX_ENV__SV                                                                                   
    `define MOVING_MAX_ENV__SV                                                                               
                                                                                                                    
                                                                                                                    
    class moving_max_env extends uvm_env;                                                                          
                                                                                                                    
        moving_max_virtual_sequencer moving_max_virtual_sqr;                                                      
        moving_max_config moving_max_cfg;                                                                         
                                                                                                                    
                                                                                                                    
        moving_max_reference_model   refm;                                                                         
                                                                                                                    
        moving_max_subsystem_monitor subsys_mon;                                                                   
                                                                                                                    
        `uvm_component_utils_begin(moving_max_env)                                                                 
        `uvm_field_object (refm, UVM_DEFAULT | UVM_REFERENCE)                                                       
        `uvm_field_object (moving_max_virtual_sqr, UVM_DEFAULT | UVM_REFERENCE)                                    
        `uvm_field_object (moving_max_cfg        , UVM_DEFAULT)                                                    
        `uvm_component_utils_end                                                                                    
                                                                                                                    
        function new (string name = "moving_max_env", uvm_component parent = null);                              
            super.new(name, parent);                                                                                
        endfunction                                                                                                 
                                                                                                                    
        extern virtual function void build_phase(uvm_phase phase);                                                  
        extern virtual function void connect_phase(uvm_phase phase);                                                
        extern virtual task          run_phase(uvm_phase phase);                                                    
                                                                                                                    
    endclass                                                                                                        
                                                                                                                    
    function void moving_max_env::build_phase(uvm_phase phase);                                                    
        super.build_phase(phase);                                                                                   
        moving_max_cfg = moving_max_config::type_id::create("moving_max_cfg", this);                           
                                                                                                                    



        refm = moving_max_reference_model::type_id::create("refm", this);


        uvm_config_db#(moving_max_reference_model)::set(this, "*", "refm", refm);


        `uvm_info(this.get_full_name(), "set reference model by uvm_config_db", UVM_LOW)


        subsys_mon = moving_max_subsystem_monitor::type_id::create("subsys_mon", this);


        moving_max_virtual_sqr = moving_max_virtual_sequencer::type_id::create("moving_max_virtual_sqr", this);
        `uvm_info(this.get_full_name(), "build_phase done", UVM_LOW)
    endfunction


    function void moving_max_env::connect_phase(uvm_phase phase);
        super.connect_phase(phase);


        refm.moving_max_cfg = moving_max_cfg;
        `uvm_info(this.get_full_name(), "connect phase done", UVM_LOW)
    endfunction


    task moving_max_env::run_phase(uvm_phase phase);
        `uvm_info(this.get_full_name(), "moving_max_env is running", UVM_LOW)
    endtask


`endif
