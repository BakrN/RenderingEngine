module fp_floor (
    i_a,
    o_b
);

///////////////////////////////////////////
//  port definition
///////////////////////////////////////////
    input  [20:0] i_a;          // input e5, f1.15
    output [20:0] o_b;          
///////////////////////////////////////////
//  wire definition
///////////////////////////////////////////
    // intermidiate wire
    wire [4:0]  w_exp;
    wire [15:0] w_fraction;
    wire [15:0] w_fraction_out;

///////////////////////////////////////////
//  assign statement
///////////////////////////////////////////
    assign w_exp  = i_a[20:16];
    assign w_fraction = i_a[15:0];

    assign o_b = {w_exp, w_fraction_out};
    assign w_fraction_out = f_floor(w_exp, w_fraction);
///////////////////////////////////////////
//  function statement
///////////////////////////////////////////
    function [15:0] f_floor;
        input [4:0]  exp;
        input [15:0] frac;
        begin
            case (exp[4:0])
                5'hf:  f_floor = {frac[15],15'h0};
                5'h10: f_floor = {frac[15:14],14'h0};
                5'h11: f_floor = {frac[15:13],13'h0};
                5'h12: f_floor = {frac[15:12],12'h0};
                5'h13: f_floor = {frac[15:11],11'h0};
                5'h14: f_floor = {frac[15:10],10'h0};
                5'h15: f_floor = {frac[15:9],9'h0};
                5'h16: f_floor = {frac[15:8],8'h0};
                5'h17: f_floor = {frac[15:7],7'h0};
                5'h18: f_floor = {frac[15:6],6'h0};
                5'h19: f_floor = {frac[15:5],5'h0};
                5'h1a: f_floor = {frac[15:4],4'h0};
                5'h1b: f_floor = {frac[15:3],3'h0};
                5'h1c: f_floor = {frac[15:2],2'h0};
                5'h1d: f_floor = {frac[15:1],1'h0};
                5'h1e: f_floor = frac[15:0];
                default: f_floor = 16'h0;
            endcase
        end
    endfunction

endmodule
