// Made By: Abubakr Nada 
// Responsible for fragment shading, checks z buffer and writes to frame buffer 
`include "rtl/ren_params.v"

module ren_frag_shader#(parameter attrib_count=4) (
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
    // from depth buffer and frame buffer 
    i_z_buffer, 
    // edge coeffs from setup
    i_e0_a, 
    i_e1_a, 
    i_e2_a, 
    i_e0_b, 
    i_e1_b, 
    i_e2_b, 
    i_e0_c, 
    i_e1_c, 
    i_e2_c,
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
    input [21:0] i_e0_a;  
    input [21:0] i_e1_a;  
    input [21:0] i_e2_a;  
    input [21:0] i_e0_b;  
    input [21:0] i_e1_b;  
    input [21:0] i_e2_b;  
    input [21:0] i_e0_c;  
    input [21:0] i_e1_c;  
    input [21:0] i_e2_c;  
    input [21:0] i_z_buffer; 
    output o_ack ; 
    // Constants 
    localparam s_IDLE              = 0  ;  
    localparam s_setup_points_0    = 31 ; 
    localparam s_setup_points_1    = 34 ; 
    localparam s_update_points     = 32 ; 
    localparam s_basis_F0_mul_a    = 1  ;  // (1 point at a time)
    localparam s_basis_F0_mul_b    = 2  ;  
    localparam s_basis_F0_add_ab   = 3  ;  
    localparam s_basis_F0_add_c    = 4  ;  
    localparam s_basis_F1_mul_a    = 5  ;  
    localparam s_basis_F1_mul_b    = 6  ;  
    localparam s_basis_F1_add_ab   = 7  ;  
    localparam s_basis_F1_add_c    = 8  ;
    localparam s_basis_F2_mul_a    = 9  ;  
    localparam s_basis_F2_mul_b    = 10 ;  
    localparam s_basis_F2_add_ab   = 11 ;  
    localparam s_basis_F2_add_c    = 12 ;
    localparam s_basis_R_add_ab    = 13 ; 
    localparam s_basis_R_add_c     = 14 ; 
    localparam s_basis_R_rcp       = 35 ; 
    localparam s_basis_norm_mul_F0 = 15 ; 
    localparam s_basis_norm_mul_F1 = 36 ; 
    localparam s_attrib_mul_x      = 16 ;
    localparam s_attrib_mul_y      = 17 ;
    localparam s_attrib_add_xy     = 18 ;
    localparam s_attrib_add_z      = 19 ; 
    localparam s_depth_fetch       = 20 ; // check here which points valid  
    localparam s_depth_update      = 21 ;   
    localparam s_depth_writeback   = 22 ;   
    localparam s_OUT_color         = 33 ;   
    localparam s_tile_processed    = 36 ;   
    //  WIRES 
    // SIMD 
    wire [4*22-1:0] w_simd_in0; 
    wire [4*22-1:0] w_simd_in1; 
    wire [4*22-1:0] w_simd_out; 
    wire w_simd_enable ;
    wire w_simd_valid; 
    wire w_simd_busy; 
    reg r_simd_enable ; 
    wire w_simd_rstn; 
    assign w_simd_rstn = r_simd_enable; 
    wire [22*4-1:0] w_simd_reg; 
    reg [2:0] r_simd_opcode;
    // end  
    wire [21:0] w_point_in_0 ; 
    wire [21:0] w_point_in_1 ; 
    wire [21:0] w_point_in_2 ; 
    wire [21:0] w_point_in_3 ; 
    //  REGS    
    reg [7:0] r_state; 
    reg [22*4-1:0] r_points_x, r_points_y ; // ones used for parameter interpolation
    reg [22*4-1:0] r_intermediate_result ; 
    reg [22*4-1:0] r_basis_F0; 
    reg [22*4-1:0] r_basis_F1; 
    reg [15:0 ]    r_sample_count_x; 
    // depth 
    reg [3:0]      r_depth_mask ;
    reg [1:0]      r_depth_counter;
    wire[6:0] w_d_access_high; 
    assign w_d_access_high =  22*r_depth_counter-1;  
    wire[6:0] w_d_access_low ; 
    assign w_d_access_low =22*(r_depth_counter-1) ; 
    // attributes 
    reg [4:0] r_attributes_interpolated ; 
    reg [15:0 ]    r_sample_count_y; 
    
    // vtx attribute interpolated 
    reg [22*4-1:0] r_interpolated_attrib; 
    // assignment
    

    // assignment for first 
    assign w_simd_in0 = ((r_state==s_setup_points_0) ? ((i_tile_size< 4) ? {i_tile_x , i_tile_x, i_tile_y, i_tile_y}: {i_tile_x , i_tile_x , i_tile_x , i_tile_x}) : 
    (r_state==s_setup_points_1) ? {i_tile_y , i_tile_y , i_tile_y , i_tile_y }:  
    (r_state==s_update_points)  ? ((r_sample_count_x>=i_tile_size) ? r_points_y : r_points_x):  // if it's equal to tile size then add to y 
    (r_state==s_basis_F0_mul_a) ? r_points_x :  
    (r_state==s_basis_F0_mul_b) ? r_points_y :  
    (r_state==s_basis_F0_add_ab)? r_basis_F0 :  // edit this
    (r_state==s_basis_F0_add_c) ? r_basis_F0 :  // edit this
    (r_state==s_basis_F1_mul_a) ? r_points_x:  
    (r_state==s_basis_F1_mul_b) ? r_points_y:  
    (r_state==s_basis_F1_add_ab)? r_basis_F0:  
    (r_state==s_basis_F1_add_c) ? r_basis_F0:  
    (r_state==s_basis_F2_mul_a) ? r_points_x :  
    (r_state==s_basis_F2_mul_b) ? r_points_y :  
    (r_state==s_basis_F2_add_ab)? r_intermediate_result :  
    (r_state==s_basis_F2_add_c) ? r_intermediate_result :  
    (r_state==s_basis_R_add_ab) ? r_basis_F0 :  
    (r_state==s_basis_R_add_c)  ? w_simd_reg :  
    (r_state==s_basis_norm_mul_F0) ? r_basis_F0: 
    (r_state==s_basis_norm_mul_F1) ? r_basis_F1: 

    0) ; 
    assign w_simd_in1 = ((r_state==s_setup_points_0) ? ((i_tile_size< 4) ? {`fpHALF , `fpONEHALF ,`fpHALF, `fpONEHALF }: {`fpHALF , `fpONEHALF , `fpTWOHALF , `fpTHREEHALF}) : 
    (r_state==s_setup_points_1) ? {`fpHALF , `fpHALF , `fpHALF , `fpHALF  }:  
    (r_state==s_update_points) ? ((r_sample_count_x>=i_tile_size) ? {`fpONE , `fpONE , `fpONE , `fpONE } : {`fpONE, `fpTWO, `fpTHREE, `fpFOUR}):  // if it's equal to tile size then add to y 
    (r_state==s_basis_F0_mul_a) ? {i_e0_a ,i_e0_a , i_e0_a, i_e0_a  }:  
    (r_state==s_basis_F0_mul_b) ? {i_e0_b ,i_e0_b , i_e0_b, i_e0_b  } :  
    (r_state==s_basis_F0_add_ab)? w_simd_reg :  // edit this
    (r_state==s_basis_F0_add_c) ? {i_e0_c ,i_e0_c , i_e0_c, i_e0_c  }:  
    (r_state==s_basis_F1_mul_a) ? {i_e1_a ,i_e1_a , i_e1_a, i_e1_a  }:  
    (r_state==s_basis_F1_mul_b) ? {i_e1_b ,i_e1_b , i_e1_b, i_e1_b  } :  
    (r_state==s_basis_F1_add_ab)? w_simd_reg:  
    (r_state==s_basis_F1_add_c) ? {i_e1_c ,i_e1_c , i_e1_c, i_e1_c  } :  
    (r_state==s_basis_F2_mul_a) ? {i_e2_a ,i_e2_a , i_e2_a, i_e2_a  } :  
    (r_state==s_basis_F2_mul_b) ? {i_e2_b ,i_e2_b , i_e2_b, i_e2_b  } :  
    (r_state==s_basis_F2_add_ab)? w_simd_reg :  
    (r_state==s_basis_F2_add_c) ? {i_e2_c ,i_e2_c , i_e2_c, i_e2_c  } :  
    (r_state==s_basis_R_add_ab) ? r_basis_F1:  
    (r_state==s_basis_R_add_c)  ? r_intermediate_result:  
    (r_state==s_basis_norm_mul_F0) ? r_intermediate_result:  
    (r_state==s_basis_norm_mul_F1) ? r_intermediate_result:  
    0) ; 
    //  ALWAYS 

    // main FSM 
    always @(posedge clk ) begin
        case(r_state) 
            s_IDLE: begin 

            end
            s_setup_points_0 : begin 
                if (w_simd_valid)begin 
                    // r_
                    if (i_tile_size == 1) begin 
                        r_points_x <= {w_simd_out[22*4-1:22*3] , 66'd0} ; 
                        r_points_y <= {w_simd_out[22*2-1:22*1] , 66'd0} ; 
                    end else if(i_tile_size==2) begin 
                        r_points_x <= {w_simd_out[22*4-1:22*3], w_simd_out[22*3-1:22*2], w_simd_out[22*4-1:22*3], w_simd_out[22*3-1:22*2]} ; 
                        r_points_y <= {w_simd_out[22*2-1:22*1] , w_simd_out[22*2-1:22*1] , w_simd_out[22*1-1:22*0], w_simd_out[22*1-1:22*0]} ; 
                    end
                    else begin 
                        r_points_x <= w_simd_out; 
                    end
                    if(r_sample_count_y == 0 ) begin  // if y points weren't setup 
                        r_state <= s_setup_points_1; 
                    end 
                    else 
                        r_state <= s_basis_F0_mul_a; 
                end
            end
            s_setup_points_1: begin 
                if (w_simd_valid)begin 
                    r_state <= s_basis_F0_mul_a; 
                    r_points_y <= w_simd_out; 
                end
            end
            s_update_points: begin 
                if (r_sample_count_y >= i_tile_size-1 && r_sample_count_x >= i_tile_size) begin 
                    // finished  tile 
                    r_sample_count_x <= 0 ; 
                    r_sample_count_y <= 0 ; 
                    r_state <= s_IDLE ;
                end else begin 
                    if (w_simd_valid) begin 
                        if (r_sample_count_x >= i_tile_size-1) begin 
                            r_sample_count_x <= 0 ; 
                            r_sample_count_y <= r_sample_count_y + 1; 
                            r_points_y <= w_simd_out; 
                            r_state <= s_setup_points_0; 
                        end
                        else begin 
                            r_sample_count_x <= r_sample_count_x + 4; 
                            r_points_x <= w_simd_out; 
                            r_state <= s_basis_F0_mul_a ; 
                        end
                    end
                end
            end
            s_basis_F0_mul_a : begin 
                if(w_simd_valid)begin 
                    r_basis_F0 <= w_simd_out; 
                    r_state    <= s_basis_F0_mul_b; 
                end
            end 
            s_basis_F0_mul_b : begin 
                if(w_simd_valid)begin 
                    r_state <= s_basis_F0_add_ab ; 
                    r_simd_opcode <= `op_add; 
                end
            end 
            s_basis_F0_add_ab: begin 
                if(w_simd_valid)begin 
                    r_basis_F0 <= w_simd_out; 
                    r_state <= s_basis_F0_add_c; 
                end
            end 
            s_basis_F0_add_c : begin 
                if(w_simd_valid)begin 
                    r_basis_F0 <= w_simd_out; 
                    r_state <= s_basis_F1_mul_a; 
                    r_simd_opcode <= `op_mul; 
                end
            end 
            s_basis_F1_mul_a : begin 
                if(w_simd_valid)begin 
                    r_basis_F1 <= w_simd_out; 
                    r_state    <= s_basis_F1_mul_b; 
                end
            end 
            s_basis_F1_mul_b : begin 
                if(w_simd_valid)begin 
                    r_state <= s_basis_F1_add_ab ; 
                    r_simd_opcode <= `op_add; 
                end
            end 
            s_basis_F1_add_ab: begin 
                if(w_simd_valid)begin 
                    r_basis_F1 <= w_simd_out; 
                    r_state <= s_basis_F1_add_c; 
                end
            end 
            s_basis_F1_add_c : begin 
                if(w_simd_valid)begin 
                    r_basis_F1 <= w_simd_out; 
                    r_state <= s_basis_F2_mul_a; 
                    r_simd_opcode <= `op_mul; 
                end
            end 
            s_basis_F2_mul_a : begin 
                if(w_simd_valid)begin 
                    r_state <= s_basis_F2_add_c; 
                end
            end 
            s_basis_F2_mul_b : begin 
            end 
            s_basis_F2_add_ab: begin 
            end 
            s_basis_F2_add_c : begin 
            end 
            s_basis_R_add_ab  : begin 
            end 
            s_basis_R_add_c    : begin 
            end 
            s_basis_R_rcp    : begin 
            end 
            s_basis_norm_mul_F0 : begin 

            end 
            s_basis_norm_mul_F1 : begin 
            end  
            s_attrib_mul_x : begin 
            end
            s_attrib_mul_y : begin 
            end
            s_attrib_add_xy: begin 
            end
            s_attrib_add_z: begin 
                if (w_simd_valid)begin 
                    r_attributes_interpolated <= w_simd_out ;
                    
                end
            end
            s_depth_fetch : begin 
                if (r_depth_counter == 4)begin 
                    r_depth_counter <= 0 ; 
                    // subtract operation r_intermediate_z - interpolated z - reg [22*4-1:0] r_interpolated_attrib; 
                    
                end else begin 
                    case (r_depth_counter)
                        0: begin
                            r_intermediate_result[22*4-1:22*1] <= i_z_buffer;
                        end
                        1:  begin 
                            r_intermediate_result[22*3-1:22*2] <= i_z_buffer; 
                        end
                        2: begin 
                             r_intermediate_result[22*2-1:22*1] <= i_z_buffer; 
                        end
                        3: begin
                             r_intermediate_result[22*1-1:22*0] <= i_z_buffer; 
                        end
                    endcase
                    r_depth_counter <= r_depth_counter + 1; 
                end
            end
            s_depth_update: begin 
                // do the comparison and create depth mask , and then update z buffer if necessary
                if (w_simd_valid)begin 
                    r_depth_mask <= {w_simd_out[4*22-1], w_simd_out[3*22-1], w_simd_out[2*22-1], w_simd_out[1*22-1] }; 
                    r_simd_enable <= 0 ; 
                    r_state <= s_depth_writeback; 
                end
            end
            s_depth_writeback: begin 
                // update depth 
                
            end
            s_OUT_color : begin 
                r_state <= s_update_points; 
            end

    
        endcase 
    end

    //  MODULE INSTANSIATION
    FP_SIMD  u_FP_SIMD (
    .clk                     ( clk                              ),
    .rst_n                   ( w_simd_rst                            ),
    .i_en                    ( w_simd_enable                             ),
    .i_in1                   ( w_simd_in0  ),
    .i_in2                   ( w_simd_in1 ),
    .i_opcode                ( r_simd_opcode                  ),

    .o_output                ( w_simd_out),
    .o_valid                 ( w_simd_valid                          ),
    .o_busy                  ( w_simd_busy),
    .o_reg_out  (w_simd_reg)
    ); 

endmodule 