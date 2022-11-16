//~ `New testbench
`timescale  1ns / 1ps

module tb_FP_SIMD;

// FP_SIMD Parameters
parameter PERIOD  = 10;
parameter SIMD_WIDTH = 4; 

// FP_SIMD Inputs
reg   clk                                  = 0 ;
reg   rst_n                                = 0 ;
reg   i_en                                 = 0 ;
reg   [(SIMD_WIDTH*22)- 1:0]  i_in1        = 0 ;
reg   [(SIMD_WIDTH*22)-1:0]  i_in2         = 0 ;
reg   [2:0]  i_opcode                      = 0 ;

// FP_SIMD Outputs
wire  [(SIMD_WIDTH*22)-1:0]  o_output      ;
wire  o_valid                              ;
wire  o_busy                               ;


initial
begin
    clk = 0 ; 
    rst_n = 0 ; 
    forever #(PERIOD/2)  clk=~clk;
end

FP_SIMD  u_FP_SIMD (
    .clk                     ( clk                              ),
    .rst_n                   ( rst_n                            ),
    .i_en                    ( i_en                             ),
    .i_in1                   ( i_in1     [(SIMD_WIDTH*22)- 1:0] ),
    .i_in2                   ( i_in2     [(SIMD_WIDTH*22)-1:0]  ),
    .i_opcode                ( i_opcode  [2:0]                  ),

    .o_output                ( o_output  [(SIMD_WIDTH*22)-1:0]  ),
    .o_valid                 ( o_valid                          ),
    .o_busy                  ( o_busy                           )
); 
    reg[21:0] a0 = {1'b0, 5'h0f, 16'h8000}; // = 1.0f 
    reg[21:0] a1 = {1'b0, 5'h10, 16'h8000}; // = 2.0f 
    reg[21:0] a2 = 0 ; 
    reg[21:0] b0 = {1'b0, 5'h0f, 16'h8000}; // = 1.0f
    reg[21:0] b1 = 0; // = 0
    reg[21:0] b2 = 0 ; 
    // if add 
    parameter [21:0] c0_add = {1'b0, 5'h10, 16'h8000}; // 1.0f + 1.0f= 2.0f 
    parameter [21:0] c1_add = {1'b0, 5'h10, 16'h8000}; // 2.0f + 0.0f= 2.0f 
    parameter [21:0] c2_add = 0 ; 
    parameter [21:0] c0_mul = {1'b0, 5'h0f, 16'h8000}; // 1.0f *1 .0f = 1.0f 
    parameter [21:0] c1_mul = 0 ; 
    parameter [21:0] c2_mul = 0 ; 
    //reduce_add after addition
    parameter [21:0] c0_red = {1'b0, 5'h11, 16'h8000}; // 2.0f + 2.0f= 4.0f 
    parameter [21:0] c1_red = 0 ; // dont care
    parameter [21:0] c2_red = 0 ; // dont care 
    
initial
begin
    i_opcode = 0;
    i_in1 = {a0, a1, a2, 22'd0}; 
    i_in2 = {b0, b1, b2, 22'd0}; 
    i_en = 1; 
    #(PERIOD) ; 
    i_en=0 ; 
    #(PERIOD*5); 
    i_opcode = 3'b100; // reduce_add 
    i_en = 1 ; 
    #(PERIOD); 
    i_en = 0 ; 
    #(5*PERIOD)
    $finish;
end

endmodule