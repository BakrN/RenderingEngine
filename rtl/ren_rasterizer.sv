`timescale 1ns / 1ps
`include "ren_defines.svh"

module ren_rasterizer(
        clk         , 
        i_en        , 
        rstn        , 
        i_valid     , 
        i_busy_r    , 
        
        i_e0_edge   , 
        i_e1_edge   , 
        i_e2_edge   ,  
        
        // fifo 
        i_empty     , 
        i_tile      ,  
        o_fifo_read , 
        // tile  
        i_tile , 
        o_tile ,
        o_busy      
); 
    // Get a binner module but 
    input  logic clk;
    input  logic i_en;
    input  logic rstn; 
    input i_empty; 
    input  logic i_valid;
    input  logic i_busy_r;
    input  logic i_full;
    input  edge_t i_e0_edge; 
    input  edge_t i_e1_edge;  
    input  edge_t i_e2_edge; 
    input  tile_t i_tile ; 
    output fp22_t o_tile_x;
    output fp22_t o_tile_y;
    output tile_t o_tile ; 
    output  o_tile_size;
    output  o_fifo_read   ; 
    output  o_busy;
    
    localparam s_IDLE = 0 ; 
    localparam s_fetch_tile = 1; 
    localparam s_binning    = 2 ;
    
    logic [1:0] r_index ;
    logic [2:0] r_state;   
    tile_t r_tile; 
    fp22_t r_intermediate; // saves r_ty + y
    // adder io 
    logic w_adder_s  ; 
    logic w_adder_en ; 
    fp22_t w_adder_a  ;  
    fp22_t w_adder_b  ; 
    fp22_t w_adder_out ; 
     
    /* -------------------------------------------------------------------------- */
    /*                                  Binner IO                                 */
    /* -------------------------------------------------------------------------- */
    wire w_bin_busy; 
    /* -------------------------------------------------------------------------- */
    /*                                   Assign                                   */
    /* -------------------------------------------------------------------------- */
    assign o_fifo_read = r_state <= s_fetch_tile;  
    assign w_adder_a = (r_index==1) ? i_tile.y[21:0] :i_tile.x[21:0] ; 
    assign w_adder_b = get_fp_2(r_tile.size);  // fp/2 
    /* -------------------------------------------------------------------------- */
    /*                                Always Blocks                               */
    /* -------------------------------------------------------------------------- */
    always_ff @(posedge clk or negedge rstn) begin  
        if (!rstn)  begin
            r_state <= s_IDLE; 
            r_index <= 0 ; 
        end
        else begin 
            case (r_state)
                s_IDLE : begin 
                    r_index <=  0 ;  
                    if(~i_empty && ~w_bin_busy) begin //  if not empty and binner not busy 
                        r_state <= s_fetch_tile; 
                    end
                end 
                s_fetch_tile : begin 
                    r_state <= s_binning; 
                    r_tile  <= i_tile   ; 
                end 
                s_binning : begin 
                    r_state <= s_IDLE; 
                end
            endcase 
        end
    end
    

   
    /* -------------------------------------------------------------------------- */
    /*                            Module Instantiation                            */
    /* -------------------------------------------------------------------------- */
    fp_add  u_fp_add (
        .clk                     ( clk       ),
        .i_en                    ( w_adder_en),
        .i_a                     ( w_adder_a ),
        .i_b                     ( w_adder_b ),
        .i_adsb                  ( w_adder_s ),

        .o_c                     ( w_adder_out)
    );

    function get_fp_2; // assums tile size is to the power of 2
    input [31:0] number ; 

        begin 
             logic [63:0] index; 
            assign index = ((number & -number) * 64'h077CB5310) >> 27; 
            case (index)
                0: begin 
                    get_fp_2 = `fpONE ; 
                    // 0 
                end
                1: begin 
                    get_fp_2= `fpONE; 
                end
                3: begin 
                    get_fp_2 = `fpTWO;  
                end
                5: begin  
                    get_fp_2 = {1'b0 , 5'd28, 16'h8000}; 
                    //14;  
                end
                7: begin 
                    get_fp_2 = {1'b0 , 5'd17, 16'h8000}; 
                    //3
                end
                11: begin 
                    get_fp_2 = {1'b0 , 5'd29, 16'h8000}; 
                    //15
                end
                14: begin 
                    get_fp_2 = {1'b0 , 5'd18, 16'h8000}; 
                    //4
                end
                15: begin 
                    get_fp_2 = {1'b0 , 5'd22, 16'h8000}; 
                    //8
                end
                18: begin 
                    get_fp_2 = {1'b0 , 5'd27, 16'h8000}; 
                    //13
                end
                23: begin 
                    get_fp_2 = {1'b0 , 5'd21, 16'h8000}; 
                    //7
                end
                25: begin 
                    get_fp_2 = {1'b0 , 5'd26, 16'h8000}; 
                    //12
                end
                27: begin 
                    get_fp_2 = {1'b0 , 5'd20, 16'h8000}; 
                    //6
                end
                28: begin 
                    get_fp_2 = {1'b0 , 5'd25, 16'h8000}; 
                    //11
                end
                29: begin 
                    get_fp_2 = {1'b0 , 5'd19, 16'h8000}; 
                     //5
                end
                30: begin 
                    get_fp_2 = {1'b0 , 5'd24, 16'h8000}; 
                    // 10
                end
                31: begin 
                    get_fp_2 = {1'b0 , 5'd23, 16'h8000}; 
                    //9
                end
                default: begin 
                    get_fp_2 = `fpONE; 
                end 
            endcase
        end
   
       /*bit twiddling: http://graphics.stanford.edu/~seander/bithacks.html
   static const int MultiplyDeBruijnBitPosition[32] = 
    {
    0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8, 
    31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9
    };*/ 
    endfunction 

endmodule

/* How algorithm works:  
1 - start off with a width of 4 
2 - recursively through top blocks and just add them to raster queue
3 - 
4 - 
5 - 
6 - 
7 -
8 -
9 - 

