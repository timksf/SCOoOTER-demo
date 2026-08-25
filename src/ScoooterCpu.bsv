`ifndef SCOOOTER_CPU_CONFIG
`define SCOOOTER_CPU_CONFIG

`define SCOOOTER_CFG_IFU_INST              1
`define SCOOOTER_CFG_ISSUE_WIDTH           1
`define SCOOOTER_CFG_RESET_VECTOR          0
`define SCOOOTER_CFG_BASE_IMEM             'h00000
`define SCOOOTER_CFG_SIZE_IMEM             'h10000
`define SCOOOTER_CFG_BASE_DMEM             'h80000000
`define SCOOOTER_CFG_SIZE_DMEM             'h10000
`define SCOOOTER_CFG_ROB_BANK_DEPTH        2
`define SCOOOTER_CFG_INST_WINDOW           2
`define SCOOOTER_CFG_MUL_DIV_STRATEGY      1
`define SCOOOTER_CFG_NUM_ALU               1
`define SCOOOTER_CFG_NUM_MUL_DIV           0
`define SCOOOTER_CFG_NUM_BRANCH            1
`define SCOOOTER_CFG_RS_DEPTH_ALU          1
`define SCOOOTER_CFG_RS_DEPTH_MEM          1
`define SCOOOTER_CFG_RS_DEPTH_CSR          1
`define SCOOOTER_CFG_RS_DEPTH_MUL_DIV      1
`define SCOOOTER_CFG_RS_DEPTH_BRANCH       1
`define SCOOOTER_CFG_STORE_BUFFER_DEPTH    4
`define SCOOOTER_CFG_BRANCH_PREDICTOR      0
`define SCOOOTER_CFG_BTB_INDEX_BITS        0
`define SCOOOTER_CFG_PHT_INDEX_BITS        4
`define SCOOOTER_CFG_BRANCH_HISTORY_BITS   0

`endif

`ifndef SCOOOTER_CONFIG_ONLY
package ScoooterCpu;

import Vector :: *;

import BlueFabric :: *;
import AhbAdapters :: *;
import Config :: *;
import Dave :: *;
import Interfaces :: *;
import ScoooterMemory :: *;

interface ScoooterCpu_ifc;
    interface AhbMasterFabric_ifc#(32, 32) m_ahb;
    interface DebugHartIFC debug_hart;
    method Action sw_interrupt(Bool value);
    method Action timer_interrupt(Bool value);
    method Action external_interrupt(Bool value);
endinterface

module mkScoooterCpu(ScoooterCpu_ifc);

    DaveIFC i_core <- mkDave;

    MemoryAhbAdapter_ifc i_ahb <- mkMemoryAhbAdapter;
    Empty i_memory <- mkScoooterMemoryArbiter(i_core, i_ahb.memory);

    interface m_ahb         = i_ahb.m_ahb;
    interface debug_hart    = i_core.debug_harts[0][0];

    method Action sw_interrupt(Bool value);
        i_core.sw_int(replicate(replicate(value)));
    endmethod

    method Action timer_interrupt(Bool value);
        i_core.timer_int(replicate(replicate(value)));
    endmethod

    method Action external_interrupt(Bool value);
        i_core.ext_int(replicate(replicate(value)));
    endmethod
endmodule

endpackage
`endif
