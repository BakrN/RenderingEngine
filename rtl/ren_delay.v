`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/05/2022 06:41:19 PM
// Design Name: 
// Module Name: ren_delay
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


module  ren_delay#(
    parameter P_WIDTH     = 8, 
    parameter P_NUM_DELAY = 8
)(
    clk,
    i_en,
    i_data,
    o_data
);
////////////////////////////
// I/O definition
////////////////////////////
    input                clk;
    input                i_en;
    input  [P_WIDTH-1:0] i_data;
    output [P_WIDTH-1:0] o_data;

////////////////////////////
// reg
////////////////////////////
    reg   [P_WIDTH-1:0] r_delay[0:P_NUM_DELAY-1];

////////////////////////////
// assign
////////////////////////////
    // in/out port connection
    assign o_data = r_delay[P_NUM_DELAY-1];

////////////////////////////
// always
////////////////////////////
    always @(posedge clk) begin
        if (i_en) r_delay[0] <= i_data;
    end

    // delay register connection
    integer i;
    always @(posedge clk) begin
        if ( P_NUM_DELAY > 1 ) begin
            for ( i = 1; i < P_NUM_DELAY; i = i + 1) begin
                if (i_en) r_delay[i] <= r_delay[i-1];
            end
        end
    end

endmodule
