//~ `New testbench
`timescale  1ns / 1ps
`include "rtl/ren_params.v"
module tb_FP_SIMD;
`define assert(signal, value) \
        if (signal !== value) begin \
            $display("ASSERTION FAILED in %m: signal != value"); \
            $finish; \
        end
// FP_SIMD Parameters
parameter PERIOD  = 10;
parameter SIMD_WIDTH = 4; 

// FP_SIMD Inputs
reg   clk                                  = 0 ;
reg   rst_n                                = 0 ;
reg   i_en                                 = 0 ;
wire   [(SIMD_WIDTH*22)- 1:0]  i_in1        = 0 ;
wire [(SIMD_WIDTH*22)-1:0]  i_in2         = 0 ;
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

    assign i_in1 = {a0 , a1, a2 ,a3 }; 
    assign i_in2 = {b0 , b1, b2, b3} ; 
    reg[21:0] a0 = `fpONE; // = 1.0f 
    reg[21:0] b0 = `fpHALF; // = 1.0f
    reg[21:0] a1 = `fpTWO; // = 2.0f 
    reg[21:0] b1 = `fpTWO; // = 0
    reg[21:0] a2 = `fpTWOHALF ; 
    reg[21:0] b2 = `fpONE ; 
    reg[21:0] a3 = `fpTHREE; 
    reg[21:0] b3 = `fpONE ;  
    // if add 
    reg [87:0] red_add = {`fpONEHALF, `fpFOUR , `fpTHREEHALF, `fpFOUR}; 
    parameter [87:0] res_mul = {`fpHALF , `fpFOUR , `fpTWOHALF , `fpTHREE}; // 1.0f *1 .0f = 1.0f 
    parameter [87:0] res_sub = {`fpHALF, 22'd0 , `fpONEHALF , `fpTWO}; // 1.0f *1 .0f = 1.0f 
    parameter [87:0] res_red = {`fpFOUR , 66'd0} ; // after sub
initial
begin
    i_opcode = `op_add;
    i_en = 1; 
    #(PERIOD*4); // state should be out 
    `assert(o_output , {res_ad}) ; 
df
    #(PERIOD*4); 

    `assert(o_output, res_add) ; 
    i_opcode = `op_sub; // reduce_add 
    
    i_en = 0 ; 
    #(5*PERIOD)
    $finish;
end

endmodule