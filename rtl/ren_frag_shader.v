// Made By: Abubakr Nada 
// Responsible for fragment shading, checks z buffer, color buffer and writes to frame buffer 


module ren_frag_shader(
    clk, 
    rst_n, 
    i_en, 
    i_valid, 
    i_tile_x, 
    i_tile_y, 
    i_tile_size, // int 
    i_cr_delta, 
    i_cg_delta, 
    i_cb_delta, 
    i_z_delta, 
    o_ack 
); 
    input clk  ; 
    input rst_n; 
    input i_valid; 
    input i_en; 
    input [21:0] i_tile_x; 
    input [21:0] i_tile_y; 
    input [15:0] i_tile_size; // 16 8 4 2 1 
    input [22*3-1:0] i_cr_delta;  
    input [22*3-1:0] i_cg_delta;  
    input [22*3-1:0] i_cb_delta; 
    input [22*3-1:0] i_z_delta; 
    output o_ack ; 
    // Constants 
    localparam s_IDLE            = 0  ;  
    localparam s_setup_points    = 31 ; 
    localparam s_basis_F0_mul_a  = 1  ;  // (1 point at a time)
    localparam s_basis_F0_mul_b  = 2  ;  
    localparam s_basis_F0_add_ab = 3  ;  
    localparam s_basis_F0_add_c  = 4  ;  
    localparam s_basis_F1_mul_a  = 5  ;  
    localparam s_basis_F1_mul_b  = 6  ;  
    localparam s_basis_F1_add_ab = 7  ;  
    localparam s_basis_F1_add_c  = 8  ;
    localparam s_basis_F2_mul_a  = 9  ;  
    localparam s_basis_F2_mul_b  = 10 ;  
    localparam s_basis_F2_add_ab = 11 ;  
    localparam s_basis_F2_add_c  = 12 ;
    localparam s_basis_R_load    = 13 ; 
    localparam s_basis_R_red     = 14 ; 
    localparam s_basis_norm_mul  = 15 ; 
    localparam s_attrib_cr_mul   = 16 ; // using deltas 
    localparam s_attrib_cr_red   = 17 ; 
    localparam s_attrib_cg_mul   = 18 ; 
    localparam s_attrib_cg_red   = 19 ; 
    localparam s_attrib_cb_mul   = 20 ; 
    localparam s_attrib_cb_red   = 21 ; 
    localparam s_attrib_depth_mul= 22 ; 
    localparam s_attrib_depth_red= 23 ; 
    localparam s_OUT = 30 ;   
    //  WIRES 
    // SIMD 
    wire [4*22-1:0] w_simd_in0; 
    wire [4*22-1:0] w_simd_in1; 
    wire [4*22-1:0] w_simd_out; 
    wire w_simd_enable ;
    wire w_simd_valid; 
    wire w_simd_busy; 
    reg [2:0] r_simd_opcode;
    // end  
    wire [21:0] w_point_in_0 ; 
    wire [21:0] w_point_in_1 ; 
    wire [21:0] w_point_in_2 ; 
    wire [21:0] w_point_in_3 ; 
    //  REGS    
    reg [7:0] r_state; 
    reg [22*4-1:0] r_points_x, r_points_y ; // ones used for parameter interpolation
    // assignment  
    // assignment for first 
    assign w_simd_in0 = ((1) ?0 : 
    0) ; 
    assign w_simd_in1 = ((1) ?0 : 
    0) ; 
    //  ALWAYS 

    // main FSM 
    always @(posedge clk ) begin
        case(r_state) 
            s_IDLE: begin 

            end
            s_basis_F0_mul_a : begin 

            end 
            s_basis_F0_mul_b : begin 
            end 
            s_basis_F0_add_ab: begin 
            end 
            s_basis_F0_add_c : begin 
                end 
            s_basis_F1_mul_a : begin 
                end 
            s_basis_F1_mul_b : begin 
                end 
            s_basis_F1_add_ab: begin 
                end 
            s_basis_F1_add_c : begin 
                end 
            s_basis_F2_mul_a : begin 
                end 
            s_basis_F2_mul_b : begin 
                end 
            s_basis_F2_add_ab: begin 
                end 
            s_basis_F2_add_c : begin 
                end 
            s_basis_R_load   : begin 
                end 
            s_basis_R_red    : begin 
                end 
            s_basis_norm_mul : begin 
                end 
            s_attrib_cr_mul  : begin 
                end 
            s_attrib_cr_red  : begin 
                end 
            s_attrib_cg_mul  : begin 
                end 
            s_attrib_cg_red  : begin 
                end 
            s_attrib_cb_mul  : begin 
                end 
            s_attrib_cb_red  : begin 
                end 
            s_attrib_depth_mul : begin 
            end
            s_attrib_depth_red : begin 
            end

    
        endcase 
    end

    //  MODULE INSTANSIATION
    FP_SIMD  u_FP_SIMD (
    .clk                     ( clk                              ),
    .rst_n                   ( rst_n                            ),
    .i_en                    ( w_simd_enable                             ),
    .i_in1                   ( w_simd_in0  ),
    .i_in2                   ( w_simd_in1 ),
    .i_opcode                ( r_simd_opcode                  ),

    .o_output                ( w_simd_out),
    .o_valid                 ( w_simd_valid                          ),
    .o_busy                  ( w_simd_busy)
    ); 

endmodule 