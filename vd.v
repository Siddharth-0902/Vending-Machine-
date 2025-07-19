`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.04.2025 17:48:04
// Design Name: 
// Module Name: vd
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module vd(
    input clk,
    input reset,
    input [1:0] coin,     // 01 - ₹1, 10 - ₹2, 11 - ₹5
    input [1:0] select,   // 00 - Coke, 01 - Pepsi, 10 - Sprite
    input confirm,        // Confirm selection (like button press)
    output reg dispense,
    output reg [3:0] change
);

    reg [3:0] total;      // To hold total inserted amount
    reg [3:0] price;
    reg [2:0] state;

    parameter IDLE = 3'd0, COLLECT = 3'd1, DISPENSE = 3'd2, RETURN_CHANGE = 3'd3, RESET = 3'd4;

    // Map drink selection to price
    always @(*) begin
        case (select)
            2'b00: price = 4'd5;  // Coke
            2'b01: price = 4'd7;  // Pepsi
            2'b10: price = 4'd10; // Sprite
            default: price = 4'd0;
        endcase
    end

    // FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            total <= 0;
            dispense <= 0;
            change <= 0;
        end else begin
            case (state)
                IDLE: begin
                    dispense <= 0;
                    change <= 0;
                    total <= 0;
                    if (confirm) begin
                        state <= COLLECT;
                    end
                end

                COLLECT: begin
                    // Add value based on coin input
                    case (coin)
                        2'b01: total <= total + 1;
                        2'b10: total <= total + 2;
                        2'b11: total <= total + 5;
                        default: total <= total;
                    endcase

                    if (total >= price) begin
                        state <= DISPENSE;
                    end
                end

                DISPENSE: begin
                    dispense <= 1;
                    state <= RETURN_CHANGE;
                end

                RETURN_CHANGE: begin
                    if (total > price) begin
                        change <= total - price;
                    end else begin
                        change <= 0;
                    end
                    state <= RESET;
                end

                RESET: begin
                    total <= 0;
                    dispense <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

/*module vd(
    input clk,
    input rst,
    input [2:0] coin,           // 001=₹1, 010=₹2, 101=₹5
    input [1:0] select,         // 00=Coke(₹5), 01=Pepsi(₹7), 10=Sprite(₹10)
    input sel_valid,           // High when selection is made
    output reg dispense,
    output reg [3:0] change,
    output reg insufficient
);

    // State encoding
    parameter IDLE          = 3'b000,
              COIN_ACCEPT   = 3'b001,
              SELECTION     = 3'b010,
              DISPENSE      = 3'b011,
              RETURN_CHANGE = 3'b100;

    reg [2:0] state, next_state;
    reg [4:0] balance;
    reg [4:0] price;

    // Coin decoder logic
    wire [4:0] coin_val;
    assign coin_val = (coin == 3'b001) ? 5'd1 :
                      (coin == 3'b010) ? 5'd2 :
                      (coin == 3'b101) ? 5'd5 : 5'd0;

    // Sequential state transition
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            balance <= 0;
            dispense <= 0;
            change <= 0;
            insufficient <= 0;
        end else begin
            state <= next_state;
        end
    end

    // Combinational next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:
                if (coin_val > 0) next_state = COIN_ACCEPT;

            COIN_ACCEPT:
                if (sel_valid) next_state = SELECTION;
                else next_state = COIN_ACCEPT;

            SELECTION:
                if (balance >= price) next_state = DISPENSE;
                else next_state = IDLE;

            DISPENSE:
                if (balance > price) next_state = RETURN_CHANGE;
                else next_state = IDLE;

            RETURN_CHANGE:
                next_state = IDLE;

            default: next_state = IDLE;
        endcase
    end

    // FSM output logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            balance <= 0;
            dispense <= 0;
            change <= 0;
            insufficient <= 0;
        end else begin
            dispense <= 0;
            change <= 0;
            insufficient <= 0;

            case (state)
                IDLE: begin
                    balance <= 0;
                end

                COIN_ACCEPT: begin
                    if (coin_val > 0)
                        balance <= balance + coin_val;
                end

                SELECTION: begin
                    case (select)
                        2'b00: price <= 5;    // Coke
                        2'b01: price <= 7;    // Pepsi
                        2'b10: price <= 10;   // Sprite
                        default: price <= 0;
                    endcase

                    if (balance < price)
                        insufficient <= 1;
                end

                DISPENSE: begin
                    dispense <= 1;
                    balance <= balance - price;
                end

                RETURN_CHANGE: begin
                    change <= balance;  // Remaining balance after price is already deducted
                    balance <= 0;
                end
            endcase
        end
    end

endmodule*/
/*module VendingMachine(
  input  start,cancel,selectSoda,confirm,clk,
  input [2:0] coins,
  output [2:0]outFirst,
  output outSecond);
  
  parameter[2:0] idle=0, countCoins=1, sodaSelect=2, dispense=3, giveChange=4;
  reg [2:0] currentState;
  
  always@ (posedge clk)
    if (!start) currentState= idle ; 
  else begin 
    case (currentState)
      idle 	   : currentState = (cancel) ? idle :((coins) ? countCoins : giveChange) ;
      countCoins : currentState = (cancel) ? idle :((coins >= 3'b010) ? sodaSelect : giveChange) ;
      sodaSelect : currentState = (cancel) ? idle :((selectSoda) ? dispense : sodaSelect) ;
      dispense   : currentState = (cancel) ? idle :((confirm) ? giveChange : dispense) ;
      default    : currentState = idle ;
    endcase
  end
  assign outFirst = (start) ? (cancel == 1'b1 | selectSoda ==1'b0 | coins < 3'b010) ? coins : (coins - 3'b010): 3'bxxx ;
  assign outSecond = ((confirm ==1'b1 && currentState == dispense) ? 1'b1 : 1'b0) ;
endmodule*/
/*module vd (
    input clk,
    input reset,
    input [2:0] coin_in,      // 001=₹1, 010=₹2, 100=₹5
    input [1:0] select,       // 00=A, 01=B, 10=C
    input confirm,            // Confirm drink selection
    output reg dispense,
    output reg [3:0] change,
    output reg error
);

    parameter IDLE = 0, WAIT_SELECTION = 1, CHECK_AMOUNT = 2, DISPENSE = 3, INSUFFICIENT = 4;

    reg [2:0] state, next_state;
    reg [3:0] balance;

    // Drink prices
    parameter PRICE_A = 5;
    parameter PRICE_B = 7;
    parameter PRICE_C = 10;

    // Coin values
    wire [3:0] coin_value = (coin_in == 3'b001) ? 1 :
                            (coin_in == 3'b010) ? 2 :
                            (coin_in == 3'b100) ? 5 : 0;

    // Price selected
    reg [3:0] price;

    // FSM state register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            balance <= 0;
        end else begin
            state <= next_state;
            if (coin_value > 0)
                balance <= balance + coin_value;
        end
    end

    // FSM next state and output logic
    always @(*) begin
        // Default assignments
        next_state = state;
        dispense = 0;
        change = 0;
        error = 0;
        price = 0;

        case (state)
            IDLE: begin
                if (coin_value > 0)
                    next_state = WAIT_SELECTION;
            end

            WAIT_SELECTION: begin
                if (confirm) begin
                    case (select)
                        2'b00: price = PRICE_A;
                        2'b01: price = PRICE_B;
                        2'b10: price = PRICE_C;
                        default: price = 0;
                    endcase
                    if (balance >= price)
                        next_state = DISPENSE;
                    else
                        next_state = INSUFFICIENT;
                end
            end

            DISPENSE: begin
                dispense = 1;
                case (select)
                    2'b00: price = PRICE_A;
                    2'b01: price = PRICE_B;
                    2'b10: price = PRICE_C;
                    default: price = 0;
                endcase
                change = balance - price;
                next_state = IDLE;
            end

            INSUFFICIENT: begin
                error = 1;
                next_state = WAIT_SELECTION;
            end

            default: next_state = IDLE;
        endcase
    end

endmodule*/
