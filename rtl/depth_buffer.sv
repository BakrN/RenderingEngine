
module depth_buffer ( clk, 
rstn ,
i_addr_row ,
i_addr_col , 
o_data , 
o_busy 
) ; 
    parameter COLS = 640; 
    parameter ROWS = 480;
    localparam s_reset = 1;
    localparam s_idle  = 0 ;
    input logic clk; 
    input logic rstn; 
    input logic i_addr_row [$clog2(ROWS)-1:0]; 
    input logic i_addr_col [$clog2(COLS)-1:0]; 
    output logic o_data [21:0]; 
    output logic o_busy; 
    logic [21:0] r_mem_array [ROWS][COLS] ; 
    logic [21:0] r_mem [ROWS][COLS];
    logic r_state ;

    assign o_busy = (r_state != s_idle); 
    always_ff @( posedge clk or negedge rstn) begin : mem_read
        if (!rstn) begin  
            
        end else begin 

        end
    end
endmodule 