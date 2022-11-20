// for rounding up just add 0.5
module fp_to_int(

    input [21:0] i_a , 
    output [15:0] o_c
); 

    wire [4:0] w_exp, w_exp_comp;  
    wire [15:0]w_mantissa;
    assign w_exp = i_a[20:16];
    assign w_mantissa = i_a[15:0];
    assign w_exp_comp = w_exp - 5'd15; 
    function [15:0] fp_convert; 
        input [21:0] fp ; 
        input [4:0] ee ;
         case (ee[4:0])
                    5'd0:  fp_convert = {15'b0,fp[15]};    // bias 0
                    5'd1:  fp_convert = {14'b0,fp[15:14]};
                    5'd2:  fp_convert = {13'b0,fp[15:13]};
                    5'd3:  fp_convert = {12'b0,fp[15:12]};
                    5'd4:  fp_convert = {11'b0,fp[15:11]};
                    5'd5:  fp_convert = {10'b0,fp[15:10]};
                    5'd6:  fp_convert = {9'b0,fp[15:9]};
                    5'd7:  fp_convert = {8'b0,fp[15:8]};
                    5'd8:  fp_convert = {7'b0,fp[15:7]};
                    5'd9:  fp_convert = {6'b0,fp[15:6]};
                    5'd10: fp_convert = {5'b0,fp[15:5]};
                    5'd11: fp_convert = {4'b0,fp[15:4]};
                    5'd12: fp_convert = {3'b0,fp[15:3]};
                    5'd13: fp_convert = {2'b0,fp[15:2]};
                    5'd14: fp_convert = {1'b0,fp[15:1]};
                    5'd15: fp_convert = fp[15:0];
                    default: fp_convert= 16'h0;
                endcase
    endfunction
    assign o_c = fp_convert(i_a , w_exp_comp); 

endmodule