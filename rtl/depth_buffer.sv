
module depth_buffer ( clk, 
rstn ,
i_addr_row ,
i_addr_col , 
o_data 
) ; 
    parameter COLS = 640; 
    parameter ROWS = 480; 
    input logic clk; 
    input logic rstn; 
    input logic i_addr_row [$clog2(ROWS)-1:0]; 
    input logic i_addr_col [$clog2(COLS)-1:0]; 
    output logic o_data [21:0]; 

    
    logic [21:0] r_mem [ROWS][COLS];
    always_ff @( posedge clk or negedge rstn) begin : mem_read
        
    end
endmodule 