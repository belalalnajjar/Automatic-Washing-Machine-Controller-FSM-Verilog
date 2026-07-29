`timescale 1ns / 1ps

module tb_washing_machine_fsm;

    // Inputs
    reg clk;
    reg reset;
    reg start;
    reg cancel;
    reg lid_closed;
    reg water_full;
    reg t_wash_done;
    reg t_drain_done;
    reg t_rinse_done;
    reg t_spin_done;

    // Outputs
    wire fill_valve;
    wire motor_wash;
    wire motor_spin;
    wire pump_drain;
    wire lid_lock;
    wire led_running;
    wire led_done;
    wire led_error;

    // DUT
    washing_machine_fsm dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .cancel(cancel),
        .lid_closed(lid_closed),
        .water_full(water_full),
        .t_wash_done(t_wash_done),
        .t_drain_done(t_drain_done),
        .t_rinse_done(t_rinse_done),
        .t_spin_done(t_spin_done),
        .fill_valve(fill_valve),
        .motor_wash(motor_wash),
        .motor_spin(motor_spin),
        .pump_drain(pump_drain),
        .lid_lock(lid_lock),
        .led_running(led_running),
        .led_done(led_done),
        .led_error(led_error)
    );

    // Clock generats per 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task, clear all timer + sensor signals
    task clear_signals;
    begin
        start       = 0;
        cancel      = 0;
        water_full  = 0;
        t_wash_done = 0;
        t_drain_done= 0;
        t_rinse_done= 0;
        t_spin_done = 0;
    end
    endtask

    initial begin
        lid_closed = 1;
        clear_signals();

        reset = 1;
        #20;
        reset = 0;

        // test 1 - Normal complete wash cycle
        $display("=== TEST 1: Normal cycle ===");
        #10;
        start = 1;
        #10;
        start = 0;

        // After time, water gets full
        #50;
        water_full = 1;
        #10;
        water_full = 0;

        
        #80;
        t_wash_done = 1;
        #10;
        t_wash_done = 0;

        // Drain done
        #60;
        t_drain_done = 1;
        #10;
        t_drain_done = 0;

        // Rinse done
        #60;
        t_rinse_done = 1;
        #10;
        t_rinse_done = 0;

        // Spin done
        #80;
        t_spin_done = 1;
        #10;
        t_spin_done = 0;
        #50;

        // test 2 - Lid opens during spin
        $display("=== TEST 2: Lid open during spin ===");
        clear_signals();
        lid_closed = 1;

        // Start another cycle quickly
        start = 1;
        #10; start = 0;

        // Straight to spin
        #40; water_full = 1; #10; water_full = 0;
        #40; t_wash_done = 1; #10; t_wash_done = 0;
        #40; t_drain_done = 1; #10; t_drain_done = 0;
        #40; t_rinse_done = 1; #10; t_rinse_done = 0;

        // Now in spin. Open lid.
        #40;
        lid_closed = 0;   // should be PAUSE_SPIN
        #60;
        lid_closed = 1;   // should go back to SPIN

        #60;
        t_spin_done = 1; #10; t_spin_done = 0;

        #40;
        
        // test 3 - Cancel during WASH
        $display("=== TEST 3: Cancel during wash ===");
        clear_signals();
        lid_closed = 1;

        start = 1; #10; start = 0;

        #40; water_full = 1; #10; water_full = 0;
// Now cancel in wash
        #40;
        cancel = 1;
        #20;
        cancel = 0;
        #50;
        $display("Simulation finished.");
        $stop;
    end
endmodule
