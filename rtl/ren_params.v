`define TILE_SIZE 16 // 16x16
`define fpTILE_SIZE {1'b0, 5'b10011 , 16'h8000} 

`define fpTILE_SIZE_rc {1'b0, 5'b01011 , 16'h8000} 
 
`define fpHALF  {1'b0, 5'h0e , 16'h8000}   // 0.5f
`define fpONE  {1'b0, 5'b01111 , 16'h8000}   // 1.0f
`define fpONEHALF  {1'b0, 5'b01111 ,4'b1100 ,12'h000}  // 1.5f
`define fpTWO  {1'b0, 5'h10 , 16'h8000}  // 2.0f
`define fpTWOHALF  {1'b0, 5'b10000 , 4'b1010, 12'h000}  // 2.5f
`define fpTHREE  {1'b0, 5'b10000 , 4'b1100, 12'h000}  // 3.0f
`define fpTHREEHALF  {1'b0, 5'b10000 , 4'b1110 ,12'h000}  // 3.5f
`define fpFOUR {1'b0, 5'b10001 , 16'h8000} // 4.0f
// simd instructions
`define op_add 0 
`define op_sub 1  
`define op_mul 2  
`define op_rcp 3 
`define op_reduce_add 4
`define op_reduce_mul 5 
`define op_load_1 6 
`define op_load_2 7  
// HELP FUNCTIONS 
