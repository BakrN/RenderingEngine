

module fifo#(parameter WIDTH = 22 , parameter DEPTH=13)(
    clk, 
    rst_n, 
    i_data,
    i_wr_en, 
    i_rd_en, 
    o_empty, 
    o_full, 
    o_data

    );
    input clk; 
    input rst_n; 
    input [WIDTH-1:0] i_data; 
    input [WIDTH-1:0] o_data; 
    input i_wr_en;  
    input i_rd_en;  
    output o_empty;   
    output o_full; 

    assign o_empty = (r_element_count==0) ? 1 : 0 ; 
    assign o_full = (r_element_count>(DEPTH-1)) ? 1 : 0 ; 


    reg [$clog2(DEPTH)-1:0] r_wr_ptr , r_rd_ptr, r_element_count; 
    reg [WIDTH-1:0] memory [DEPTH-1:0]; 
    
    always @(posedge clk or negedge rst_n)begin 
        if(~rst_n)begin 
            r_wr_ptr <= 0 ; 
            r_rd_ptr <= 0 ; 
            r_element_count <= 0 ; 
        end
        else begin 
            if (~o_full && i_wr_en)begin 
                memory[r_wr_ptr] <= i_data; 
                r_wr_ptr <= r_wr_ptr+ 1 ; 
                r_element_count <= r_element_count + 1; 
            end
            if (~o_empty && i_rd_en) begin 
                r_element_count <= r_element_count  - 1; 
                r_rd_ptr <= r_rd_ptr + 1 ; 
            end
        end
    end
    assign o_data = memory[r_rd_ptr]; 
endmodule