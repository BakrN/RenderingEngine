//~ `New testbench
`timescale  1ns / 1ps
`include "rtl/ren_params.v"
//`include "ren_params.v" // vivado 
module tb_ren_setup;

// ren_setup Parameters
parameter PERIOD  = 10;


// ren_setup Inputs
reg   clk                                  = 0 ;
reg   rstn                                 = 1 ;
reg   i_en                                 = 0 ;
reg   i_busy                               = 0 ;
reg   [21:0]  i_vtx0_x                     = 0 ;
reg   [21:0]  i_vtx0_y                     = 0 ;
reg   [21:0]  i_vtx0_z                     = 0 ;
reg   [21:0]  i_vtx0_cr                    = 0 ;
reg   [21:0]  i_vtx0_cg                    = 0 ;
reg   [21:0]  i_vtx0_cb                    = 0 ;
reg   [21:0]  i_vtx1_x                     = 0 ;
reg   [21:0]  i_vtx1_y                     = 0 ;
reg   [21:0]  i_vtx1_z                     = 0 ;
reg   [21:0]  i_vtx1_cr                    = 0 ;
reg   [21:0]  i_vtx1_cg                    = 0 ;
reg   [21:0]  i_vtx1_cb                    = 0 ;
reg   [21:0]  i_vtx2_x                     = 0 ;
reg   [22:0]  i_vtx2_y                     = 0 ;
reg   [21:0]  i_vtx2_z                     = 0 ;
reg   [21:0]  i_vtx2_cr                    = 0 ;
reg   [21:0]  i_vtx2_cg                    = 0 ;
reg   [21:0]  i_vtx2_cb                    = 0 ;

// ren_setup Outputs
wire  [21:0]  o_vtx0_x                     ;
wire  [21:0]  o_vtx0_y                     ;
wire  [21:0]  o_vtx0_z                     ;
wire  [21:0]  o_vtx0_cr                    ;
wire  [21:0]  o_vtx0_cg                    ;
wire  [21:0]  o_vtx0_cb                    ;
wire  [21:0]  o_vtx1_x                     ;
wire  [21:0]  o_vtx1_y                     ;
wire  [21:0]  o_vtx1_z                     ;
wire  [21:0]  o_vtx1_cr                    ;
wire  [21:0]  o_vtx1_cg                    ;
wire  [21:0]  o_vtx1_cb                    ;
wire  [21:0]  o_vtx2_x                     ;
wire  [21:0]  o_vtx2_y                     ;
wire  [21:0]  o_vtx2_z                     ;
wire  [21:0]  o_vtx2_cr                    ;
wire  [21:0]  o_vtx2_cg                    ;
wire  [21:0]  o_vtx2_cb                    ;
wire  [21:0]  o_e0_a                       ;
wire  [21:0]  o_e0_b                       ;
wire  [21:0]  o_e0_c                       ;
wire  [21:0]  o_e1_a                       ;
wire  [21:0]  o_e1_b                       ;
wire  [21:0]  o_e1_c                       ;
wire  [21:0]  o_e2_a                       ;
wire  [21:0]  o_e2_b                       ;
wire  [21:0]  o_e2_c                       ;
wire  [21:0]  o_min_x                      ;
wire  [21:0]  o_min_y                      ;
wire  [22*3-1:0]  o_cr_coeff               ;
wire  [22*3-1:0]  o_cg_coeff               ;
wire  [22*3-1:0]  o_cb_coeff               ;
wire  [22*3-1:0]  o_z_coeff                ;
wire  [15:0]  o_steps_x                    ;
wire  [15:0]  o_steps_y                    ;
wire  o_valid                              ;
wire  o_idle                               ;
wire  o_shader_valid                       ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end



ren_setup  u_ren_setup (
    .clk                     ( clk                        ),
    .rstn                    ( rstn                       ),
    .i_en                    ( i_en                       ),
    .i_busy                  ( i_busy                     ),
    .i_vtx0_x                ( i_vtx0_x        [21:0]     ),
    .i_vtx0_y                ( i_vtx0_y        [21:0]     ),
    .i_vtx0_z                ( i_vtx0_z        [21:0]     ),
    .i_vtx0_cr               ( i_vtx0_cr       [21:0]     ),
    .i_vtx0_cg               ( i_vtx0_cg       [21:0]     ),
    .i_vtx0_cb               ( i_vtx0_cb       [21:0]     ),
    .i_vtx1_x                ( i_vtx1_x        [21:0]     ),
    .i_vtx1_y                ( i_vtx1_y        [21:0]     ),
    .i_vtx1_z                ( i_vtx1_z        [21:0]     ),
    .i_vtx1_cr               ( i_vtx1_cr       [21:0]     ),
    .i_vtx1_cg               ( i_vtx1_cg       [21:0]     ),
    .i_vtx1_cb               ( i_vtx1_cb       [21:0]     ),
    .i_vtx2_x                ( i_vtx2_x        [21:0]     ),
    .i_vtx2_y                ( i_vtx2_y        [22:0]     ),
    .i_vtx2_z                ( i_vtx2_z        [21:0]     ),
    .i_vtx2_cr               ( i_vtx2_cr       [21:0]     ),
    .i_vtx2_cg               ( i_vtx2_cg       [21:0]     ),
    .i_vtx2_cb               ( i_vtx2_cb       [21:0]     ),

    .o_vtx0_x                ( o_vtx0_x        [21:0]     ),
    .o_vtx0_y                ( o_vtx0_y        [21:0]     ),
    .o_vtx0_z                ( o_vtx0_z        [21:0]     ),
    .o_vtx0_cr               ( o_vtx0_cr       [21:0]     ),
    .o_vtx0_cg               ( o_vtx0_cg       [21:0]     ),
    .o_vtx0_cb               ( o_vtx0_cb       [21:0]     ),
    .o_vtx1_x                ( o_vtx1_x        [21:0]     ),
    .o_vtx1_y                ( o_vtx1_y        [21:0]     ),
    .o_vtx1_z                ( o_vtx1_z        [21:0]     ),
    .o_vtx1_cr               ( o_vtx1_cr       [21:0]     ),
    .o_vtx1_cg               ( o_vtx1_cg       [21:0]     ),
    .o_vtx1_cb               ( o_vtx1_cb       [21:0]     ),
    .o_vtx2_x                ( o_vtx2_x        [21:0]     ),
    .o_vtx2_y                ( o_vtx2_y        [21:0]     ),
    .o_vtx2_z                ( o_vtx2_z        [21:0]     ),
    .o_vtx2_cr               ( o_vtx2_cr       [21:0]     ),
    .o_vtx2_cg               ( o_vtx2_cg       [21:0]     ),
    .o_vtx2_cb               ( o_vtx2_cb       [21:0]     ),
    .o_e0_a                  ( o_e0_a          [21:0]     ),
    .o_e0_b                  ( o_e0_b          [21:0]     ),
    .o_e0_c                  ( o_e0_c          [21:0]     ),
    .o_e1_a                  ( o_e1_a          [21:0]     ),
    .o_e1_b                  ( o_e1_b          [21:0]     ),
    .o_e1_c                  ( o_e1_c          [21:0]     ),
    .o_e2_a                  ( o_e2_a          [21:0]     ),
    .o_e2_b                  ( o_e2_b          [21:0]     ),
    .o_e2_c                  ( o_e2_c          [21:0]     ),
    .o_min_x                 ( o_min_x         [21:0]     ),
    .o_min_y                 ( o_min_y         [21:0]     ),
    .o_cr_coeff              ( o_cr_coeff      [22*3-1:0] ),
    .o_cg_coeff              ( o_cg_coeff      [22*3-1:0] ),
    .o_cb_coeff              ( o_cb_coeff      [22*3-1:0] ),
    .o_z_coeff               ( o_z_coeff       [22*3-1:0] ),
    .o_steps_x               ( o_steps_x       [15:0]     ),
    .o_steps_y               ( o_steps_y       [15:0]     ),
    .o_valid                 ( o_valid                    ),
    .o_idle                  ( o_idle                     ),
    .o_shader_valid          ( o_shader_valid             )
);

initial
begin

    i_en  = 1 ; 
    i_busy = 0 ; 
    rstn =0  ;
    #PERIOD;
    rstn =1  ;  
    i_vtx0_x = `fpONE; 
    i_vtx0_y = `fpHALF; 
    i_vtx0_z = 0; 
    
    i_vtx1_x = `fpONE;  // 1.0f
    i_vtx1_y = `fpHALF; 
    i_vtx1_z = 0; 
    
    i_vtx2_x = `fpTWO; 
    i_vtx2_y = `fpFOUR; 
    i_vtx2_z = 0; 
    
    i_vtx0_cr = 0 ; 
    i_vtx0_cg = 0 ; 
    i_vtx0_cb = 0 ; 
    i_vtx1_cr = 0 ; 
    i_vtx1_cg = 0 ; 
    i_vtx1_cb = 0 ; 
    i_vtx2_cr = 0 ; 
    i_vtx2_cg = 0 ; 
    i_vtx2_cb = 0 ; 
    #(PERIOD*120)

    $finish;
end

endmodule
