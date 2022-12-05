`timescale 1ns / 1ps
// Made By: Abubakr Nada 
// Extracts triangle coefficients & bounding boxes and other info 
// writes to binner queue
// implementing this edge function(from subscript0 to subscript1): a=y0-y1, b=x1-x0 , c= x0*y1-x1*y0
`include "rtl/ren_params.sv"
//`include "ren_params.sv" // vivado 
module ren_setup(
        clk, 
        // control 
        rstn , 
        i_en, 
        i_busy, // from fifo 
        //triangle data (TODO could add more data in the future)
        i_vtx0_x , 
        i_vtx0_y , 
        i_vtx0_z , 
        i_vtx0_cr, 
        i_vtx0_cg, 
        i_vtx0_cb, 
        i_vtx1_x , 
        i_vtx1_y , 
        i_vtx1_z , 
        i_vtx1_cr, 
        i_vtx1_cg, 
        i_vtx1_cb, 
        i_vtx2_x , 
        i_vtx2_y , 
        i_vtx2_z , 
        i_vtx2_cr, 
        i_vtx2_cg, 
        i_vtx2_cb, 
        //outputs 
        // vertex 
        o_vtx0_x , 
        o_vtx0_y , 
        o_vtx0_z , 
        o_vtx0_cr, 
        o_vtx0_cg, 
        o_vtx0_cb, 
        o_vtx1_x ,
        o_vtx1_y , 
        o_vtx1_z , 
        o_vtx1_cr, 
        o_vtx1_cg, 
        o_vtx1_cb, 
        o_vtx2_x ,
        o_vtx2_y , 
        o_vtx2_z , 
        o_vtx2_cr, 
        o_vtx2_cg, 
        o_vtx2_cb, 
        // triangle info 
        o_e0_a  , 
        o_e0_b  , 
        o_e0_c  , 

        o_e1_a  , 
        o_e1_b  , 
        o_e1_c  , 

        o_e2_a  , 
        o_e2_b  , 
        o_e2_c  , 
        // Tile stepping and min/max steps
        o_min_x , 
        o_min_y , 
        o_steps_x ,
        o_steps_y, 
        // Interpolation coefficients 
        o_cr_coeff , 
        o_cg_coeff , 
        o_cb_coeff , 
        o_z_coeff ,
        // control 
        o_valid , 
        o_idle 
);
    // Functions
    // Ports IO 
    input clk  ; 
    input rstn ; 
    input i_en ; 
    input i_busy; 
    input [21:0] i_vtx0_x ; 
    input [21:0] i_vtx0_y ; 
    input [21:0] i_vtx0_z ; 
    input [21:0] i_vtx0_cr; 
    input [21:0] i_vtx0_cg; 
    input [21:0] i_vtx0_cb; 
    input [21:0] i_vtx1_x ; 
    input [21:0] i_vtx1_y ; 
    input [21:0] i_vtx1_z ; 
    input [21:0] i_vtx1_cr; 
    input [21:0] i_vtx1_cg; 
    input [21:0] i_vtx1_cb; 
    input [21:0] i_vtx2_x ; 
    input [22:0] i_vtx2_y ; 
    input [21:0] i_vtx2_z ; 
    input [21:0] i_vtx2_cr; 
    input [21:0] i_vtx2_cg; 
    input [21:0] i_vtx2_cb; 
    output [21:0] o_vtx0_x ; 
    output [21:0] o_vtx0_y ; 
    output [21:0] o_vtx0_z ; 
    output [21:0] o_vtx0_cr; 
    output [21:0] o_vtx0_cg; 
    output [21:0] o_vtx0_cb; 
    output [21:0] o_vtx1_x ; // mid
    output [21:0] o_vtx1_y ; 
    output [21:0] o_vtx1_z ; 
    output [21:0] o_vtx1_cr; 
    output [21:0] o_vtx1_cg; 
    output [21:0] o_vtx1_cb; 
    output [21:0] o_vtx2_x ; // bottom
    output [21:0] o_vtx2_y ; 
    output [21:0] o_vtx2_z ; 
    output [21:0] o_vtx2_cr; 
    output [21:0] o_vtx2_cg; 
    output [21:0] o_vtx2_cb; 
    output [21:0] o_e0_a ;  
    output [21:0] o_e0_b ;   
    output [21:0] o_e0_c ;   
    output [21:0] o_e1_a ;  
    output [21:0] o_e1_b ;   
    output [21:0] o_e1_c ;   
    output [21:0] o_e2_a ;  
    output [21:0] o_e2_b ;   
    output [21:0] o_e2_c ;   
    output [21:0] o_min_x;   
    output [21:0] o_min_y;   
    output [22*3-1:0] o_cr_coeff ;  
    output [22*3-1:0] o_cg_coeff ;  
    output [22*3-1:0] o_cb_coeff ;  
    output [22*3-1:0] o_z_coeff ;  
    output [15:0] o_steps_x  ;// int
    output [15:0] o_steps_y  ; 
    output o_valid; 
    output o_idle;  
    // Constant
    localparam s_IDLE    = 4'd0 ;  
    localparam s_e_a     = 4'd1 ;  
    localparam s_e_b     = 4'd2 ;  
    localparam s_e_c_0_0 = 4'd3 ;  // multiplication phase 1
    localparam s_e_c_0_1 = 4'd4 ;  // multiplication phase 2
    localparam s_e_c_1   = 4'd5 ;  // reduction (subtraction)
    localparam s_OUT     = 4'd6 ;  
     // attribute interpolation: 
    // For now just (cr cg cb and z )
    localparam s_attribdelta_0 = 4'd7 ; 
    localparam s_attribdelta_1 = 4'd8 ; 
    localparam s_tile_mul      = 4'd9 ; // for calculating the min tile y and steps 
    // Wires
    wire [21:0] w_min_x , w_max_x, w_min_y , w_max_y ;
    wire [21:0] w_intermediatec_0,w_intermediatec_1,w_intermediatec_2 ,w_intermediatec_3;   // used when calculating coeff c
    // SIMD
    wire [4*22-1:0] w_simd_in0; 
    wire [4*22-1:0] w_simd_in1; 
    wire [4*22-1:0] w_simd_out; 
    wire w_simd_enable ;
    wire w_simd_valid; 
    wire w_simd_busy; 
    wire w_simd_rstn; 
    // SIMD END
    wire [21:0] w_e0_c_1 ;
    wire [21:0] w_e0_c_2 ;
    wire [21:0] w_e1_c_1 ;
    wire [21:0] w_e1_c_2 ;
    wire [21:0] w_e2_c_1 ;
    wire [21:0] w_e2_c_2 ;
    // Regs 
    reg [3:0] r_state ;  
    reg [2:0] r_simd_opcode;
    reg [21:0] r_e0_a ;  
    reg [21:0] r_e0_b ;   
    reg [21:0] r_e0_c ;   // will be used for temp storage
    reg [21:0] r_e1_a ;  
    reg [21:0] r_e1_b ;   
    reg [21:0] r_e1_c ;   // will be used for temp storage
    reg [21:0] r_e2_a ;  
    reg [21:0] r_e2_b ;   
    reg [21:0] r_e2_c ; 
    reg [22*2-1:0] r_cr_attrib; 
    reg [22*2-1:0] r_cg_attrib; 
    reg [22*2-1:0] r_cb_attrib; 
    reg [22*2-1:0] r_z_attrib; 
    reg [21:0] r_min_tile_x ; 
    reg [21:0] r_min_tile_y ; 
    reg [15:0] r_steps_x; 
    reg [15:0] r_steps_y; 
    // Assign 
    assign w_intermediatec_0 = r_e0_a; 
    assign w_intermediatec_1 = r_e1_a; 
    assign w_intermediatec_2 = r_e2_a; 
    assign w_intermediatec_3 = r_e0_b; 
    assign o_shader_valid = (r_state == s_OUT); 
    assign o_min_x ={r_min_tile_x[21], (r_min_tile_x[20:16]+$clog2(`TILE_SIZE)) ,r_min_tile_x[15:0]}; // multiplying by tile size
    assign o_min_y = {r_min_tile_y[21], (r_min_tile_y[20:16]+$clog2(`TILE_SIZE)) ,r_min_tile_y[15:0]}; 

    assign w_max_x= (o_e0_b[21]) ? ((!o_e2_b[21]) ? i_vtx0_x : i_vtx1_x) : ((o_e1_b[21]) ? i_vtx2_x : i_vtx1_x) ; // e0b = vtx2-vtx0, e1b = v1-v2 , e2b = v0-v1 ## // checking sign bit 
    assign w_min_x = (o_e0_b[21]) ? ((!o_e1_b[21]) ? i_vtx2_x : i_vtx1_x) : ((o_e2_b[21]) ? i_vtx0_x : i_vtx1_x) ;
    assign o_idle = (r_state==s_IDLE); 

    // checks 
    assign w_min_y=  (o_e0_a[21]) ? ((!o_e2_a[21]) ? i_vtx0_y : i_vtx1_y) : ((o_e1_a[21]) ? i_vtx2_y : i_vtx1_y) ; // e0a = vtx0-vtx2, e1a = v2-v1 , e2a = v1-v0 ## // checking sign bit
    assign w_max_y = (o_e0_a[21]) ? ((!o_e1_a[21]) ? i_vtx2_y : i_vtx1_y) : ((o_e2_a[21]) ? i_vtx0_y : i_vtx1_y); // v2>v0  ? (check if v2 > v1 ? v2 : v1) : 
    // SIMD 
    assign w_simd_rstn = w_simd_enable; 
    assign w_simd_enable = (r_state != 0 && r_state != s_OUT) ? 1 : 0 ; 
    assign w_simd_in0 = (r_state == s_e_a) ? {i_vtx0_y[21:0] , i_vtx2_y[21:0] , i_vtx1_y[21:0], i_vtx0_cr[21:0]} : // adding in vertex coeff calculationf
                        ((r_state == s_e_b)? {i_vtx2_x[21:0] , i_vtx1_x[21:0] , i_vtx0_x[21:0],i_vtx1_cr[21:0]} : 
                        ((r_state == s_e_c_0_0) ? {i_vtx0_x[21:0] , i_vtx2_x[21:0] , w_min_x[21:0] , w_max_x[21:0]} : // mul phase 1 ,calc mintile x and max tiley
                        ((r_state==s_tile_mul)?  {44'd0 ,   w_min_y[21:0] , w_max_y[21:0] }: 
                        ((r_state==s_e_c_0_1) ? {i_vtx2_x[21:0] , i_vtx1_x[21:0] , i_vtx1_x[21:0] ,i_vtx0_x[21:0]} :   // mul phase 2
                        ((r_state==s_e_c_1) ? {r_e0_c [21:0], w_intermediatec_0 [21:0], w_intermediatec_2 [21:0], 22'd0} : // subtraction
                        ((r_state==s_attribdelta_0) ? {i_vtx0_cg [21:0], i_vtx1_cg[21:0] , i_vtx0_cb[21:0] ,i_vtx1_cb[21:0]} : 
                        ((r_state==s_attribdelta_1) ? {i_vtx0_z[21:0] , i_vtx1_z[21:0], 44'd0} : // calculating min tile y and max tile y 
                        0)))))));  

    assign w_simd_in1 = (r_state == s_e_a) ? {i_vtx2_y[21:0] , i_vtx1_y[21:0] , i_vtx0_y[21:0],i_vtx2_cr[21:0]} : 
                        ((r_state == s_e_b)? {i_vtx0_x [21:0], i_vtx2_x [21:0], i_vtx1_x[21:0], i_vtx2_cr[21:0]} : 
                        ((r_state == s_e_c_0_0) ? {i_vtx2_y[21:0] , i_vtx0_y[21:0] , `fpTILE_SIZE_rc , `fpTILE_SIZE_rc }: 
                        ((r_state==s_tile_mul)? {44'd0 ,`fpTILE_SIZE_rc , `fpTILE_SIZE_rc} : 
                        ((r_state==s_e_c_0_1) ? {i_vtx1_y[21:0] , i_vtx2_y[21:0] ,i_vtx0_y[21:0] , i_vtx1_y[21:0]} :
                        
                        ((r_state==s_e_c_1) ? {r_e1_c[21:0] ,w_intermediatec_1[21:0], w_intermediatec_3[21:0]  , 22'd0} : // this needs to chagne
                        ((r_state==s_attribdelta_0) ? {i_vtx2_cg[21:0] , i_vtx2_cg[21:0] , i_vtx2_cb[21:0] ,i_vtx2_cb[21:0]} : 
                        ((r_state==s_attribdelta_1) ? {i_vtx2_z[21:0] , i_vtx2_z[21:0], 44'd0} : 
                        0)))))));    
    // SIMD END
    // Tile 
    
    //output
    assign  o_vtx0_x  =  i_vtx0_x ; 
    assign  o_vtx0_y  =  i_vtx0_y ; 
    assign  o_vtx0_z  =  i_vtx0_z ; 
    assign  o_vtx0_cr =  i_vtx0_cr; 
    assign  o_vtx0_cg =  i_vtx0_cg; 
    assign  o_vtx0_cb =  i_vtx0_cb; 
    assign  o_vtx1_x  =  i_vtx1_x ;
    assign  o_vtx1_y  =  i_vtx1_y  ;
    assign  o_vtx1_z  =  i_vtx1_z  ;
    assign  o_vtx1_cr =  i_vtx1_cr ;
    assign  o_vtx1_cg =  i_vtx1_cg ;
    assign  o_vtx1_cb =  i_vtx1_cb ;
    assign  o_vtx2_x  =  i_vtx2_x  ;
    assign  o_vtx2_y  =  i_vtx2_y ;
    assign  o_vtx2_z  =  i_vtx2_z ;
    assign  o_vtx2_cr =  i_vtx2_cr;
    assign  o_vtx2_cg =  i_vtx2_cg;
    assign  o_vtx2_cb =  i_vtx2_cb;
    assign o_e0_a =  r_e0_a;   
    assign o_e0_b =  r_e0_b;   
    assign o_e0_c =  r_e0_c;   
    assign o_e1_a =  r_e1_a;  
    assign o_e1_b =  r_e1_b;   
    assign o_e1_c =  r_e1_c;   
    assign o_e2_a =  r_e2_a;  
    assign o_e2_b =  r_e2_b;   
    assign o_e2_c =  r_e2_c;  
    assign o_valid = (r_state == s_OUT) ; 
    assign o_cr_coeff = {r_cr_attrib , i_vtx2_cr} ; 
    assign o_cg_coeff = {r_cg_attrib , i_vtx2_cg} ; 
    assign o_cb_coeff = {r_cb_attrib , i_vtx2_cb} ; 
    assign o_z_coeff = {r_z_attrib , i_vtx2_z} ; 
    assign o_steps_x = r_steps_x; 
    assign o_steps_y = r_steps_y; 
    // Always Blocks              
  always @(posedge clk or negedge rstn) begin
    if (!rstn) 
        r_state <= s_IDLE; 
    else begin 
        case (r_state)
            s_IDLE: begin 
                if (i_en ) begin 
                    r_state <= s_e_c_0_0; 
                    r_simd_opcode <= `op_mul ;
                end
            end
            s_e_c_0_0:begin 
                if(w_simd_valid) begin 
                    // move to next state and load coeff register
                    r_e0_c <= w_simd_out[4*22-1:3*22]; 
                    r_e1_c <= w_simd_out[3*22-1:2*22]; 
                    r_min_tile_x <= {1'b0, w_floor_o_1 } ;
                    r_steps_x <= (w_ftoi_o_2 - w_ftoi_o_1) ;  
                    r_state <= s_tile_mul;
                end
            end
            s_tile_mul: begin 
                if(w_simd_valid) begin 
                    r_min_tile_y <= {1'b0, w_floor_o_1 } ;
                    r_steps_y <= (w_ftoi_o_2 - w_ftoi_o_1) ;  
                    r_state <= s_e_c_0_1;
                end
            end
            s_e_c_0_1:begin 
                if(w_simd_valid) begin 
                    // move to next state and load coeff register
                    r_simd_opcode <= 3'b001; // subtraction
                    r_e0_a <= w_simd_out[4*22-1:3*22]; 
                    r_e1_a <= w_simd_out[3*22-1:2*22]; 
                    r_e2_a <= w_simd_out[2*22-1:1*22]; 
                    r_e0_b <= w_simd_out[1*22-1:0*22]; 
                    r_state <= s_e_c_1;
                end 
            end
            s_e_c_1:begin 
                if(w_simd_valid) begin 
                    // move to next state and load coeff register
                    r_e0_c <= w_simd_out[4*22-1:3*22]; 
                    r_e1_c <= w_simd_out[3*22-1:2*22]; 
                    r_e2_c <= w_simd_out[2*22-1:1*22]; 
                    r_state <= s_e_a; 
                    r_simd_opcode <= `op_sub; 
                end
            end
            s_e_a: begin 
                if(w_simd_valid) begin 
                    // move to next state and load coeff register
                    r_e0_a <= w_simd_out[4*22-1:3*22]; 
                    r_e1_a <= w_simd_out[3*22-1:2*22]; 
                    r_e2_a <= w_simd_out[2*22-1:1*22]; 
                    r_cr_attrib[2*22-1:1*22] <= w_simd_out[21:0]; 
                    r_state <= s_e_b;
                end
            end
            s_e_b: begin 
                if(w_simd_valid) begin 
                    // move to next state and load coeff register
                    r_e0_b <= w_simd_out[4*22-1:3*22]; 
                    r_e1_b <= w_simd_out[3*22-1:2*22]; 
                    r_e2_b <= w_simd_out[2*22-1:1*22]; 
                    r_cr_attrib[1*22-1:0*22] <= w_simd_out[21:0]; 
                    r_state <= s_attribdelta_0;
                end
            end
            
            s_attribdelta_0: begin 
                if (w_simd_valid) begin 
                    r_cg_attrib <= w_simd_out[4*22-1:2*22]; 
                    r_cb_attrib <= w_simd_out[2*22-1:0*22]; 
                    r_state <= s_attribdelta_1; 
                end
            end
            s_attribdelta_1: begin 
                if (w_simd_valid) begin 
                    r_z_attrib<= w_simd_out[4*22-1:2*22]; 
                    r_state <= s_OUT; 
                end
            end
            s_OUT: begin 
                if (~i_busy)
                r_state <= s_IDLE;
            end 
        endcase 
    end
        
  end
    // module instantiation 
    FP_SIMD  u_FP_SIMD (
    .clk                     ( clk                              ),
    .rst_n                   ( w_simd_rstn                            ),
    .i_en                    ( w_simd_enable                             ),
    .i_in1                   ( w_simd_in0  ),
    .i_in2                   ( w_simd_in1 ),
    .i_opcode                ( r_simd_opcode                  ),

    .o_output                ( w_simd_out),
    .o_valid                 ( w_simd_valid                          ),
    .o_busy                  ( w_simd_busy)
    ); 
    wire [20:0]  w_floor_1;
    wire  [20:0]  w_floor_o_1;
    wire [20:0]  w_floor_2;
    wire  [20:0]  w_floor_o_2;
    assign w_floor_1 = w_simd_out[2*22-2:22]; 
    assign w_floor_2 = w_simd_out[1*22-2:0]; 
    fp_floor  u_fp_floor1 (
        .i_a                     ( w_floor_1),
        .o_b                     ( w_floor_o_1)
    );  
    fp_floor  u_fp_floor2 (
        .i_a                     ( w_floor_2),
        .o_b                     ( w_floor_o_2)
    );  
    wire [21:0]  w_ftoi_1;
    wire [15:0]  w_ftoi_o_1;
    wire [21:0]  w_ftoi_2;
    wire [15:0]  w_ftoi_o_2;
    assign w_ftoi_1 = {1'b0, w_floor_o_1}; 
    assign w_ftoi_2 = {1'b0, w_floor_o_2}; 
    fp_to_int  u_fp_to_int1 (
        .i_a                     ( w_ftoi_1 ),
        .o_c                     ( w_ftoi_o_1)
    );
    fp_to_int  u_fp_to_int2 (
        .i_a                     ( w_ftoi_2 ),
        .o_c                     ( w_ftoi_o_2  ) 
    );
endmodule 
