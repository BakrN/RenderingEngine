// Made By: Abubakr Nada 
// Responsible for fragment shading, checks z buffer and writes to frame buffer 
`include "ren_params.sv"

module ren_frag_shader#(parameter attrib_count=4) ( // always enabled 
    clk, 
    rstn, 
    i_fifo_empty,   
    i_tile,   
    i_cr_delta, 
    i_cg_delta, 
    i_cb_delta, 
    i_z_delta, 
    // from depth buffer and frame buffer 
    i_z_buffer, 
    // edge coeffs from setup
    i_e0 , 
    i_e1 , 
    i_e2 
    // depth buffer & image buffer out

); 
    input clk  ; 
    input rstn;  
    input i_fifo_empty ; 
    input tile_t i_tile ; 
    input [22*3-1:0] i_cr_delta;  
    input [22*3-1:0] i_cg_delta;  
    input [22*3-1:0] i_cb_delta; 
    input [22*3-1:0] i_z_delta; 
    input edge_t i_e0; 
    input edge_t i_e1; 
    input edge_t i_e2; 
    input fp22_t i_z_buffer; 
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
    //  logicS 
    // fifo 
    logic r_fifo_rd; 
    // SIMD 
    logic [4*22-1:0] w_simd_in0; 
    logic [4*22-1:0] w_simd_in1; 
    logic [4*22-1:0] w_simd_out; 
    logic [4*22-1:0] w_simd_reg_out; 
    logic r_simd_enable ;
    logic w_simd_valid; 
    logic w_simd_busy; 
    logic w_simd_rstn; 
    assign w_simd_rstn = r_simd_enable; 
    logic [2:0] r_simd_opcode;
    // end  
    fp22_t w_point_in_0 ; 
    fp22_t w_point_in_1 ; 
    fp22_t w_point_in_2 ; 
    fp22_t w_point_in_3 ; 
    //  REGS    
    logic [7:0] r_state; 
    logic [22*4-1:0] r_points_x, r_points_y ; // ones used for parameter interpolation
    logic [22*4-1:0] r_intermediate_result ; 
    logic [22*4-1:0] r_basis_F0; 
    logic [22*4-1:0] r_basis_F1; 
    logic [15:0 ]    r_sample_count_x; 
    // depth 
    logic [3:0]      r_depth_mask ;
    logic [1:0]      r_depth_counter;
    logic[6:0] w_d_access_high; 
    assign w_d_access_high =  22*r_depth_counter-1;  
    logic[6:0] w_d_access_low ; 
    assign w_d_access_low =22*(r_depth_counter-1) ; 
    // attributes 
    logic [4:0] r_attributes_interpolated ; 
    logic [15:0 ]    r_sample_count_y; 
    
    // vtx attribute interpolated 
    logic [22*4-1:0] r_interpolated_attrib; 
    // assignment
    

    // assignment for first 
    assign w_simd_in0 = ((r_state==s_setup_points_0) ? ((i_tile.size< 4) ? {i_tile.x , i_tile.x, i_tile.y, i_tile.y}: {i_tile.x , i_tile.x , i_tile.x , i_tile.x}) : 
    (r_state==s_setup_points_1) ? {i_tile.y , i_tile.y , i_tile.y , i_tile.y }:  
    (r_state==s_update_points)  ? ((r_sample_count_x>=i_tile.size) ? r_points_y : r_points_x):  // if it's equal to tile size then add to y 
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
    (r_state==s_basis_R_add_c)  ? w_simd_reg_out :  
    (r_state==s_basis_norm_mul_F0) ? r_basis_F0: 
    (r_state==s_basis_norm_mul_F1) ? r_basis_F1: 

    0) ; 
    assign w_simd_in1 = ((r_state==s_setup_points_0) ? ((i_tile.size< 4) ? {`fpHALF , `fpONEHALF ,`fpHALF, `fpONEHALF }: {`fpHALF , `fpONEHALF , `fpTWOHALF , `fpTHREEHALF}) : 
    (r_state==s_setup_points_1) ? {`fpHALF , `fpHALF , `fpHALF , `fpHALF  }:  
    (r_state==s_update_points) ? ((r_sample_count_x>=i_tile.size) ? {`fpONE , `fpONE , `fpONE , `fpONE } : {`fpONE, `fpTWO, `fpTHREE, `fpFOUR}):  // if it's equal to tile size then add to y 
    (r_state==s_basis_F0_mul_a) ? {i_e0.a ,i_e0.a , i_e0.a, i_e0.a  }:  
    (r_state==s_basis_F0_mul_b) ? {i_e0.b ,i_e0.b , i_e0.b, i_e0.b  } :  
    (r_state==s_basis_F0_add_ab)? r_intermediate_result :  
    (r_state==s_basis_F0_add_c) ? {i_e0.c ,i_e0.c , i_e0.c, i_e0.c  }:  
    (r_state==s_basis_F1_mul_a) ? {i_e1.a ,i_e1.a , i_e1.a, i_e1.a  }:   
    (r_state==s_basis_F1_mul_b) ? {i_e1.b ,i_e1.b , i_e1.b, i_e1.b  } :  
    (r_state==s_basis_F1_add_ab)? r_intermediate_result:  
    (r_state==s_basis_F1_add_c) ? {i_e1.c ,i_e1.c , i_e1.c, i_e1.c  } :  
    (r_state==s_basis_F2_mul_a) ? {i_e2.a ,i_e2.a , i_e2.a, i_e2.a  } :  
    (r_state==s_basis_F2_mul_b) ? {i_e2.b ,i_e2.b , i_e2.b, i_e2.b  } :  
    (r_state==s_basis_F2_add_ab)? w_simd_reg_out:  
    (r_state==s_basis_F2_add_c) ? {i_e2.c ,i_e2.c , i_e2.c, i_e2.c  } :  
    (r_state==s_basis_R_add_ab) ? r_basis_F1:  
    (r_state==s_basis_R_add_c)  ? r_intermediate_result:  
    (r_state==s_basis_norm_mul_F0) ? r_intermediate_result:  
    (r_state==s_basis_norm_mul_F1) ? r_intermediate_result:  
    0) ; 
    //  ALWAYS 

    // main FSM 
    always_ff @(posedge clk or negedge rstn ) begin
        if (!rstn)begin 
        end else begin 
        case(r_state) 
            s_IDLE: begin 
                if (!i_fifo_empty) begin 
                    // enable read                    
                end
            end
            s_setup_points_0 : begin 
                if (w_simd_valid)begin 
                    // r_
                    if (i_tile.size == 1) begin 
                        r_points_x <= {w_simd_out[22*4-1:22*3] , 66'd0} ; 
                        r_points_y <= {w_simd_out[22*2-1:22*1] , 66'd0} ; 
                    end else if(i_tile.size==2) begin 
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
                if (r_sample_count_y >= i_tile.size-1 && r_sample_count_x >= i_tile.size) begin 
                    // finished  tile 
                    r_sample_count_x <= 0 ; 
                    r_sample_count_y <= 0 ;  
                    r_state <= s_IDLE ;
                end else begin 
                    if (w_simd_valid) begin 
                        if (r_sample_count_x >= i_tile.size-1) begin 
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
                    r_intermediate_result <= w_simd_out; 
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
                    r_intermediate_result <= w_simd_out; 
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
                    r_state <= s_basis_F2_mul_b;
                    r_intermediate_result <= w_simd_out ;  
                end
            end 
            s_basis_F2_mul_b : begin 
                if(w_simd_valid)begin 
                    r_state <= s_basis_F2_add_ab; 
                    r_simd_opcode <= `op_add; 
                end
            end 
            s_basis_F2_add_ab: begin 
                if(w_simd_valid)begin 
                    r_intermediate_result <= w_simd_out; 
                    r_state <= s_basis_F2_add_c; 
                end
            end 
            s_basis_F2_add_c : begin 
                if(w_simd_valid)begin 
                    r_state <= s_basis_R_add_ab;   
                end 
            end 
            s_basis_R_add_ab  : begin 
                if(w_simd_valid)begin 
                    r_state <= s_basis_R_add_c;   
                end 
            end 
            s_basis_R_add_c    : begin 
                if(w_simd_valid)begin 
                    r_intermediate_result <= w_simd_out;  
                    r_state <= s_basis_R_rcp;   
                    r_simd_opcode <= `op_rcp; 
                end  
            end 
            s_basis_R_rcp    : begin  
                if (w_simd_valid) begin  
                    r_intermediate_result <= w_simd_out;
                    r_simd_opcode <= `op_mul;  
                    r_state <= s_basis_norm_mul_F0; 
                end  
            end 
            s_basis_norm_mul_F0 : begin 
                if(w_simd_valid) begin 
                    r_basis_F0 <= w_simd_out; 
                    r_state <= s_basis_norm_mul_F1; 
                end
            end 
            s_basis_norm_mul_F1 : begin 
                if(w_simd_valid) begin 
                    r_basis_F1 <= w_simd_out; 
                    r_state <= s_attrib_mul_x;  // start interpolation 
                end
            end  
            s_attrib_mul_x : begin  // with deltas calculated in setup 
                if(w_simd_valid) begin 
                    r_basis_F1 <= w_simd_out; 
                    r_state <= s_attrib_mul_x;  // start interpolation 
                end
            end
            s_attrib_mul_y : begin 
                if(w_simd_valid) begin 
                    r_basis_F1 <= w_simd_out; 
                    r_state <= s_attrib_mul_x;  // start interpolation 
                end
            end
            s_attrib_add_xy: begin 
                if(w_simd_valid) begin  
                    r_basis_F1 <= w_simd_out; 
                    r_state <= s_attrib_mul_x;  // start interpolation 
                end
            end
            s_attrib_add_z: begin 
                if (w_simd_valid)begin 
                    r_attributes_interpolated <= w_simd_out ;
                    
                end
            end
            s_depth_fetch : begin 
                if (r_depth_counter == 4)begin 
                    r_depth_counter <= 0 ; 
                    // subtract operation r_intermediate_z - interpolated z - logic [22*4-1:0] r_interpolated_attrib; 
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
    end
    //  MODULE INSTANSIATION
    FP_SIMD  u_FP_SIMD (
    .clk                     ( clk                              ),
    .rst_n                   ( w_simd_rst                            ),
    .i_en                    ( r_simd_enable                             ),
    .i_in1                   ( w_simd_in0  ),
    .i_in2                   ( w_simd_in1 ),
    .i_opcode                ( r_simd_opcode                  ),

    .o_output                ( w_simd_out),
    .o_valid                 ( w_simd_valid                          ),
    .o_busy                  ( w_simd_busy),
    .o_reg_out  (w_simd_reg_out)
    );       


endmodule 