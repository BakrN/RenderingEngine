module ren_shader_queue(
    clk, 
    rst_n, 
    // fifo control 

    // binner 
    i_tile_x_b , 
    i_tile_y_b , 
    i_valid_b, 
    // resterizer 
    i_tile_x_r , 
    i_tile_y_r , 
    i_tile_size_r , // int 
    i_valid_r, 
    o_empty , 
    o_full 
); 
    // 16 x 16 for (binner)
    input clk; 
    input rst_n ; 
    input i_tile_x_b ; 
    input i_tile_y_b ; 
    input i_valid_b ; 
    input i_tile_x_r ; 
    input i_tile_y_r ;  
    input i_tile_size_r; 
    input i_valid_r  ;
    output o_empty   ; 
    output o_full    ; 
    output o_tile_x; // floored 
    output o_tile_y; // floored
    output tile_size; // int 



endmodule
