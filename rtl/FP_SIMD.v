`timescale 1ns / 1ps

// Floating point ALU unit 
// max 3 ops at a time 
// 2 bits: add , mul , rcp , sub 
// operations on inputs: add_inputs(overwrites output) , sub_inputs(overwrites output) , mul inputs 
// opcodes  = 000: add in, 001: sub in,  010: mul in , 011: rcp  , 100: reduce , 101: reduce_mul 
// operations on reg, rcp , reduce , clear, mul 
// 1 for each stage 
// enquue operations 
module FP_SIMD( 
    clk , 
    rst_n, 
    i_opcode, 
    i_en , 
    i_in1 , 
    i_in2 ,
    o_output , 
    o_reg_out, 
    o_busy , 
    o_valid 
    );
    localparam SIMD_WIDTH = 4;
    // Ports IO 
    input clk ;
    input rst_n; 
    input i_en ; 
    input [(SIMD_WIDTH*22)- 1:0] i_in1; 
    input [(SIMD_WIDTH*22)-1:0] i_in2; 
    output [(SIMD_WIDTH*22)-1:0] o_output; 
    output [(SIMD_WIDTH*22)-1:0] o_reg_out; 
    input [2:0] i_opcode ; // any different combination 
    output o_valid; 
    output o_busy ; 
    // io_end
    // states 
    // max latency is 3 
    
    localparam s_IDLE = 0 ; 
    localparam s_S0_0 = 1 ; 
    localparam s_S0_1 = 2 ; 
    localparam s_S0_2 = 3 ; 
    localparam s_S1_0 = 4 ; 
    localparam s_S1_1 = 5 ; 
    localparam s_S1_2 = 6 ; 
    localparam s_OUT  = 7; // update inner reg
    localparam s_REGUPDATE  = 8; // update inner reg

    localparam op_add = 0 ; 
    localparam op_sub= 1 ; 
    localparam op_mul = 2 ; 
    localparam op_rcp =  3 ; 
    localparam op_reduce_add = 4 ; 
    localparam op_reduce_mul = 5 ; 
    localparam op_load_1 = 6; 
    localparam op_load_2 = 7; 
    
    // wires 
    wire w_adder_en  ; 
    wire w_multiplier_en ; 
    wire w_rcp_en ; 
    wire [21:0] w_add_ia [SIMD_WIDTH-1:0]; 
    wire [21:0] w_add_ib [SIMD_WIDTH-1:0]; 
    wire [21:0] w_add_out [SIMD_WIDTH-1:0]; 
    wire [21:0] w_mul_ia [SIMD_WIDTH-1:0]; 
    wire [21:0] w_mul_ib [SIMD_WIDTH-1:0]; 
    wire [21:0] w_mul_out [SIMD_WIDTH-1:0]; 
    wire [21:0] w_rcp [SIMD_WIDTH-1:0]; 
    wire [21:0] w_rcp_out [SIMD_WIDTH-1:0]; 
    wire  w_subtraction;
    // regs 
    
    reg [3:0] r_state ;
    reg [21:0] r_result [SIMD_WIDTH-1:0]; 
    reg [1:0] r_out_selector; // 00 adder , 01 mul  , 10rcp , 11 reg
    reg [2:0] r_operation; 


    //assigns 
    assign w_adder_en = (r_state==s_IDLE) ? 0 : ((r_out_selector==0) ? 1 : 0); 
    assign o_reg_out = {r_result[0] ,r_result[1], r_result[2], r_result[3]}; 
    assign w_rcp_en = (r_state==s_IDLE) ? 0 : ((r_out_selector==2'b10) ? 1 : 0); 
    assign w_multiplier_en = (r_state==s_IDLE) ? 0 : ((r_out_selector==2'b01) ? 1 : 0); 
    for (genvar j = 0 ; j <SIMD_WIDTH ; j = j+1 )begin 
        assign o_output[(SIMD_WIDTH-j)*22 -1:(SIMD_WIDTH-j-1)*22] = (r_out_selector==0) ? w_add_out[j] : ((r_out_selector==1)?w_mul_out[j] :((r_out_selector==2) ? w_rcp_out[j]: r_result[j])); 
    end 
    assign w_subtraction = (i_opcode==op_sub) ? 1 : 0 ; 
    
    // opcodes  = 000: add in, 001: sub in,  010: mul in , 011: rcp  , 100: reduce , 101: reduce_mul 
    for (genvar j = 0 ; j <SIMD_WIDTH; j = j+1) begin
        assign w_add_ia[j] = (i_opcode[2] == 1) ? r_result[j] : i_in1[(SIMD_WIDTH-j)*22-1: (SIMD_WIDTH-j)*22-1-21]  ; 
        assign w_mul_ia[j] = (i_opcode[2] == 1) ? r_result[j] : i_in1[(SIMD_WIDTH-j)*22-1: (SIMD_WIDTH-j)*22-1-21] ; 
        assign w_rcp[j] =  r_result[j] ;
        if (j== 2)begin 
            assign w_add_ib[j]= (i_opcode[2] == 1 ) ?  r_result[j+1] :i_in2[(SIMD_WIDTH-j)*22-1: (SIMD_WIDTH-j)*22-1-21]  ; 
            assign w_mul_ib[j] = (i_opcode[2] == 1) ? r_result[j+1] : i_in2[(SIMD_WIDTH-j)*22-1: (SIMD_WIDTH-j)*22-1-21]  ; 
        end else if (j==0) begin // 2nd stage reduce. only care about1st adder
            assign w_add_ib[j]= (i_opcode[2] == 1) ? ((r_state <4)? r_result[j+1] : r_result[j+2] ) : i_in2[(SIMD_WIDTH-j)*22-1: (SIMD_WIDTH-j)*22-1-21]  ; 
            assign w_mul_ib[j] = (i_opcode[2] == 1) ? ((r_state <4)? r_result[j+1] : r_result[j+2] ) : i_in2[(SIMD_WIDTH-j)*22-1: (SIMD_WIDTH-j)*22-1-21]  ; 
        end else begin 
            assign w_add_ib[j]=   i_in2[(SIMD_WIDTH-j)*22-1: (SIMD_WIDTH-j)*22-1-21]  ; 
            assign w_mul_ib[j] =  i_in2[(SIMD_WIDTH-j)*22-1: (SIMD_WIDTH-j)*22-1-21] ; 
        end
    end 
    
    
    assign o_busy = (r_state==s_IDLE) ? 0 : 1 ; 
    assign o_valid = (r_state==s_OUT) ? 1 : 0 ; 
    //always
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin 
         //   r_result <= 0 ; 
            r_state <= s_IDLE ; 
        end
        else begin 
        case (r_state) 
            s_IDLE: begin 
                if (i_en)begin 
                    case (i_opcode) 
                        // on input
                        3'b000: begin // add in 
                            r_out_selector <= 0 ; 
                            r_state <= s_S0_0; 
                        end
                        3'b001: begin // subtract in 
                            r_out_selector <= 0 ; 
                            r_state <= s_S0_0; 
                        end
                        3'b010: begin // mul in 
                            r_out_selector <= 1; 
                            r_state <= s_S0_0; 
                        end
                        3'b011: begin // rcp 
                            r_out_selector <= 2; 
                            r_state <= s_S0_0; 
                        end
                        3'b100: begin // reduce add 
                            r_out_selector <= 0; 
                            r_state <= s_S0_0; 
                        end
                        3'b101: begin // reduce mul
                            r_out_selector <= 1; 
                            r_state <= s_S0_0; 
                        end
                        3'b110: begin // load reg1
                            r_out_selector <= 3; 
                            r_result[0] <= i_in1[4*22-1: 3*22]; 
                            r_result[1] <= i_in1[3*22-1: 2*22]; 
                            r_result[2] <= i_in1[2*22-1: 1*22]; 
                            r_result[3] <= i_in1[1*22-1: 0*22]; 
                        end
                        3'b111: begin // load reg2
                            r_out_selector <= 3; 
                            r_result[0] <= i_in2[4*22-1: 3*22]; 
                            r_result[1] <= i_in2[3*22-1: 2*22]; 
                            r_result[2] <= i_in2[2*22-1: 1*22]; 
                            r_result[3] <= i_in2[1*22-1: 0*22]; 
                        end
                        default: begin 
                            r_out_selector <= 3; 
                        end
                    endcase 
                     
                end else 
                    r_state <= s_IDLE; 
            end
           
            s_S0_0: begin 
                r_state <= s_S0_1; 
            end
            s_S0_1: begin 
                
                if (i_opcode == op_rcp) 
                    r_state <= s_OUT; 
                else 
                    r_state <= s_S0_2; 

            end
            s_S0_2: begin 
                if(i_opcode[2] == 1)begin 
                    r_state <= s_REGUPDATE; 
                end
                else 
                 r_state <= s_OUT; 
                
            end
            s_REGUPDATE: begin 
                r_result[0]<= o_output[(SIMD_WIDTH)*22-1: (SIMD_WIDTH)*22 - 1 -21]; 
                r_result[1]<= o_output[(SIMD_WIDTH-1)*22-1: (SIMD_WIDTH-1)*22 - 1 -21]; 
                r_result[2]<= o_output[(SIMD_WIDTH-2)*22-1: (SIMD_WIDTH-2)*22 - 1 -21]; 
                r_result[3]<= o_output[(SIMD_WIDTH-3)*22-1: (SIMD_WIDTH-3)*22 - 1 -21]; 
                r_state <= s_S1_0; 
            end
            s_S1_0: begin 
                r_state <= s_S1_1; 
            end
            s_S1_1: begin 
                r_state <= s_S1_2; 
            end 
            s_S1_2: begin 
                r_state <= s_OUT; // no need to update reg 
            end 
            s_OUT: begin 
                r_result[0]<= o_output[(SIMD_WIDTH)*22-1: (SIMD_WIDTH)*22 - 1 -21]; 
                r_result[1]<= o_output[(SIMD_WIDTH-1)*22-1: (SIMD_WIDTH-1)*22 - 1 -21]; 
                r_result[2]<= o_output[(SIMD_WIDTH-2)*22-1: (SIMD_WIDTH-2)*22 - 1 -21]; 
                r_result[3]<= o_output[(SIMD_WIDTH-3)*22-1: (SIMD_WIDTH-3)*22 - 1 -21]; 
                r_state <= s_IDLE ; 
            end 
           
            default: begin 
                r_state <= s_IDLE; 
            end
        endcase 
        end
    end
    // module instantiation
    generate for (genvar i = 0 ; i<4; i = i+1) begin 
          
    // latency 3
    fp_add  u_add(
    .clk                     ( clk      ),
    .i_en                    ( w_adder_en),
    .i_a                     ( w_add_ia[i]),
    .i_b                     ( w_add_ib[i]), 
    .i_adsb                  ( w_subtraction), // add 
    .o_c                     ( w_add_out[i])
    );
    // Latency 2
    fp_rcp  u_rcp(
    .clk                     ( clk    ),
    .i_en                    ( w_rcp_en),
    .i_a                     ( w_rcp[i]   ),
    .o_c                     ( w_rcp_out[i])
    );
    // Latency 3
    fp_mul  u_mul(
    .clk                     ( clk    ),
    .i_en                    ( w_multiplier_en), 
    .i_a                     ( w_mul_ia[i] ),
    .i_b                     ( w_mul_ib[i] ),
    .o_c                     ( w_mul_out[i] )
    );
    end 
    endgenerate 
endmodule
