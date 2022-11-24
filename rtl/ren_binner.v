// Made by: Abubakr Nada 
// Calculates TR and TA corners of a corner 
// writes to either frag_shader with tile_start_x, y and size or rasterizer for further reduction 
// Floating poitn format for 16 is: 0b 5'b10011 16'h8000 , 2^4
`include "rtl/ren_params.v"
module ren_binner(
    clk, 
    // control
    i_en,  
    rstn, 
    i_valid ,
    i_ack_r ,  // raster acknoledgement
    // inputs 
    i_e0_a  , 
    i_e0_b  , 
    i_e0_c  , 
    i_e1_a  , 
    i_e1_b  , 
    i_e1_c  , 
    i_e2_a  , 
    i_e2_b  , 
    i_e2_c  ,
    i_min_x , 
    i_min_y ,
    i_step_x, 
    i_step_y, 
    // reaster in 
    i_busy_r , // raster busy ( stall )
    i_full , // fifo (stall)
    // outputs
    o_tile_x , 
    o_tile_y , 
    o_tile_size,
    o_valid_r , // ctrl for raster out  
    o_busy , 
    o_fifo_write 
) ;
    // PORTS IO 
    input clk ;     
    input i_en; 
    input rstn; 
    input i_valid; 
    input i_busy_r; 
    input i_full  ;  
    input [21:0] i_e0_a ; 
    input [21:0] i_e0_b ; 
    input [21:0] i_e0_c ; 
    input [21:0] i_e1_a ; 
    input [21:0] i_e1_b ; 
    input [21:0] i_e1_c ; 
    input [21:0] i_e2_a ; 
    input [21:0] i_e2_b ; 
    input [21:0] i_e2_c ;
    input [21:0] i_min_x; 
    input [21:0] i_min_y; 
    input [21:0] i_step_x; 
    input [21:0] i_step_y; 
    input i_ack_r ; 
    output [21:0] o_tile_x ; 
    output [21:0] o_tile_y ; 
    output [15:0] o_tile_size; 
    output o_valid_r; 
    output o_busy; 
    output o_fifo_write ; 
    // Constant 
    // FSM : s_STAGE_OPERATION(_#)// in sequential order 
    localparam op_add = 0 ; 
    localparam op_sub= 1 ; 
    localparam op_mul = 2 ; 
    localparam op_rcp =  3 ; 
    localparam op_reduce_add = 4 ; 
    localparam op_reduce_mul = 5 ; 
    localparam s_IDLE = 0 ; 
    localparam s_norm_add       = 1 ; 
    localparam s_norm_rcp       = 2 ;
    localparam s_norm_mul_0     = 3 ;
    localparam s_norm_mul_1     = 4 ;
    localparam s_norm_mul_2     = 5 ;
    localparam s_efunc_mul_0    = 6 ; 
    localparam s_efunc_red_0    = 7 ; 
    localparam s_efunc_mul_1    = 8 ; 
    localparam s_efunc_red_1    = 9 ; 
    localparam s_efunc_mul_2    = 10 ; 
    localparam s_efunc_red_2    = 11 ; 
    localparam s_efunc_tr_add_0 = 25 ; 
    localparam s_efunc_tr_mul_0 = 12 ; 
    localparam s_efunc_tr_red_0 = 13 ; 
    localparam s_efunc_tr_add_1 = 26 ; 
    localparam s_efunc_tr_mul_1 = 14 ; 
    localparam s_efunc_tr_red_1 = 15 ; 
    localparam s_efunc_tr_add_2 = 27 ; 
    localparam s_efunc_tr_mul_2 = 16 ; 
    localparam s_efunc_tr_red_2 = 17 ; 
    localparam s_efunc_ta_add_0 = 28 ; 
    localparam s_efunc_ta_mul_0 = 18 ; 
    localparam s_efunc_ta_red_0 = 19 ; 
    localparam s_efunc_ta_add_1 = 29 ; 
    localparam s_efunc_ta_mul_1 = 20 ; 
    localparam s_efunc_ta_red_1 = 21 ; 
    localparam s_efunc_ta_add_2 = 30 ; 
    localparam s_efunc_ta_mul_2 = 22 ; 
    localparam s_efunc_ta_red_2 = 23 ; 
    localparam s_raster_out = 24;
    localparam s_shader_out = 31;
    localparam s_tile_step = 32; 
    localparam [21:0] tile_size = {1'b0, 5'b10011 , 16'h8000}; 
    // Wires  
    wire [1:0]  w_e0_tr ;
    wire [1:0]  w_e1_tr;  
    wire [1:0]  w_e2_tr; 
    wire [1:0]  w_e0_ta; 
    wire [1:0]  w_e1_ta; 
    wire [1:0]  w_e2_ta; 
    
    wire w_tr_tile ;
    wire w_ta_tile ;
    // SIMD
    wire [4*22-1:0] w_simd_in0; 
    wire [4*22-1:0] w_simd_in1; 
    wire [4*22-1:0] w_simd_out; 
    wire w_simd_enable ;
    wire w_simd_valid; 
    wire w_simd_busy; 
    reg [2:0] r_simd_opcode;
    // Registers 
    reg [21:0] r_ee0_a; 
    reg [21:0] r_ee1_a; 
    reg [21:0] r_ee2_a; 
    reg [21:0] r_ee0_b; 
    reg [21:0] r_ee1_b; 
    reg [21:0] r_ee2_b; 
    reg [21:0] r_ee0_c; 
    reg [21:0] r_ee1_c; 
    reg [21:0] r_ee2_c; 
    reg [21:0] r_e0_func; 
    reg [21:0] r_e1_func; 
    reg [21:0] r_e2_func; 
    reg [21:0] r_tx ; // tile x 
    reg [21:0] r_ty ; // tile y
    reg [21:0] r_intermediate_x  ,r_intermediate_y; 
    reg [5:0] r_state; 
    reg [15:0] r_tx_counter; 
    reg [15:0] r_ty_counter; 
    

    // Assign 
    assign w_simd_in0 = (r_state==s_norm_add) ? {{1'b0, i_e0_a[20:0]} , {1'b0 ,i_e1_a[20:0]} , {1'b0 ,i_e2_a[20:0]} , 22'd0} : 
    ((r_state==s_norm_mul_0) ? {i_e0_a, i_e0_b , i_e0_c , i_e1_a} : 
    ((r_state==s_norm_mul_1) ? {i_e1_b , i_e1_c, i_e2_a , i_e2_b} : 
    ((r_state==s_norm_mul_2) ? {i_e2_c , 66'd0} : 
    ((r_state==s_efunc_mul_0) ? {r_ee0_c ,r_ee0_a , r_ee0_b, 22'd0} :
    ((r_state==s_efunc_mul_1) ? {r_ee1_c ,r_ee1_a , r_ee1_b, 22'd0} : 
    ((r_state==s_efunc_mul_2) ? {r_ee2_c ,r_ee2_a , r_ee2_b, 22'd0} :
    ((r_state==s_efunc_tr_add_0) ? {w_corner_offsets[w_e0_tr][43:22] , w_corner_offsets[w_e0_tr][21:0] , 44'd0} : // x , y
    ((r_state==s_efunc_tr_mul_0) ? {r_e0_func , r_ee0_a , r_ee0_b ,22'd0} : 
    ((r_state==s_efunc_tr_add_1) ? {w_corner_offsets[w_e1_tr][43:22] , w_corner_offsets[w_e1_tr][21:0] , 44'd0} :
    ((r_state==s_efunc_tr_mul_1) ? {r_e1_func , r_ee1_a , r_ee1_b ,22'd0} : 
    ((r_state==s_efunc_tr_add_2) ? {w_corner_offsets[w_e2_tr][43:22] , w_corner_offsets[w_e2_tr][21:0] , 44'd0} :
    ((r_state==s_efunc_tr_mul_2) ? {r_e2_func , r_ee2_a , r_ee2_b ,22'd0} : 
    ((r_state==s_efunc_ta_add_0) ? {w_corner_offsets[w_e0_ta][43:22] , w_corner_offsets[w_e0_ta][21:0] , 44'd0} :
    ((r_state==s_efunc_ta_mul_0) ? {r_e0_func , r_ee0_a , r_ee0_b ,22'd0} : 
    ((r_state==s_efunc_ta_add_1) ? {w_corner_offsets[w_e1_ta][43:22] , w_corner_offsets[w_e1_ta][21:0] , 44'd0} :
    ((r_state==s_efunc_ta_mul_1) ? {r_e1_func , r_ee1_a , r_ee1_b ,22'd0} : 
    ((r_state==s_efunc_ta_add_2) ? {w_corner_offsets[w_e2_ta][43:22] , w_corner_offsets[w_e2_ta][21:0] , 44'd0} :
    ((r_state==s_efunc_ta_mul_2) ? {r_e2_func , r_ee2_a , r_ee2_b ,22'd0} : 
    ((r_state==s_tile_step) ? {r_tx, r_ty, 22'd0,22'd0} : 
    1))))))))))))))))))); 
    assign w_simd_in1 = (r_state==s_norm_add) ? {{1'b0, i_e0_b[20:0]} , {1'b0 ,i_e1_b[20:0]} , {1'b0 ,i_e2_b[20:0]} , 22'd0} : 
    ((r_state==s_norm_mul_0) ? {r_ee0_a, r_ee0_b, r_ee0_c, r_ee1_a} : 
    ((r_state==s_norm_mul_1) ? {r_ee1_b, r_ee1_c, r_ee2_a , r_ee2_b} : 
    ((r_state==s_norm_mul_2) ? {r_ee2_c , 66'd0} : 
    ((r_state==s_efunc_mul_0) ? {{1'b0 , 5'hf , 16'h8000} ,r_tx , r_ty, 22'd0} :
    ((r_state==s_efunc_mul_1) ? {{1'b0 , 5'hf , 16'h8000} ,r_tx , r_ty, 22'd0} :
    ((r_state==s_efunc_mul_2) ? {{1'b0 , 5'hf , 16'h8000} ,r_tx , r_ty, 22'd0} :
    ((r_state==s_efunc_tr_add_0) ? {r_tx ,r_ty , 44'd0} : // x , y
    ((r_state==s_efunc_tr_mul_0) ? {{1'b0 , 5'hf , 16'h8000} , r_intermediate_x, r_intermediate_y,22'd0} : // intermediate results obtained from prev addition
    ((r_state==s_efunc_tr_add_1) ? {r_tx ,r_ty , 44'd0} : // x , y
    ((r_state==s_efunc_tr_mul_1) ? {{1'b0 , 5'hf , 16'h8000} , r_intermediate_x, r_intermediate_y,22'd0} : 
    ((r_state==s_efunc_tr_add_2) ? {r_tx ,r_ty , 44'd0} : // x , y
    ((r_state==s_efunc_tr_mul_2) ? {{1'b0 , 5'hf , 16'h8000} , r_intermediate_x, r_intermediate_y,22'd0} : 
    ((r_state==s_efunc_ta_add_0) ? {r_tx ,r_ty , 44'd0} : // x , y
    ((r_state==s_efunc_ta_mul_0) ? {{1'b0 , 5'hf , 16'h8000} , r_intermediate_x, r_intermediate_y,22'd0} : 
    ((r_state==s_efunc_ta_add_1) ? {r_tx ,r_ty , 44'd0} : // x , y
    ((r_state==s_efunc_ta_mul_1) ? {{1'b0 , 5'hf , 16'h8000} , r_intermediate_x, r_intermediate_y,22'd0} : 
    ((r_state==s_efunc_ta_add_2) ? {r_tx ,r_ty , 44'd0} : // x , y
    ((r_state==s_efunc_ta_mul_2) ? {{1'b0 , 5'hf , 16'h8000} , r_intermediate_x, r_intermediate_y,22'd0} : 
    ((r_state==s_tile_step) ? {`fpTILE_SIZE, `fpTILE_SIZE, 22'd0,22'd0} : 
    1))))))))))))))))))); 
    assign w_tr_tile = 0; // ors less than 0
    assign w_ta_tile = 0; // and over 0 
    assign o_tile_size = `TILE_SIZE ; 
    assign o_valid_r = (r_state == s_raster_out) ? 1 : 0 ;  
    assign o_tile_x = r_tx ; 
    assign o_tile_x = r_ty  ; 
    assign o_fifo_write = (r_state == s_shader_out) ? 1 : 0 ; 
    // Always 

    // Module instantiation
    // Normalization of edge functions 
    // ee0 /= (glm::abs(ee0.x) + glm::abs(ee0.y));
    // ee1 /= (glm::abs(ee1.x) + glm::abs(ee1.y));
    // ee2 /= (glm::abs(ee2.x) + glm::abs(ee2.y));  
    // Normalization end 


    // TR and TA calculations 
    wire [43:0] w_corner_offsets [3:0]; 
    assign w_corner_offsets[0] = 44'd0; //{ 0.f, 0.f}, // LL (Xy)
    assign w_corner_offsets[1] = {1'b0, 5'b10011 , 16'h8000, 22'd0};//{ TILE_SIZE, 0.f },            /LR
    assign w_corner_offsets[2] = {22'd0 ,1'b0, 5'b10011 , 16'h8000 };//{ 0.f, TILE_SIZE },        /UL
    assign w_corner_offsets[3] = {1'b0, 5'b10011 , 16'h8000,1'b0, 5'b10011 , 16'h8000};//{ TILE_SIZE , TILE_SIZE} // UR
    
    // offsets 
    /*{ 0.f, 0.f},                                            // LL
    { TILE_SIZE, 0.f },                     // LR
    { 0.f, TILE_SIZE },                     // UL
    { TILE_SIZE , TILE_SIZE} // UR
    };*/ 
    /*const uint8_t edge0TRCorner = (ee0.y >= 0.f) ? ((ee0.x >= 0.f) ? 3u : 2u) : (ee0.x >= 0.f) ? 1u : 0u; [ sign bit chck ]
    const uint8_t edge1TRCorner = (ee1.y >= 0.f) ? ((ee1.x >= 0.f) ? 3u : 2u) : (ee1.x >= 0.f) ? 1u : 0u;
    const uint8_t edge2TRCorner = (ee2.y >= 0.f) ? ((ee2.x >= 0.f) ? 3u : 2u) : (ee2.x >= 0.f) ? 1u : 0u;
    // TA corner is the one diagonal from TR corner calculated above    
    const uint8_t edge0TACorner = 3u - edge0TRCorner;
    const uint8_t edge1TACorner = 3u - edge1TRCorner;
    const uint8_t edge2TACorner = 3u - edge2TRCorner;*/ 
    assign w_e0_tr = (!r_ee0_b[21]) ? ((!r_ee0_a) ? 3 : 2) : ((!r_ee0_a) ?1 : 0) ;
    assign w_e1_tr = (!r_ee1_b[21]) ? ((!r_ee1_a) ? 3 : 2) : ((!r_ee1_a) ?1 : 0) ;
    assign w_e2_tr = (!r_ee2_b[21]) ? ((!r_ee2_a) ? 3 : 2) : ((!r_ee2_a) ?1 : 0) ;
    assign w_e0_ta = 3 - w_e0_tr; 
    assign w_e1_ta = 3 - w_e1_tr; 
    assign w_e2_ta = 3 - w_e2_tr; 

    // calculate initial edge functions 
    // const float edgeFunc0 = ee0.z + ((ee0.x * tilePosx (min tile position of LL pixel)) + (ee0.y * tilePosY));
    // const float edgeFunc1 = ee1.z + ((ee1.x * tilePosX) + (ee1.y * tilePosY));
    // const float edgeFunc2 = ee2.z + ((ee2.x * tilePosX) + (ee2.y * tilePosY));
    
    // traverse the tiling
    // While tx is within mintile x and maxtile x 
    // while ty is within mintile y and maxtile y  


    always @(posedge clk) begin
        // check if within range (r_tx <=max_tile , r<ty <= max_y tile)
        case (r_state)
            s_IDLE: begin 
                if (i_en && i_valid)begin 
                    r_state <= s_norm_add; 
                    r_simd_opcode <= op_add; 
                    r_tx_counter <= 0 ; 
                    r_ty_counter <= 0 ; 
                    r_tx <= i_min_x;
                    r_ty <= i_min_y;
                end
            end
            s_norm_add: begin 
                if (w_simd_valid) begin 
                    r_ee0_c <= w_simd_out[4*22 -1: 3*22]; 
                    r_ee1_c <= w_simd_out[3*22 -1: 2*22]; 
                    r_ee2_c <= w_simd_out[2*22 -1: 1*22];
                    r_state <= s_norm_rcp; 
                    r_simd_opcode <= op_rcp; 
                    // set opcode for next 
                end
            end
            s_norm_rcp: begin 
                if(w_simd_valid) begin 
                    r_ee0_c <= w_simd_out[4*22 -1: 3*22]; 
                    r_ee1_c <= w_simd_out[3*22 -1: 2*22]; 
                    r_ee2_c <= w_simd_out[2*22 -1: 1*22];
                    r_state <= s_norm_mul_0; 
                    r_simd_opcode <= op_mul; 
                end
            end
            s_norm_mul_0    : begin 
                if(w_simd_valid) begin 
                    r_ee0_a <= w_simd_out[4*22 -1: 3*22]; 
                    r_ee0_b <= w_simd_out[3*22 -1: 2*22]; 
                    r_ee0_c <= w_simd_out[2*22 -1: 1*22];
                    r_ee1_a <= w_simd_out[21:0];
                    r_state <= s_norm_mul_1; 
                end
            end
            s_norm_mul_1    : begin 
                if(w_simd_valid) begin 
                    r_ee1_b <= w_simd_out[4*22 -1: 3*22]; 
                    r_ee1_c <= w_simd_out[3*22 -1: 2*22]; 
                    r_ee2_a <= w_simd_out[2*22 -1: 1*22];
                    r_ee2_b <= w_simd_out[21:0];
                    r_state <= s_norm_mul_2; 
                end
            end
            s_norm_mul_2    : begin 
                if(w_simd_valid) begin 
                    r_ee2_c <= w_simd_out[4*22 -1: 3*22]; 
                    r_state <= s_efunc_mul_0; 
                end
            end
            s_efunc_mul_0   : begin 
                if(w_simd_valid) begin 
                    r_state <= s_efunc_red_0 ; 
                    r_simd_opcode <= op_reduce_add ; 
                end
            end
            s_efunc_red_0   : begin 
                if(w_simd_valid) begin 
                    r_e0_func <= w_simd_out[4*22 -1: 3*22]; 
                    r_state <= s_efunc_mul_1; 
                    r_simd_opcode <= op_mul; 
                end
            end
            s_efunc_mul_1   : begin 
                if(w_simd_valid) begin 
                    r_state <= s_efunc_red_1 ; 
                    r_simd_opcode <= op_reduce_add ; 
                end
            end
            s_efunc_red_1   : begin 
                if(w_simd_valid) begin 
                    r_e1_func <= w_simd_out[4*22 -1: 3*22]; 
                    r_state <= s_efunc_mul_1; 
                    r_simd_opcode <= op_mul; 
                end

            end
            s_efunc_mul_2   : begin 
                if(w_simd_valid) begin 
                    r_e2_func <= w_simd_out[4*22 -1: 3*22]; 
                    r_state <= s_efunc_red_2; 
                    r_simd_opcode <= op_reduce_add ; 
                end
            end
            s_efunc_red_2   : begin 
                if(w_simd_valid) begin 
                    r_e2_func <= w_simd_out[4*22 -1: 3*22]; 
                    r_state <= s_efunc_tr_add_0; 
                    r_simd_opcode <= op_add;  
                end
            end
            s_efunc_tr_add_0 : begin 
                // if done then 
                if (w_simd_valid) begin 
                    r_intermediate_x <= w_simd_out[4*22-1:3*22]; 
                    r_intermediate_y <= w_simd_out[3*22-1:2*22]; 
                    r_state <= s_efunc_tr_mul_0; 
                    r_simd_opcode <= op_mul ;
                end
            end
            s_efunc_tr_mul_0 : begin 
                if (w_simd_valid) begin 
                    r_state <= s_efunc_tr_red_0; 
                    r_simd_opcode <= op_reduce_add ;
                end
            end
            s_efunc_tr_red_0 : begin 
                if (w_simd_valid) begin 
                    // check if it's less than 0 , if it is discard and restart(increase r_x or r_y)
                    if (w_simd_out[4*22-1]) begin 
                        // less than one 
                        // discard
                        // update tx, ty with tile_size 
                        r_state <= s_tile_step ;
                        r_simd_opcode <= op_add ;
                    end else begin 
                        r_state <= s_efunc_tr_add_1; 
                        r_simd_opcode <= op_add ;
                    end
                end
            end
            s_efunc_tr_add_1 : begin 
                if (w_simd_valid) begin 
                    r_intermediate_x <= w_simd_out[4*22-1:3*22]; 
                    r_intermediate_y <= w_simd_out[3*22-1:2*22]; 
                    r_state <= s_efunc_tr_mul_1; 
                    
                    r_simd_opcode <= op_mul ;
                end
            end
            s_efunc_tr_mul_1: begin 
                if (w_simd_valid) begin 
                    r_state <= s_efunc_tr_red_1; 
                    r_simd_opcode <= op_reduce_add ;
                end
            end
            s_efunc_tr_red_1: begin 
                // check if it's less than 0 , if it is discard and restart(increase r_x or r_y)
                    if (w_simd_out[4*22-1]) begin 
                        // less than one 
                        // discard
                        // update tx, ty with tile_size 
                        r_state <= s_tile_step ;
                        r_simd_opcode <= op_add ;
                    end else begin 
                        r_state <= s_efunc_tr_add_2; 
                        r_simd_opcode <= op_add ;
                    end
                
            end
            s_efunc_tr_add_2 : begin 
                if (w_simd_valid) begin 
                    r_intermediate_x <= w_simd_out[4*22-1:3*22]; 
                    r_intermediate_y <= w_simd_out[3*22-1:2*22]; 
                    r_state <= s_efunc_tr_mul_2; 
                    r_simd_opcode <= op_mul ;
                end
            end
            s_efunc_tr_mul_2: begin 
                if (w_simd_valid) begin 
                    r_state <= s_efunc_tr_red_2; 
                    r_simd_opcode <= op_reduce_add ;
                end
            end

            s_efunc_tr_red_2: begin 
                if (w_simd_out[4*22-1]) begin 
                    // less than one 
                        // discard
                        // update tx, ty with tile_size 
                        r_state <= s_tile_step ;
                        r_simd_opcode <= op_add ;

                end else begin 
                    r_state <= s_efunc_ta_add_0; 
                    r_simd_opcode <= op_add ;
                end
            end
            s_efunc_ta_add_0: begin 
                if (w_simd_valid) begin 
                    r_intermediate_x <= w_simd_out[4*22-1:3*22]; 
                    r_intermediate_y <= w_simd_out[3*22-1:2*22]; 
                    r_state <= s_efunc_ta_mul_0; 
                    r_simd_opcode <= op_mul ;
                end
            end
            s_efunc_ta_mul_0: begin 
                if (w_simd_valid) begin 
                    r_state <= s_efunc_ta_red_0; 
                    r_simd_opcode <= op_reduce_add ;
                end
            end
            s_efunc_ta_red_0: begin 
                if (w_simd_out[4*22-1]) begin 
                    // if one is negative then send to raster + and restart
                    r_state <= s_raster_out ;
                end else begin 
                    r_state <= s_efunc_ta_add_1; 
                    r_simd_opcode <= op_add ;
                end
            end
            s_efunc_ta_add_1: begin 
                if (w_simd_valid) begin 
                    r_intermediate_x <= w_simd_out[4*22-1:3*22]; 
                    r_intermediate_y <= w_simd_out[3*22-1:2*22]; 
                    r_state <= s_efunc_ta_mul_1; 
                    r_simd_opcode <= op_mul ;
                end
            end
            s_efunc_ta_mul_1: begin 
                if (w_simd_valid) begin 
                    r_state <= s_efunc_ta_red_1; 
                    r_simd_opcode <= op_reduce_add ;
                end
            end

            s_efunc_ta_red_1: begin 
                if (w_simd_out[4*22-1]) begin 
                    // if one is negative then send to raster + and restart
                    r_state <= s_raster_out ;
                end else begin 
                    r_state <= s_efunc_ta_add_2; 
                    r_simd_opcode <= op_add ;
                end
            end
            s_efunc_ta_add_2: begin 
                if (w_simd_valid) begin 
                    r_intermediate_x <= w_simd_out[4*22-1:3*22]; 
                    r_intermediate_y <= w_simd_out[3*22-1:2*22]; 
                    r_state <= s_efunc_ta_mul_2; 
                    r_simd_opcode <= op_mul ;
                end
            end
            s_efunc_ta_mul_2: begin 
                    if (w_simd_valid) begin 
                    r_state <= s_efunc_ta_red_2; 
                    r_simd_opcode <= op_reduce_add ;
                end
            end

            s_efunc_ta_red_2: begin 
                if (w_simd_out[4*22-1]) begin 
                    // if one is negative then send to raster + and restart
                    r_state <= s_raster_out ;
                end else begin 
                    r_state <= s_shader_out; // full tile size
                end
            end
            s_tile_step: begin 
                if (r_ty_counter < i_step_y || r_tx_counter < i_step_x) begin 
                    if(w_simd_valid) begin 
                        r_state <= s_efunc_tr_add_0; 
                        if (r_tx_counter < i_step_x) begin 
                            // lod simd output which adds tile size to r_tx 
                            r_tx <= w_simd_out[4*22-1:3*22]; 
                        end else begin 
                            // load simd output to ty and reset r_tx
                            r_tx <= i_min_x ; 
                            r_ty <= w_simd_out[3*22-1:2*22]; 
                        end
                    end
                end
                else begin 
                    r_state <= s_IDLE; 
                    r_tx_counter <= 0 ; 
                    r_ty_counter <= 0 ; 
                end
            end
            s_raster_out    : begin 
                // write to register in here if it's idle, otherwise stall here 
                // stall and then go to tile_step 
                if (i_busy_r)  
                    r_state <= s_raster_out ; 
                else if (i_ack_r) begin // recieved the tile x and y 
                    r_state <= s_tile_step ; 
                end
            end
            s_shader_out    : begin 
                // queue in to fifo of the fragment shader . queue in 
                if (i_full)
                    r_state <= s_shader_out; 
                else 
                    r_state <= s_tile_step ;
            end
        endcase 
        
    end

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