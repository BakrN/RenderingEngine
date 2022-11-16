`timescale 1ns / 1ps
// Made By: Abubakr Nada 
// Extracts triangle coefficients & bounding boxes and other info 
// writes to binner queue
// implementing this edge function(from subscript0 to subscript1): a=y0-y1, b=x1-x0 , c= x0*y1-x1*y0
// vertices already sorted by control unit
// Latency = 6 
// TODO add ranking order for on height 
module ren_setup(
        clk, 
        // control 
        rstn , 
        i_en, 
        i_busy, // from fifo 
        //triangle data (TODO could add more data in the future)
        i_vtx0_x , // top 
        i_vtx0_y , 
        i_vtx0_z , 
        i_vtx0_cr, 
        i_vtx0_cg, 
        i_vtx0_cb, 
        i_vtx1_x , // mid
        i_vtx1_y , 
        i_vtx1_z , 
        i_vtx1_cr, 
        i_vtx1_cg, 
        i_vtx1_cb, 
        i_vtx2_x , // bottom
        i_vtx2_y , 
        i_vtx2_z , 
        i_vtx2_cr, 
        i_vtx2_cg, 
        i_vtx2_cb, 
        //outputs 
        // vertex 
        o_vtx0_x , // top 
        o_vtx0_y , 
        o_vtx0_z , 
        o_vtx0_cr, 
        o_vtx0_cg, 
        o_vtx0_cb, 
        o_vtx1_x , // mid
        o_vtx1_y , 
        o_vtx1_z , 
        o_vtx1_cr, 
        o_vtx1_cg, 
        o_vtx1_cb, 
        o_vtx2_x , // bottom
        o_vtx2_y , 
        o_vtx2_z , 
        o_vtx2_cr, 
        o_vtx2_cg, 
        o_vtx2_cb, 
        // triangle info 
        o_e0_a  , // edge 0 top-bottom
        o_e0_b  , 
        o_e0_c  , 

        o_e1_a  , // edge 1 bottom-mid  
        o_e1_b  , 
        o_e1_c  , 

        o_e2_a  , // edge 2 mid-top  
        o_e2_b  , 
        o_e2_c  , 
        o_min_x, // bounding box 
        o_max_x , 
        // control 
        o_valid , 
        o_idle 
);
    // Ports IO 
    input clk  ; 
    input rstn ; 
    input i_en ; 
    input i_busy; 
    input [21:0] i_vtx0_x ; 
    input [21:0] i_vtx0_y ; 
    input [21:0] i_vtx0_z ; 
    input [21:0] i_vtx0_cr; 
    input [21:0] i_vtx0_cg; 
    input [21:0] i_vtx0_cb; 
    input [21:0] i_vtx1_x ; 
    input [21:0] i_vtx1_y ; 
    input [21:0] i_vtx1_z ; 
    input [21:0] i_vtx1_cr; 
    input [21:0] i_vtx1_cg; 
    input [21:0] i_vtx1_cb; 
    input [21:0] i_vtx2_x ; 
    input [22:0] i_vtx2_y ; 
    input [21:0] i_vtx2_z ; 
    input [21:0] i_vtx2_cr; 
    input [21:0] i_vtx2_cg; 
    input [21:0] i_vtx2_cb; 
    output [21:0] o_vtx0_x ; 
    output [21:0] o_vtx0_y ; 
    output [21:0] o_vtx0_z ; 
    output [21:0] o_vtx0_cr; 
    output [21:0] o_vtx0_cg; 
    output [21:0] o_vtx0_cb; 
    output [21:0] o_vtx1_x ; // mid
    output [21:0] o_vtx1_y ; 
    output [21:0] o_vtx1_z ; 
    output [21:0] o_vtx1_cr; 
    output [21:0] o_vtx1_cg; 
    output [21:0] o_vtx1_cb; 
    output [21:0] o_vtx2_x ; // bottom
    output [21:0] o_vtx2_y ; 
    output [21:0] o_vtx2_z ; 
    output [21:0] o_vtx2_cr; 
    output [21:0] o_vtx2_cg; 
    output [21:0] o_vtx2_cb; 
    output [21:0] o_e0_a ;  
    output [21:0] o_e0_b ;   
    output [21:0] o_e0_c ;   
    output [21:0] o_e1_a ;  
    output [21:0] o_e1_b ;   
    output [21:0] o_e1_c ;   
    output [21:0] o_e2_a ;  
    output [21:0] o_e2_b ;   
    output [21:0] o_e2_c ;   
    output [21:0] o_min_x;   
    output [21:0] o_max_x;   
    output o_valid; 
    output o_idle;  
    // Constant
    localparam s_IDLE = 3'd0 ;  
    localparam s_e_a = 3'd1 ;  
    localparam s_e_b = 3'd2 ;  
    localparam s_e_c_0_0 = 3'd3 ;  // multiplication phase 1
    localparam s_e_c_0_1 = 3'd4 ;  // multiplication phase 2
    localparam s_e_c_1 = 3'd5 ;  // reduction (subtraction)
    localparam s_OUT = 3'd6 ;  
    // Wires
    // SIMD
    wire [4*22-1:0] w_simd_in0; 
    wire [4*22-1:0] w_simd_in1; 
    wire [4*22-1:0] w_simd_out; 
    wire w_simd_enable ;
    wire w_simd_valid; 
    wire w_simd_busy; 
    // SIMD END
    wire [21:0] w_e0_c_1 ;
    wire [21:0] w_e0_c_2 ;
    wire [21:0] w_e1_c_1 ;
    wire [21:0] w_e1_c_2 ;
    wire [21:0] w_e2_c_1 ;
    wire [21:0] w_e2_c_2 ;
    // Regs 
    reg [2:0] r_state ;  
    reg [2:0] r_simd_opcode;
    reg [21:0] r_e0_a ;  
    reg [21:0] r_e0_b ;   
    reg [21:0] r_e0_c ;   // will be used for temp storage
    reg [21:0] r_e1_a ;  
    reg [21:0] r_e1_b ;   
    reg [21:0] r_e1_c ;   // will be used for temp storage
    reg [21:0] r_e2_a ;  
    reg [21:0] r_e2_b ;   
    reg [21:0] r_e2_c ; 
    
    // Assign 
    assign w_valid = (r_state==s_OUT) ; // TODO edit this later 
    assign o_max_x= (o_e0_b[21]) ? ((!o_e2_b[21]) ? i_vtx0_x : i_vtx1_x) : ((o_e1_b[21]) ? i_vtx2_x : i_vtx1_x) ; // e0b = vtx2-vtx0, e1b = v1-v2 , e2b = v0-v1 ## // checking sign bit 
    assign o_min_x = (o_e0_b[21]) ? ((!o_e1_b[21]) ? i_vtx2_x : i_vtx1_x) : ((o_e2_b[21]) ? i_vtx0_x : i_vtx1_x) ;
    assign o_idle = (r_state==s_IDLE); 
    // checks 
    //assign o_max_y = (!o_e0_a[21]) ? ((o_e2_a[21]) ? i_vtx0_y : i_vtx1_y) : ((!o_e1_a[21]) ? i_vtx2_y : i_vtx1_y) ; // e0a = vtx0-vtx2, e1a = v2-v1 , e2a = v1-v0 ## // checking sign bit 
    //assign o_min_y = (); 
    // SIMD 
    assign w_simd_enable = (r_state != 0 && r_state != s_OUT) ? 1 : 0 ; 
    assign w_simd_in0 = (r_state == s_e_a) ? {i_vtx0_y , i_vtx2_y , i_vtx1_y, 22'b0} : 
                        ((r_state == s_e_b)? {i_vtx2_x , i_vtx1_x , i_vtx0_x,22'd0} : 
                        ((r_state == s_e_c_0_0) ? {i_vtx0_x , i_vtx2_x , 44'd0} : // mul phase 1 
                        ((r_state==s_e_c_0_1) ? {i_vtx2_x , i_vtx1_x , i_vtx1_x ,i_vtx0_x} :   // mul phase 2
                        {r_e0_c , w_simd_out[4*22-1:3*22] , w_simd_out[2*22-1:1*22] , 22'd0})));  // subtraction
    assign w_simd_in1 = (r_state == s_e_a) ? {i_vtx2_y , i_vtx1_y , i_vtx0_y,22'd0} : 
                        ((r_state == s_e_b)? {i_vtx0_x , i_vtx2_x , i_vtx1_x, 22'b0} : 
                        ((r_state == s_e_c_0_0) ? {i_vtx2_y , i_vtx0_y , 44'd0}: 
                        ((r_state==s_e_c_0_1) ? {i_vtx1_y , i_vtx2_y ,i_vtx0_y , i_vtx1_y} :
                        {r_e1_c ,w_simd_out[3*22-1:2*22], w_simd_out[21:0]  , 22'd0})));  
    // SIMD END

    assign  o_vtx0_x  =  i_vtx0_x ; 
    assign  o_vtx0_y  =  i_vtx0_y ; 
    assign  o_vtx0_z  =  i_vtx0_z ; 
    assign  o_vtx0_cr =  i_vtx0_cr; 
    assign  o_vtx0_cg =  i_vtx0_cg; 
    assign  o_vtx0_cb =  i_vtx0_cb; 
    assign  o_vtx1_x  =  i_vtx1_x ;
    assign  o_vtx1_y  =  i_vtx1_y  ;
    assign  o_vtx1_z  =  i_vtx1_z  ;
    assign  o_vtx1_cr =  i_vtx1_cr ;
    assign  o_vtx1_cg =  i_vtx1_cg ;
    assign  o_vtx1_cb =  i_vtx1_cb ;
    assign  o_vtx2_x  =  i_vtx2_x  ;
    assign  o_vtx2_y  =  i_vtx2_y ;
    assign  o_vtx2_z  =  i_vtx2_z ;
    assign  o_vtx2_cr =  i_vtx2_cr;
    assign  o_vtx2_cg =  i_vtx2_cg;
    assign  o_vtx2_cb =  i_vtx2_cb;
    assign o_e0_a =  r_e0_a;   
    assign o_e0_b =  r_e0_b;   
    assign o_e0_c =  r_e0_c;   
    assign o_e1_a =  r_e1_a;  
    assign o_e1_b =  r_e1_b;   
    assign o_e1_c =  r_e1_c;   
    assign o_e2_a =  r_e2_a;  
    assign o_e2_b =  r_e2_b;   
    assign o_e2_c =  r_e2_c;  
    assign o_valid = (r_state == s_OUT) ; 
    // Always Blocks              
  always @(posedge clk or negedge rstn) begin
    if (rstn) 
        r_state <= s_IDLE; 
    else begin 
        case (r_state)
            s_IDLE: begin 
                if (i_en ) begin 
                    r_state <= s_e_a; 
                    r_simd_opcode <= 1 ; // sub
                end
            end
            s_e_a: begin 
                if(w_simd_valid) begin 
                    // move to next state and load coeff register
                    r_e0_a <= w_simd_out[4*22-1:3*22]; 
                    r_e1_a <= w_simd_out[3*22-1:2*22]; 
                    r_e2_a <= w_simd_out[2*22-1:1*22]; 
                    r_state <= s_e_b;
                end
            end
            s_e_b: begin 
                if(w_simd_valid) begin 
                    // move to next state and load coeff register
                    r_e0_b <= w_simd_out[4*22-1:3*22]; 
                    r_e1_b <= w_simd_out[3*22-1:2*22]; 
                    r_e2_b <= w_simd_out[2*22-1:1*22]; 
                    r_state <= s_e_c_0_0;
                    r_simd_opcode <= 2; // mul
                end
            end
            s_e_c_0_0:begin 
                if(w_simd_valid) begin 
                    // move to next state and load coeff register
                    r_e0_c <= w_simd_out[4*22-1:3*22]; 
                    r_e1_c <= w_simd_out[3*22-1:2*22]; 
                    r_state <= s_e_c_0_1;
                end
                
            end
            s_e_c_0_1:begin 
                if(w_simd_valid) begin 
                    // move to next state and load coeff register
                    r_simd_opcode <= 3'b001; // subtraction
                    r_state <= s_e_c_1;
                end
               
            end
            s_e_c_1:begin 
                if(w_simd_valid) begin 
                    // move to next state and load coeff register
                    r_e0_c <= w_simd_out[4*22-1:3*22]; 
                    r_e1_c <= w_simd_out[3*22-1:2*22]; 
                    r_e2_c <= w_simd_out[2*22-1:1*22]; 
                    r_state <= s_OUT; 
                end
            end
            s_OUT: begin 
                if (~i_busy)
                r_state <= s_IDLE;
            end 
        endcase 
    end
        
  end
    // module instantiation 
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
    // old 
    // delay 6 o_valid 
    //ren_delay #(
    //.P_WIDTH     ( 1 ),
    //.P_NUM_DELAY ( 6 )) u_ren_delay (
    //    .clk                     ( clk      ),
    //    .i_en                    ( w_valid ) ,
    //    .i_data                  ( w_valid  ),
    //    .o_data                  ( o_valid  ) 
    //);
    // edge 0 
/*
    fp_add  u_a_coeff (
    .clk                     ( clk      ),
    .i_en                    ( 1'b1),
    .i_a                     ( i_vtx0_y), 
    .i_b                     ( i_vtx2_y),
    .i_adsb                  ( 1'b1),// subtract
    .o_c                     ( o_e0_a)
    );
    fp_add  u_b_coeff ( 
    .clk                     ( clk      ),
    .i_en                    ( 1'b1),
    .i_a                     ( i_vtx2_x),
    .i_b                     ( i_vtx0_x),
    .i_adsb                  ( 1'b1),
    .o_c                     ( o_e0_b)
    );
    //x0*y1 - x1*y0 // delay 3 mul + 3 add (delay 6)
    fp_mul  u_fp_c0mul (
    .clk                     ( clk    ),
    .i_en                    ( 1'b1),
    .i_a                     ( i_vtx0_x),
    .i_b                     ( i_vtx2_y),
    .o_c                     ( w_e0_c_1)
    );
    fp_mul  u_fp_c1mul (
    .clk                     ( clk    ),
    .i_en                    ( 1'b1),
    .i_a                     ( i_vtx2_x),
    .i_b                     ( i_vtx0_y),
    .o_c                     ( w_e0_c_2)
    );
    fp_add  u_c_coeff ( 
    .clk                     ( clk      ),
    .i_en                    ( 1'b1),
    .i_a                     ( w_e0_c_1 ),
    .i_b                     ( w_e0_c_2 ),
    .i_adsb                  ( 1'b1),
    .o_c                     ( o_e0_c)
    );

    // edge 1
    fp_add  u1_a_coeff (
    .clk                     ( clk      ),
    .i_en                    ( 1'b1),
    .i_a                     ( i_vtx2_y),
    .i_b                     ( i_vtx1_y),
    .i_adsb                  ( 1'b1),// subtract
    .o_c                     ( o_e1_a)
    );
    fp_add  u1_b_coeff ( 
    .clk                     ( clk      ),
    .i_en                    ( 1'b1),
    .i_a                     ( i_vtx1_x),
    .i_b                     ( i_vtx2_x),
    .i_adsb                  ( 1'b1),
    .o_c                     ( o_e1_b)
    );
    //x0*y1 - x1*y0 // delay 3 mul + 3 add (delay 6)
    fp_mul  u1_fp_c0mul (
    .clk                     ( clk    ),
    .i_en                    ( 1'b1),
    .i_a                     ( i_vtx2_x),
    .i_b                     ( i_vtx1_y),
    .o_c                     ( w_e1_c_1)
    );
    fp_mul  u1_fp_c1mul (
    .clk                     ( clk    ),
    .i_en                    ( 1'b1),
    .i_a                     ( i_vtx1_x),
    .i_b                     ( i_vtx2_y),
    .o_c                     ( w_e1_c_2)
    );
    fp_add  u1_c_coeff ( 
    .clk                     ( clk      ),
    .i_en                    ( 1'b1),
    .i_a                     ( w_e1_c_1 ),
    .i_b                     ( w_e1_c_2 ),
    .i_adsb                  ( 1'b1),
    .o_c                     ( o_e1_c)
    );
    // edge 2
    fp_add  u2_a_coeff (
    .clk                     ( clk      ),
    .i_en                    ( 1'b1),
    .i_a                     ( i_vtx1_y),
    .i_b                     ( i_vtx0_y),
    .i_adsb                  ( 1'b1),// subtract
    .o_c                     ( o_e2_a)
    );
    fp_add  u2_b_coeff ( 
    .clk                     ( clk      ),
    .i_en                    ( 1'b1),
    .i_a                     ( i_vtx0_x),
    .i_b                     ( i_vtx1_x),
    .i_adsb                  ( 1'b1),
    .o_c                     ( o_e2_b)
    );
    //x0*y1 - x1*y0 // delay 3 mul + 3 add (delay 6)
    fp_mul  u2_fp_c0mul (
    .clk                     ( clk    ),
    .i_en                    ( 1'b1),
    .i_a                     ( i_vtx1_x),
    .i_b                     ( i_vtx0_y),
    .o_c                     ( w_e2_c_1)
    );
    fp_mul  u2_fp_c1mul (
    .clk                     ( clk    ),
    .i_en                    ( 1'b1),
    .i_a                     ( i_vtx0_x),
    .i_b                     ( i_vtx1_y),
    .o_c                     ( w_e2_c_2)
    );
    fp_add  u2_c_coeff ( 
    .clk                     ( clk      ),
    .i_en                    ( 1'b1),
    .i_a                     ( w_e2_c_1 ),
    .i_b                     ( w_e2_c_2 ),
    .i_adsb                  ( 1'b1),
    .o_c                     ( o_e2_c)
    );
*/
endmodule 
