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
logic [5:0] prev_state; 

    // testing tile stepping 
    //always_ff @(u_ren_binner.r_state) begin
    //    
    //    if (u_ren_binner.r_state==32)begin  
    //        if(prev_state == u_ren_binner.s_efunc_tr_red_0)
    //            $display("print(f\"tile_x:  {get_dec_from_fp22('%b')},tile_y: {get_dec_from_fp22('%b')}  eTR0: {get_dec_from_fp22('%b')}\")", u_ren_binner.r_tx, u_ren_binner.r_ty, u_ren_binner.u_FP_SIMD.o_reg_out[87:3*22]);
    //        if(prev_state == u_ren_binner.s_efunc_tr_red_1)
    //            $display("print(f\"tile_x:  {get_dec_from_fp22('%b')},tile_y: {get_dec_from_fp22('%b')}  eTR1 {get_dec_from_fp22('%b')}\")",  u_ren_binner.r_tx, u_ren_binner.r_ty, u_ren_binner.u_FP_SIMD.o_reg_out[87:3*22]);
    //        if(prev_state == u_ren_binner.s_efunc_tr_red_2)
    //            $display("print(f\"tile_x:  {get_dec_from_fp22('%b')},tile_y: {get_dec_from_fp22('%b')}   eTR2: {get_dec_from_fp22('%b')}\")",u_ren_binner.r_tx, u_ren_binner.r_ty, u_ren_binner.u_FP_SIMD.o_reg_out[87:3*22] );
    //    end
    //    else 
    //        prev_state  <= u_ren_binner.r_state;
    //end 
    // get accepted tile
    //always_ff @(posedge u_ren_binner.o_fifo_write) begin
    //    $display("f\"ACCEPT tile_x:  {get_dec_from_fp22('%b')},tile_y: {get_dec_from_fp22('%b')}  eTR0: {get_dec_from_fp22('%b')}\"", u_ren_binner.r_tx, u_ren_binner.r_ty, u_ren_binner.u_FP_SIMD.o_reg_out[87:3*22]);
    //end
    // get overlap tiles
    //always_ff @(posedge u_ren_binner.w_raster_fifo_write) begin
    //    $display("f\"OVERLAP tile_x:  {get_dec_from_fp22('%b')},tile_y: {get_dec_from_fp22('%b')}  eTR0: {get_dec_from_fp22('%b')}\"", u_ren_binner.r_tx, u_ren_binner.r_ty, u_ren_binner.u_FP_SIMD.o_reg_out[87:3*22]);
    //end
    
    initial begin 
    $monitor("print(f\"tile_x: {get_dec_from_fp22('%b')} , tile_y: {get_dec_from_fp22('%b')}\")", u_ren_binner.r_tx, u_ren_binner.r_ty); 
    end
initial
begin
    rstn = 1 ;
    #PERIOD ; 
    rstn = 0 ; 
    #(PERIOD*2) ; 
    rstn =1 ; 
    i_en = 1; 
    i_valid = 1; 
    
    
    

    i_e1.a = 22'b0101101101100100010010; 
    i_e2.a = 22'b1101101001000001001101; 
    i_e0.a = 22'b1101011001000110001011;

    i_e1.b = 22'b1101101110111001000101; 
    i_e2.b = 22'b0101111000111110001000; 
    i_e0.b = 22'b1101001100001100110000; 
                                       ; 
    i_e1.c = 22'b1111101111001101010101; 
    i_e2.c = 22'b0111101000011111101001; 
    i_e0.c = 22'b0111101101100010001000; 

    i_min_x = 22'b0101111010100000000000; 
    i_min_y = 22'b0101001100000000000000 ; 
    i_step_x = 19 ; 
    i_step_y = 14 ; 
    i_tile_size = 22'b0100111000000000000000; //16 
    #(PERIOD*100)
    i_en = 0 ; 

    $display("ee0 = Vec3f (get_dec_from_fp22('%b'),get_dec_from_fp22('%b'),get_dec_from_fp22('%b')", u_ren_binner.r_ee0.a,u_ren_binner.r_ee0.b, u_ren_binner.r_ee0.c );
    $display("ee1 = Vec3f (get_dec_from_fp22('%b'),get_dec_from_fp22('%b'),get_dec_from_fp22('%b')", u_ren_binner.r_ee1.a,u_ren_binner.r_ee1.b, u_ren_binner.r_ee1.c );
    $display("ee2 = Vec3f (get_dec_from_fp22('%b'),get_dec_from_fp22('%b'),get_dec_from_fp22('%b')", u_ren_binner.r_ee2.a,u_ren_binner.r_ee2.b, u_ren_binner.r_ee2.c );
    #(PERIOD*100 + 82*1000)
    $finish;
end

endmodule