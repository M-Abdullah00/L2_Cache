module pipeline_register2 (
    input  logic clk,
    input  logic rst_n,
 
    input logic in_valid,
    input logic [1:0] in_req_type,
    input logic [31:0] in_addr,
    input logic [31:0] in_wdata,
    input logic [3:0] in_wstrb,
    input logic [1023:0] in_line_data,
    input logic [17:0] in_tag,
    input logic [6:0] in_index,
    input logic [6:0] in_offset,
    input logic [17:0] in_tag_w0,
    input logic [17:0] in_tag_w1,
    input logic [17:0] in_tag_w2,
    input logic [17:0] in_tag_w3,
    input logic in_valid_w0,
    input logic in_valid_w1,
    input logic in_valid_w2,
    input logic in_valid_w3,
    input logic [1:0] in_victim_way,
    input logic [2:0] in_plru_bits,
 
    output logic out_valid,
    output logic [1:0] out_req_type,
    output logic [31:0] out_addr,
    output logic [31:0] out_wdata,
    output logic [3:0] out_wstrb,
    output logic [1023:0] out_line_data,
    output logic [17:0] out_tag,
    output logic [6:0]  out_index,
    output logic [6:0] out_offset,
    output logic [17:0] out_tag_w0,
    output logic [17:0] out_tag_w1,
    output logic [17:0] out_tag_w2,
    output logic [17:0] out_tag_w3,
    output logic out_valid_w0,
    output logic out_valid_w1,
    output logic out_valid_w2,
    output logic out_valid_w3,
    output logic [1:0] out_victim_way,
    output logic [2:0] out_plru_bits
);
 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            out_req_type <= 2'b00;
            out_addr <= 32'h0;
            out_wdata <= 32'h0;
            out_wstrb <= 4'h0;
            out_line_data <= 1024'h0;
            out_tag <= 18'h0;
            out_index <= 7'h0;
            out_offset <= 7'h0;
            out_tag_w0 <= 18'h0;
            out_tag_w1 <= 18'h0;
            out_tag_w2 <= 18'h0;
            out_tag_w3 <= 18'h0;
            out_valid_w0 <= 1'b0;
            out_valid_w1 <= 1'b0;
            out_valid_w2 <= 1'b0;
            out_valid_w3 <= 1'b0;
            out_victim_way <= 2'h0;
            out_plru_bits <= 3'h0;
        
        end else begin
            out_valid <= in_valid;
            out_req_type <= in_req_type;
            out_addr <= in_addr;
            out_wdata <= in_wdata;
            out_wstrb <= in_wstrb;
            out_line_data <= in_line_data;
            out_tag <= in_tag;
            out_index  <= in_index;
            out_offset <= in_offset;
            out_tag_w0 <= in_tag_w0;
            out_tag_w1 <= in_tag_w1;
            out_tag_w2 <= in_tag_w2;
            out_tag_w3 <= in_tag_w3;
            out_valid_w0 <= in_valid_w0;
            out_valid_w1 <= in_valid_w1;
            out_valid_w2 <= in_valid_w2;
            out_valid_w3 <= in_valid_w3;
            out_victim_way <= in_victim_way;
            out_plru_bits <= in_plru_bits;
        end
    end
 
endmodule