package TestScoooterSoCOOCDTB;

import Clocks :: *;
import Connectable :: *;
import GetPut :: *;

import BlueJ :: *;

import ScoooterSystem :: *;

(* synthesize *)
module mkTestScoooterSoCOOCDTB(Empty);
    let system_clk <- mkAbsoluteClock(0, 2);
    let system_rst <- mkAsyncResetFromCR(2, system_clk);

    JTAG_TDO_Delay#(1) tdo_delay = ?;
    JTAG_Driver_ifc i_oocd_driver   <- mkJTAG_Driver_OOCD(tdo_delay, clocked_by system_clk, reset_by system_rst);
    JTAG_Stim_ifc   i_jtag_stim     <- mkJTAGShim(clocked_by system_clk, reset_by system_rst);

    let tck         = i_jtag_stim.tck_out;
    let trst        = i_jtag_stim.trst_out;
    let tdo_clk     = i_jtag_stim.tdo_clk;
    let tdo_rst     = i_jtag_stim.tdo_rst;

    ScoooterSystem_ifc          i_system        <- mkScoooterSystem(tdo_clk, tdo_rst, system_clk, system_rst, clocked_by tck, reset_by trst);
    JTAG_TDO_NullCrossing_ifc   i_tdo_crossing  <- mkJTAGTDONullCrossing(i_system.tdo, tdo_clk, tdo_rst, clocked_by system_clk, reset_by system_rst);

    mkConnection(toGet(i_oocd_driver.ext_tck),  toPut(i_jtag_stim.ext_tck));
    mkConnection(toGet(i_oocd_driver.ext_tdi),  toPut(i_jtag_stim.ext_tdi));
    mkConnection(toGet(i_oocd_driver.ext_tms),  toPut(i_jtag_stim.ext_tms));
    mkConnection(toGet(i_tdo_crossing.ext_tdo), toPut(i_oocd_driver.ext_tdo));
    mkConnection(toGet(i_jtag_stim.int_tms),    toPut(i_system.tms));
    mkConnection(toGet(i_jtag_stim.int_tdi),    toPut(i_system.tdi));

    Reg#(Bit#(32)) rg_cycle         <- mkReg(0, clocked_by system_clk, reset_by system_rst);
    Reg#(Bit#(8))  rg_last_gpio_o   <- mkReg(0, clocked_by system_clk, reset_by system_rst);
    Reg#(Bool)     rg_boot_seen     <- mkReg(False, clocked_by system_clk, reset_by system_rst);
    Reg#(Bool)     rg_timer_seen    <- mkReg(False, clocked_by system_clk, reset_by system_rst);
    Reg#(Bool)     rg_button_seen   <- mkReg(False, clocked_by system_clk, reset_by system_rst);

    rule r_drive_idle_inputs;
        rg_cycle <= rg_cycle + 1;
        if(rg_cycle >= 22000 && rg_cycle < 22032)
            i_system.gpio_i(8'b0000_0100);
        else
            i_system.gpio_i(0);
        i_system.uart_rx(1);
    endrule

    rule r_report_gpio if(i_system.gpio_o != rg_last_gpio_o);
        $display("GPIO output changed at cycle %0d: %02x (oe %02x)",
            rg_cycle, i_system.gpio_o, i_system.gpio_oe);

        if(!rg_boot_seen && i_system.gpio_o == 1 && i_system.gpio_oe == 3)
            rg_boot_seen <= True;
        else if(rg_boot_seen) begin
            if(i_system.gpio_o[0] != rg_last_gpio_o[0])
                rg_timer_seen <= True;
            if(i_system.gpio_o[1] != rg_last_gpio_o[1])
                rg_button_seen <= True;
        end

        rg_last_gpio_o <= i_system.gpio_o;
    endrule

`ifdef SCOOOTER_FINITE_TEST
    rule r_finish_demo if(rg_cycle == 35000);
        if(rg_boot_seen && rg_timer_seen && rg_button_seen) begin
            $display("SCOoOTER boot/timer/GPIO demo passed");
            $finish(0);
        end
        else begin
            $display("ERROR: demo incomplete: boot %0d, timer %0d, button %0d",
                rg_boot_seen, rg_timer_seen, rg_button_seen);
            $finish(1);
        end
    endrule
`endif
endmodule

endpackage
