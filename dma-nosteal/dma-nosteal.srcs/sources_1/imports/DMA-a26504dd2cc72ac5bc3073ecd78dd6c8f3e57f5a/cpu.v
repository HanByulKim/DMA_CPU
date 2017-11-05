`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size
`define FETCH_SIZE 64
`include "opcodes.v"

module cpu(
        input Clk, 
        input Reset_N, 

	// Instruction memory interface
        output i_readM, 
        output i_writeM, 
        output [`WORD_SIZE-1:0] i_address, 
        inout [`FETCH_SIZE-1:0] i_data, 

	// Data memory interface
        output d_readM, 
        output d_writeM, 
        output [`WORD_SIZE-1:0] d_address, 
        inout [`FETCH_SIZE-1:0] d_data, 
        
        input DMABegin,
        input DMAEnd,
        input BR,   
        output wire BG,
        output wire DMACMD,
        
        output [`WORD_SIZE-1:0] num_inst, 
        output [`WORD_SIZE-1:0] output_port, 
        output is_halted
);

    // TODO : Implement your multi-cycle CPU!
    Datapath datapath(.i_readM(i_readM), .i_writeM(i_writeM), .i_addressM(i_address), .i_dataM(i_data), .d_readM(d_readM), .d_writeM(d_writeM), .d_addressM(d_address), .d_dataM(d_data), .reset_n(Reset_N), .clk(Clk), .DMABegin(DMABegin), .DMAEnd(DMAEnd), .BR(BR), .BG(BG), .DMACMD(DMACMD), .num_inst(num_inst), .output_port(output_port), .is_halted(is_halted));  

endmodule
