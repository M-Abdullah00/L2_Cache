module input_arbiter (
    input logic clk,
    input logic rst_n,
 
    // CPU side
    input logic cpu_req_valid,
    input logic [31:0] cpu_req_addr,
    input logic cpu_req_write,
    input logic [31:0] cpu_req_wdata,
    input logic [3:0] cpu_req_wstrb,
    output logic cpu_req_ready,
 
    // MSHR replay (high priority)
    input logic mshr_replay_valid,
    input logic [31:0] mshr_replay_addr,
    input logic [1023:0] mshr_replay_line,
 
    // Status
    input logic mshr_full,
    input logic wb_full,
 
    // Winner output
    output logic  win_valid,
    output logic [1:0] win_req_type,   // 00=read  01=write  10=replay
    output logic [31:0] win_addr,
    output logic [31:0] win_wdata,
    output logic [3:0] win_wstrb,
    output logic [1023:0] win_line_data
);
 
    // Request type encoding
    localparam REQ_READ = 2'b00;
    localparam REQ_WRITE = 2'b01;
    localparam REQ_REPLAY = 2'b10;
 
    always_comb begin
        win_valid = 1'b0;
        win_req_type = REQ_READ;
        win_wdata = 32'h0;
        win_wstrb = 4'h0;
        win_addr = 32'h0;
        win_line_data = 1024'h0;
        cpu_req_ready = 1'b0;
 
        if (mshr_replay_valid) begin
            // MSHR replay wins unconditionally
            win_valid = 1'b1;
            win_req_type = REQ_REPLAY;
            win_addr = mshr_replay_addr;
            win_line_data = mshr_replay_line;
 
        end else if (cpu_req_valid && cpu_req_write && !wb_full) begin
            // CPU write
            win_valid = 1'b1;
            win_req_type = REQ_WRITE;
            win_addr = cpu_req_addr;
            win_wdata = cpu_req_wdata;
            win_wstrb = cpu_req_wstrb;
            cpu_req_ready = 1'b1;
 
        end else if (cpu_req_valid && !cpu_req_write && !mshr_full) begin
            // CPU read
            win_valid = 1'b1;
            win_req_type = REQ_READ;
            win_addr = cpu_req_addr;
            win_wstrb = 4'hF;
            cpu_req_ready = 1'b1;
        end
        // else: all outputs already defaulted to zero
    end
 
endmodule