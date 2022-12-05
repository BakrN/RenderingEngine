
typedef struct packed{
    reg [1:0 ] test  ; 
    int test1 ;  
} struct_name;
module depth_buffer ( clk, 
rstn ,
i_addr_row ,
i_addr_col , 
i_data , 
i_write, 
o_data , 
o_busy 
) ; 
    parameter COLS = 640; 
    parameter ROWS = 480;
    input logic clk; 
    input logic rstn; 
    input logic i_write;  
    input logic [$clog2(ROWS)-1:0] i_addr_row  ; 
    input logic [$clog2(COLS)-1:0] i_addr_col ; 
    input logic  [21:0] i_data; 
    output logic [21:0] o_data; 
    output logic o_busy; 
    logic [21:0] r_mem_array [ROWS][COLS] ; 
    logic [21:0] r_mem [ROWS][COLS]; 
    logic [$clog2(ROWS)-1: 0] r_row_count ; 
    logic [$clog2(COLS)-1: 0] r_col_count ; 
    logic r_reset ;

    assign o_busy = (r_reset == 1); 
    always_ff @( posedge clk or negedge rstn) begin : mem_read
        if (!rstn && r_reset==0) begin  
            r_reset <= 1; 
            r_row_count <= 0 ; 
            r_col_count <= 0 ;  
        end else if (r_reset) begin  
            r_mem_array[r_row_count][r_col_count] <= {1'b0, 21'h1fffff}; // max dist
            if (r_row_count < ROWS)begin  
                if (r_col_count < COLS-1) begin  
                    r_col_count <= r_col_count + 1 ; 
                end else begin 
                    if (r_row_count == ROWS-1)begin 
                        r_reset = 0 ; 
                    end else begin 
                        r_col_count <= 0 ; 
                        r_row_count <= r_row_count + 1; 
                    end
                end
            end 
        end else if (i_write) begin 
            // update mem array 
            r_mem_array[i_addr_row ][i_addr_col] <= i_data ;    
        end
    end
    
endmodule 