module pipeline_register1_tb;

    logic clk, rst_n;

    // Inputs
    logic        in_valid;
    logic [1:0]  in_req_type;
    logic [31:0] in_addr;
    logic [31:0] in_wdata;
    logic [3:0]  in_wstrb;
    logic [1023:0] in_line_data;
    logic [17:0] in_tag;
    logic [6:0]  in_index;
    logic [6:0]  in_offset;
    logic [17:0] in_tag_w0, in_tag_w1, in_tag_w2, in_tag_w3;
    logic        in_valid_w0, in_valid_w1, in_valid_w2, in_valid_w3;
    logic [1:0]  in_victim_way;
    logic [2:0]  in_plru_bits;

    // Outputs
    logic        out_valid;
    logic [1:0]  out_req_type;
    logic [31:0] out_addr;
    logic [31:0] out_wdata;
    logic [3:0]  out_wstrb;
    logic [1023:0] out_line_data;
    logic [17:0] out_tag;
    logic [6:0]  out_index;
    logic [6:0]  out_offset;
    logic [17:0] out_tag_w0, out_tag_w1, out_tag_w2, out_tag_w3;
    logic        out_valid_w0, out_valid_w1, out_valid_w2, out_valid_w3;
    logic [1:0]  out_victim_way;
    logic [2:0]  out_plru_bits;

    pipeline_register1 dut (.*);

    int pass_count = 0;
    int fail_count = 0;

    always #5 clk = ~clk;

    task automatic check_field(input string name, input logic [31:0] got, input logic [31:0] exp);
        if (got !== exp) begin
            $display("[FAIL] %s: expected 0x%0h got 0x%0h", name, exp, got);
            fail_count++;
        end
    endtask

    initial begin
        $display("\n===== pipeline_register1 Testbench =====\n");
        clk = 0; rst_n = 0;
        in_valid = 0; in_req_type = 0; in_addr = 0; in_wdata = 0; in_wstrb = 0;
        in_line_data = 0; in_tag = 0; in_index = 0; in_offset = 0;
        in_tag_w0 = 0; in_tag_w1 = 0; in_tag_w2 = 0; in_tag_w3 = 0;
        in_valid_w0 = 0; in_valid_w1 = 0; in_valid_w2 = 0; in_valid_w3 = 0;
        in_victim_way = 0; in_plru_bits = 0;

        // Test 1: Reset clears all outputs
        @(posedge clk); #1;
        if (out_valid === 0 && out_addr === 0 && out_tag === 0 && out_index === 0) begin
            $display("[PASS] Reset clears all outputs");
            pass_count++;
        end else begin
            $display("[FAIL] Reset did not clear outputs");
            fail_count++;
        end

        // Release reset
        rst_n = 1;

        // Test 2: Data latches on posedge
        @(negedge clk);
        in_valid = 1; in_req_type = 2'b01; in_addr = 32'hDEAD_BEEF;
        in_wdata = 32'hCAFE_BABE; in_wstrb = 4'hA;
        in_tag = 18'h1ABCD; in_index = 7'd99; in_offset = 7'd55;
        in_tag_w0 = 18'h11111; in_tag_w1 = 18'h22222; in_tag_w2 = 18'h33333; in_tag_w3 = 18'h04444;
        in_valid_w0 = 1; in_valid_w1 = 0; in_valid_w2 = 1; in_valid_w3 = 1;
        in_victim_way = 2'd3; in_plru_bits = 3'b101;

        @(posedge clk); #1;
        begin
            int local_fail = fail_count;
            check_field("valid",      out_valid,      1);
            check_field("req_type",   out_req_type,   2'b01);
            check_field("addr",       out_addr,       32'hDEAD_BEEF);
            check_field("wdata",      out_wdata,      32'hCAFE_BABE);
            check_field("wstrb",      out_wstrb,      4'hA);
            check_field("tag",        out_tag,        18'h1ABCD);
            check_field("index",      out_index,      7'd99);
            check_field("offset",     out_offset,     7'd55);
            check_field("tag_w0",     out_tag_w0,     18'h11111);
            check_field("tag_w1",     out_tag_w1,     18'h22222);
            check_field("tag_w2",     out_tag_w2,     18'h33333);
            check_field("tag_w3",     out_tag_w3,     18'h04444);
            check_field("valid_w0",   out_valid_w0,   1);
            check_field("valid_w1",   out_valid_w1,   0);
            check_field("valid_w2",   out_valid_w2,   1);
            check_field("valid_w3",   out_valid_w3,   1);
            check_field("victim_way", out_victim_way, 2'd3);
            check_field("plru_bits",  out_plru_bits,  3'b101);
            if (fail_count == local_fail) begin
                $display("[PASS] Data latched correctly on posedge");
                pass_count++;
            end
        end

        // Test 3: Output holds when input changes mid-cycle (before next edge)
        @(negedge clk);
        in_addr = 32'h1111_2222;
        #1;
        if (out_addr === 32'hDEAD_BEEF) begin
            $display("[PASS] Output holds old value before next posedge");
            pass_count++;
        end else begin
            $display("[FAIL] Output changed before clock edge");
            fail_count++;
        end

        // New data captured on next posedge
        @(posedge clk); #1;
        if (out_addr === 32'h1111_2222) begin
            $display("[PASS] New data captured on next posedge");
            pass_count++;
        end else begin
            $display("[FAIL] New data not captured");
            fail_count++;
        end

        // Test 4: Reset mid-operation
        @(negedge clk);
        rst_n = 0;
        @(posedge clk); #1;
        if (out_valid === 0 && out_addr === 0 && out_tag === 0) begin
            $display("[PASS] Mid-operation reset clears outputs");
            pass_count++;
        end else begin
            $display("[FAIL] Mid-operation reset did not clear outputs");
            fail_count++;
        end

        $display("\n----- Results: %0d PASSED, %0d FAILED -----\n", pass_count, fail_count);
        $finish;
    end

endmodule
