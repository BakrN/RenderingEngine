//~ `New testbench
`timescale  1ns / 1ps

module tb_ren_rasterizer ; 

// ren_rasterizer Parameters

parameter PERIOD  = 10   ;



// ren_rasterizer Inputs
logic clk                            = 0 ;
logic i_en                           = 0 ;
logic rstn                           = 0 ;
logic i_empty                              = 0 ;
logic i_valid                        = 0 ; 
logic i_busy_r                       = 0 ;
edge_t i_e0_edge                     = 0 ;  
edge_t i_e1_edge                     = 0 ;
edge_t i_e2_edge                     = 0 ;
tile_t i_tile                        = 0 ;

// ren_rasterizer Outputs
tile_t o_tile                        ;
wire  o_fifo_read                          ;
wire  o_busy                               ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end


ren_rasterizer  u_ren_rasterizer (
    .clk               ( clk          ),
    .i_en              ( i_en         ),
    .rstn              ( rstn         ),
    .i_empty                 ( i_empty            ),
    .i_valid           ( i_valid      ),
    .i_busy_r          ( i_busy_r     ),
    .i_e0_edge        ( i_e0_edge   ),
    .i_e1_edge        ( i_e1_edge   ),
    .i_e2_edge        ( i_e2_edge   ),
    .i_tile           ( i_tile      ),

    .o_tile           ( o_tile      ),
    .o_fifo_read             ( o_fifo_read        ),  
    .o_busy                  ( o_busy             )
);
initial
begin
    rstn = 1 ; 
    #(2*PERIOD); 
    rstn = 0; 
    i_en = 1 ; 
    #(2*PERIOD);
    rstn=  1 ; 
    i_tile.x = 0 ; 
    i_tile.y = 0 ;
    i_tile.size = `fpTILE_SIZE; 

    $finish; 
end

endmodule