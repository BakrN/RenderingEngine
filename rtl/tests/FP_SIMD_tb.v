//~ `New testbench
`timescale  1ns / 1ps
//`include "rtl/ren_params.vh"
`include "ren_params.v" 
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
wire rst_n                                 ; 
reg   i_en                                 = 0 ;
reg   [(SIMD_WIDTH*22)- 1:0]  i_in1        = 0 ;
reg [(SIMD_WIDTH*22)-1:0]  i_in2         = 0 ;
reg   [2:0]  i_opcode                      = 0 ;

// FP_SIMD Outputs
wire  [(SIMD_WIDTH*22)-1:0]  o_output      ;
wire  o_valid                              ;
wire  o_busy                               ;

assign rst_n = rst_n; 

initial
begin
    clk = 0 ; 
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
    reg[21:0] a0 ; 
    reg[21:0] b0 ; 
    reg[21:0] a1 ; 
    reg[21:0] b1 ; 
    reg[21:0] a2 ; 
    reg[21:0] b2 ; 
    reg[21:0] a3 ; 
    reg[21:0] b3 ; 
    initial begin 
    a0 = `fpONE; // 
    b0 = `fpHALF; //
    a1 = `fpTWO; // 
    b1 = `fpTWO; // 
    a2 = `fpTWOHALF ;
    b2 = `fpONE ; 
    a3 = `fpTHREE; 
    b3 = `fpONE ;  


    end







    
    // if add 
    `define res_add  {`fpONEHALF, `fpFOUR , `fpTHREEHALF, `fpFOUR}
    `define res_mul   {`fpHALF , `fpFOUR , `fpTWOHALF , `fpTHREE} // 1.0f *1 .0f = 1.0f 
    `define res_sub  {`fpHALF, 22'd0 , `fpONEHALF , `fpTWO} // 1.0f *1 .0f = 1.0f 
    `define res_red  `fpFOUR  // after sub
initial
begin
 i_in1 = {a0 , a1, a2 ,a3 }; 
     i_in2 = {b0 , b1, b2, b3} ; 
    i_opcode = `op_add;
    i_en = 1; 
    #(PERIOD*5); // state should be out 
    `assert(o_output , `res_add) ; 
    i_opcode = `op_mul  ; 
    #(PERIOD*5); 
    `assert(o_output , `res_mul); // error here 
    i_opcode = `op_sub ; 
    #(PERIOD*5); 
    `assert(o_output , `res_sub); 
    i_opcode = `op_reduce_add; 
    #(PERIOD*10); 
    `assert(o_output[4*22-1:3*22] , `res_red); 
    i_en = 0 ; 
    #(5*PERIOD)
    $finish;
end

endmodule