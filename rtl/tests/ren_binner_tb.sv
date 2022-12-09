//~ `New testbench
`timescale  1ns / 1ps
module tb_ren_binner;

// ren_binner Parameters
parameter PERIOD  = 10;


// ren_binner Inputs
logic clk                            = 0 ;
logic i_en                           = 0 ;
logic rstn                           = 0 ;
logic i_valid                        = 0 ;
logic i_fifo_full_r                  = 0 ;
logic i_fifo_full_s                  = 0 ;
edge_t i_e0                          = 0 ;
edge_t i_e1                          = 0 ;
edge_t i_e2                          = 0 ;
fp22_t i_min_x                       = 0 ;
fp22_t i_min_y                       = 0 ;
reg  [15:0]  i_step_x                     = 0 ;
reg  [15:0]  i_step_y                     = 0 ;
fp22_t i_tile_size                   = 0 ;

// ren_binner Outputs
wire  tile_t o_tile                        ;

wire  o_busy                               ;
wire  o_fifo_write                         ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end



ren_binner  u_ren_binner (
    .clk              ( clk                   ),
    .i_en              ( i_en                  ),
    .rstn              ( rstn                  ),
    .i_valid           ( i_valid               ),
    .i_fifo_full_r     ( i_fifo_full_r         ),
    .i_fifo_full_s     ( i_fifo_full_s         ),
    .i_e0             ( i_e0                 ),
    .i_e1             ( i_e1                 ),
    .i_e2             ( i_e2                 ),
    .i_min_x          ( i_min_x              ),
    .i_min_y          ( i_min_y              ),
    .i_step_x                ( i_step_x             [15:0] ),
    .i_step_y                ( i_step_y             [15:0] ),
    .i_tile_size      ( i_tile_size          ),

    .o_tile           ( o_tile               ),
  
    .o_busy                  ( o_busy                      ),
    .o_fifo_write            ( o_fifo_write                )
);

initial
begin
    rstn = 1 ;
    #PERIOD ; 
    rstn = 0 ; 
    #(PERIOD*2) ; 
    rstn =1 ; 
    i_en = 1; 
    i_valid = 1; 
    i_e0.a = 22'b1101101111010000101001; 
    i_e0.b = 22'b1101101111010000101001; 
    i_e0.c = 22'b0111101001111111000011 ; 
    i_e1.a = 22'b1101001011110100111011; 
    i_e2.a = 22'b0101111001000110111100; 
    i_e1.b = 22'b1101101111011010111000; 
    i_e2.b = 22'b1101001000101010111011; 
    i_e1.c = 22'b0111101000101001100011; 
    i_e2.c = 22'b1000001001001001011101; 

    i_min_x = 22'b0101111000100000000000 ; 
    i_min_y = 22'b0101001000000000000000 ; 
    i_step_x = 17 ; 
    i_step_y = 18 ; 
    i_tile_size = 22'b0100111000000000000000 ; 
    #(PERIOD*4)
    i_en = 0 ; 
    #(PERIOD*100)
    $finish;
end

endmodule