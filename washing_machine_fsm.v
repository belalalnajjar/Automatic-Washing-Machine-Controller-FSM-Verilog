`timescale 1ns / 1ps

module washing_machine_fsm (
    input  wire clk,
    input  wire reset,        
    input  wire start,
    input  wire cancel,
    input  wire lid_closed,
    input  wire water_full,
    input  wire t_wash_done,
    input  wire t_drain_done,
    input  wire t_rinse_done,
    input  wire t_spin_done,

   
    output reg  fill_valve,
    output reg  motor_wash,
    output reg  motor_spin,
    output reg  pump_drain,
    output reg  lid_lock,
    output reg  led_running,
    output reg  led_done,
    output reg  led_error
);
    // Moore FSM
    localparam [3:0]
        S_IDLE       = 4'd0,
        S_CHECK_LID  = 4'd1,
        S_FILL       = 4'd2,
        S_WASH       = 4'd3,
        S_PAUSE_WASH = 4'd4,
        S_DRAIN      = 4'd5,
        S_RINSE      = 4'd6,
        S_SPIN       = 4'd7,
        S_PAUSE_SPIN = 4'd8,
        S_DONE       = 4'd9,
        S_CANCELED   = 4'd10;

    reg [3:0] current_state, next_state;
    
    // State register
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= S_IDLE;
        else
            current_state <= next_state;
    end
    
    // Next-state logic (based on current_state + inputs)
    always @(*) begin
        next_state = current_state;  // default: stay
        case (current_state)
            
            S_IDLE: begin
                if (start && lid_closed)
                    next_state = S_FILL;
                else if (start && !lid_closed)
                    next_state = S_CHECK_LID;
            end

            S_CHECK_LID: begin
                if (lid_closed)
                    next_state = S_FILL;
                // else stay here until lid_closed = 1
            end

            S_FILL: begin
                if (cancel)
                    next_state = S_CANCELED;
                else if (water_full)
                    next_state = S_WASH;
            end

            S_WASH: begin
                if (cancel)
                    next_state = S_CANCELED;
                else if (!lid_closed)
                    next_state = S_PAUSE_WASH;
                else if (t_wash_done)
                    next_state = S_DRAIN;
            end

            S_PAUSE_WASH: begin
                if (cancel)
                    next_state = S_CANCELED;
                else if (lid_closed)
                    next_state = S_WASH;
            end

            S_DRAIN: begin
                if (cancel)
                    next_state = S_CANCELED;
                else if (t_drain_done)
                    next_state = S_RINSE;
            end

            S_RINSE: begin
                if (cancel)
                    next_state = S_CANCELED;
                else if (t_rinse_done)
                    next_state = S_SPIN;
            end

            S_SPIN: begin
                if (cancel)
                    next_state = S_CANCELED;
                else if (!lid_closed)
                    next_state = S_PAUSE_SPIN;
                else if (t_spin_done)
                    next_state = S_DONE;
            end

            S_PAUSE_SPIN: begin
                if (cancel)
                    next_state = S_CANCELED;
                else if (lid_closed)
                    next_state = S_SPIN;
            end

            S_DONE: begin
                // wait for new start for next cycle
                if (start && lid_closed)
                    next_state = S_FILL;
            end

            S_CANCELED: begin
                if (!cancel)
                    next_state = S_IDLE;
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // Output logic, depends just on current state
    always @(*) begin
        fill_valve  = 1'b0;
        motor_wash  = 1'b0;
        motor_spin  = 1'b0;
        pump_drain  = 1'b0;
        lid_lock    = 1'b0;
        led_running = 1'b0;
        led_done    = 1'b0;
        led_error   = 1'b0;

        case (current_state)
            S_IDLE: begin
            end

            S_CHECK_LID: begin
            end

            S_FILL: begin
                fill_valve  = 1'b1;
                lid_lock    = 1'b1;
                led_running = 1'b1;
            end

            S_WASH: begin
                motor_wash  = 1'b1;
                lid_lock    = 1'b1;
                led_running = 1'b1;
            end

            S_PAUSE_WASH: begin
                // motors off, but still running mode
                led_running = 1'b1;
            end

            S_DRAIN: begin
                pump_drain  = 1'b1;
                lid_lock    = 1'b1;
                led_running = 1'b1;
            end

            S_RINSE: begin
                motor_wash  = 1'b1;
                lid_lock    = 1'b1;
                led_running = 1'b1;
            end

            S_SPIN: begin
                motor_spin  = 1'b1;
                lid_lock    = 1'b1;
                led_running = 1'b1;
            end

            S_PAUSE_SPIN: begin
                led_running = 1'b1;
            end

            S_DONE: begin
                led_done = 1'b1;
            end

            S_CANCELED: begin
                led_error = 1'b1;   // indicate cancel happens
            end
        endcase
    end

endmodule

