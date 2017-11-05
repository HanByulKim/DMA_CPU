`define WORD_SIZE 16

`define INTTERRUPT_DURATION 100
/*************************************************
* DMA module (DMA.v)
* input: clock (CLK), bus grant (BG) signal, 
*        data from the device (edata), and DMA command (cmd)
* output: bus request (BR) signal
*         write enable (WRITE) signal
*         memory address (addr) to be written by the device, 
*         offset device offset (0 - 2)
*         data that will be written to the memory
*         interrupt to notify DMA is end
* You should NOT change the name of the I/O ports and the module name
* You can (or may have to) change the type and length of I/O ports 
* (e.g., wire -> reg) if you want 
* Do not add more ports! 
*************************************************/

module DMA (
    input CLK, BG,
    input [4 * `WORD_SIZE - 1 : 0] edata,
    input cmd,
    output reg BR, 
    output wire WRITE,
    output reg [`WORD_SIZE - 1 : 0] addr, 
    output reg [4 * `WORD_SIZE - 1 : 0] data,
    output reg [1:0] offset,
    output reg interrupt  // DMA End
    );

    reg w_complete;
    reg [`WORD_SIZE-1:0] req_addr;
    reg [`WORD_SIZE-1:0] req_length;
    reg [2:0] cnt;
    reg [2:0] cnt_m;

    /* Implement your own logic */
    assign WRITE = (BG==1)? 1: 0;
    initial begin
        w_complete=0;
        req_addr=16'h1f4;
        req_length=12;
        cnt=0;
        BR=0;
        interrupt=0;
        addr = 0;
        data = 0;
        cnt_m=0;
    end    
        
    always@(posedge cmd) begin
        BR=1;
    end
    
    always@(posedge CLK) begin
        if(BG == 0) begin 
            cnt_m = 0;
            cnt=0;
        end
        //1. CPU gives DMA command
        
        //2. DMA BR=1
        
        //3. CPU stop using addr/data bus & RD/WR
        
        //4. CPU BG=1
        
        //5. DMA write(CPU runs only with cache)
        if(BG == 1) begin
            if(cnt < 3) begin
               if(cnt_m == 6) begin
                   cnt = cnt + 1;
                   cnt_m = 0;
               end
               offset = cnt;
               addr = req_addr + cnt*4;
               data = edata;
               cnt_m = cnt_m + 1;
            end
            else begin
                BR = 0;
                cnt=0;
            end
        end
        
        //6. DMA clear BR
        
        //7. CPU clear BG
        
        //8. DMA DMA end interrupt
    end
    
    always@(negedge BG) begin
        interrupt = 1;
        #(`INTTERRUPT_DURATION);
        interrupt <=  0;
    end

endmodule
