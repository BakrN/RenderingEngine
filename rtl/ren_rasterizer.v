`timescale 1ns / 1ps
module ren_rasterizer(
        clk         , 
        i_en        , 
        rstn        , 
        i_valid     , 
        i_busy_r    , 
        i_full      , 
        i_e0_a      , 
        i_e0_b      , 
        i_e0_c      , 
        i_e1_a      , 
        i_e1_b      , 
        i_e1_c      , 
        i_e2_a      , 
        i_e2_b      , 
        i_e2_c      , 
        i_min_x     , 
        i_max_x     , 
        o_tile_x    , 
        o_tile_y    , 
        o_tile_size , 
        o_busy      
);
    input   clk;
    input   i_en;
    input   rstn;
    input   i_valid;
    input   i_busy_r;
    input   i_full;
    input   [21:0]  i_e0_a;
    input   [21:0]  i_e0_b;
    input   [21:0]  i_e0_c;
    input   [21:0]  i_e1_a;
    input   [21:0]  i_e1_b;
    input   [21:0]  i_e1_c;
    input   [21:0]  i_e2_a;
    input   [21:0]  i_e2_b;
    input   [21:0]  i_e2_c;
    input   [21:0]  i_min_x;
    input   [21:0]  i_max_x;
    output  [21:0]  o_tile_x;
    output  [21:0]  o_tile_y;
    output  o_tile_size;
    output  o_busy;
    
endmodule
