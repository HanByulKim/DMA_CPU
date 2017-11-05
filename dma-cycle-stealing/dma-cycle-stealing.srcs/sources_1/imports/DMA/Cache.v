`include "states.v"
`define ENTRY_SIZE 78
`define WORD_SIZE 16
`define BLOCK_SIZE 4
`define FETCH_SIZE 64

`define ENTRY_TAG 77:65
`define ENTRY_VALID 64
`define ENTRY_DATA3 63:48
`define ENTRY_DATA2 47:32
`define ENTRY_DATA1 31:16
`define ENTRY_DATA0 15:0
`define ENTRY_DATABLOCK 63:0
`define ADDRESS_TAG 15:3

module Cache(
    input clk, 
    input reset_n,
    input readC, 
    input writeC,
    input [`WORD_SIZE-1:0] addressC,
    inout [`WORD_SIZE-1:0] dataC,
    inout [`FETCH_SIZE-1:0] dataM, 
    output wire [`WORD_SIZE-1:0] addressM,
    output reg cacheReadM,
    output reg cacheWriteM, 
    output reg done,
    input DMABG
);

    reg [`ENTRY_SIZE-1:0] entries [0:1];
    reg [4:0] state;
    reg [4:0] next_state;
    reg next_readM;
    reg next_writeM;
    reg next_done;  // indicates cache's state
    
    wire index;
    wire [1:0] bo;
    
    wire hit;
    
    assign index = addressC[2];
    assign bo = addressC[1:0];    
    assign dataC = readC? {
        (bo==3)?entries[index][`ENTRY_DATA3]:
        (bo==2)?entries[index][`ENTRY_DATA2]:
        (bo==1)?entries[index][`ENTRY_DATA1]:
                  entries[index][`ENTRY_DATA0] } :
        16'bz;
    assign addressM = cacheWriteM? addressC: {addressC[`WORD_SIZE-1:2],2'b00}; //assign block address in read
    assign dataM = cacheWriteM? dataC : 64'bz; //use only lowest 16 bits in write
    assign hit=(entries[index][`ENTRY_TAG]==addressC[`ADDRESS_TAG] && entries[index][`ENTRY_VALID]==1)? 1:0; //indicates hit

    // state transition
    always @(negedge clk) begin
            state<=next_state;
            cacheReadM<=next_readM;
            cacheWriteM<=next_writeM;
            done<=next_done;
    end

    // next_state, next_output calculation 
    always @(*) begin
        if(~reset_n) begin
            state=0;
            next_state=0;
            entries[0]=0;
            entries[1]=0;
            cacheReadM=0;
            cacheWriteM=0;
            done=1;
            next_readM=0;
            next_writeM=0;
            next_done=1;
        end
        else begin
            case(state)
                `START : begin
                    if(readC && ~writeC) begin
                        if(hit) begin 
                            next_state=`START;
                            next_readM=0;
                            next_writeM=0;
                            next_done=1;
                        end
                        else begin
                            if(DMABG==0) begin  // check whether CPU is taking the bus
                                next_state=`R1;
                                next_readM=1;
                                next_writeM=0;
                                next_done=0;
                            end
                            else begin
                                next_state=`START;
                                next_readM=0;
                                next_writeM=0;
                                next_done=0;
                            end
                        end
                    end
                    else if(~readC && writeC) begin
                        if(DMABG==0) begin  // check whether CPU is taking the bus
                            next_state=`W1;     
                            next_writeM=1;
                            next_readM=0;
                            next_done=0;
                        end
                        else begin
                            next_state=`START;
                            next_readM=0;
                            next_writeM=0;
                            next_done=0;
                        end                            
                    end
                    else begin
                        next_state=`START;
                        next_readM=0;
                        next_writeM=0;
                        next_done=1;
                    end  
                end
                `R6, `W6 : begin
                    next_state=`START;
                    if(state==`R6) begin
                        entries[index][`ENTRY_TAG]=addressC[`ADDRESS_TAG];
                        entries[index][`ENTRY_DATABLOCK]=dataM;
                        entries[index][`ENTRY_VALID]=1;
                    end
                    else if(state==`W6) begin             
                        if(hit) begin //hit     
                            entries[index][`ENTRY_VALID]=0; // just invalidate the entry, since it follows write-no-allocate 
                        end
                    end
                    next_readM=0;
                    next_writeM=0;
                    next_done=1;
                end
                default: next_state=state+3'b100; //R1->...->R6, W1->...->W6, wait for memory
            endcase
        end
    end
    
endmodule
