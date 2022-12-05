

module fp_rcp (
  clk,
  i_en,
  i_a,
  o_c
);

////////////////////////////
// I/O definition
////////////////////////////
    input         clk;
    input         i_en;
    input  [21:0] i_a;          // input A
    output [21:0] o_c;          // result


///////////////////////////////////////////
//  register definition
///////////////////////////////////////////
    reg    [21:0] r_c;           // result

    reg           r_a_sign;
    reg    [4:0]  r_ce_tmp;
    reg    [7:0]  r_a_frac_l;

///////////////////////////////////////////
//  wire 
///////////////////////////////////////////
    wire          w_a_sign;
    wire   [4:0]  w_a_exp;
    wire   [15:0] w_a_fraction;
    wire   [4:0]  w_2bias;
    wire   [4:0]  w_ce_tmp;
    wire   [15:0] w_cf_tmp;
    wire   [31:0] w_rom_out;
    wire   [15:0] w_rom_base;
    wire   [15:0] w_rom_diff;
    wire   [6:0]  w_rom_address;
    wire   [7:0]  w_a_frac_l;
    //wire   [31:0] w_rom_correct;
    wire   [23:0] w_rom_correct;
    wire   [21:0] w_c;
    wire          w_zero_flag;
///////////////////////////////////////////
//  assign
///////////////////////////////////////////
    assign w_a_sign = i_a[21];
    assign w_a_exp = i_a[20:16];
    assign w_a_fraction = i_a[15:0];
    assign w_2bias = 5'h1e;  // x2
    assign w_ce_tmp = w_2bias - w_a_exp;

    assign w_rom_address = w_a_fraction[14:8];
    assign w_a_frac_l = w_a_fraction[7:0];
/* // original implementation 
    assign w_rom_base = w_rom_out[31:16];   // 1.15
    assign w_rom_diff = w_rom_out[15:0];    // 0.16
    assign w_rom_correct = w_rom_diff * {r_a_frac_l,8'b0};
    assign w_cf_tmp = w_rom_base - {1'b0,w_rom_correct[31:17]};
*/
    // timing improvement
    assign w_rom_base = w_rom_out[31:16];   // 1.15
    assign w_rom_diff = w_rom_out[15:0];    // 0.16
    assign w_rom_correct = w_rom_diff * r_a_frac_l;
    assign w_cf_tmp = w_rom_base - {1'b0,w_rom_correct[23:9]};

    assign w_zero_flag = (w_a_exp == 5'h0);

    // output port
    assign o_c = r_c;

///////////////////////////////////////////
//  always statement
///////////////////////////////////////////

    always @(posedge clk) begin
        if (i_en) begin
            r_a_sign <= w_a_sign;
            r_ce_tmp <= w_ce_tmp;
            r_a_frac_l <= w_a_frac_l;
        end
    end
 
    always @(posedge clk) begin
        if (i_en) begin
            r_c <= (w_zero_flag) ? 16'h0 : w_c;
        end
    end


///////////////////////////////////////////
//  module instance
///////////////////////////////////////////
// table rom
    fp_rcp_rom frcp_rom (
        .clk(clk),
        .i_a(w_rom_address),
        .o_c(w_rom_out)
    );
// normalize
    fp_norm norm (
        .i_s(r_a_sign),
        .i_e(r_ce_tmp),
        .i_f({1'b0,w_cf_tmp[15:0]}),
        .o_b(w_c)
    );

endmodule
