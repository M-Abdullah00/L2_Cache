module pipeline_register2_tb;

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

    pipeline_register2 dut (.*);

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
        $display("\n===== pipeline_register2 Testbench =====\n");
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

        // Test 2: Data latches correctly
        @(negedge clk);
        in_valid = 1; in_req_type = 2'b10; in_addr = 32'hFACE_F00D;
        in_wdata = 32'h1234_5678; in_wstrb = 4'h5;
        in_tag = 18'h2BCDE; in_index = 7'd42; in_offset = 7'd77;
        in_tag_w0 = 18'hAAAAA; in_tag_w1 = 18'hBBBBB; in_tag_w2 = 18'hCCCCC; in_tag_w3 = 18'hDDDDD;
        in_valid_w0 = 1; in_valid_w1 = 1; in_valid_w2 = 0; in_valid_w3 = 1;
        in_victim_way = 2'd2; in_plru_bits = 3'b110;

        @(posedge clk); #1;
        begin
            int local_fail = fail_count;
            check_field("valid",      out_valid,      1);
            check_field("req_type",   out_req_type,   2'b10);
            check_field("addr",       out_addr,       32'hFACE_F00D);
            check_field("wdata",      out_wdata,      32'h1234_5678);
            check_field("wstrb",      out_wstrb,      4'h5);
            check_field("tag",        out_tag,        18'h2BCDE);
            check_field("index",      out_index,      7'd42);
            check_field("offset",     out_offset,     7'd77);
            check_field("tag_w0",     out_tag_w0,     18'hAAAAA);
            check_field("tag_w1",     out_tag_w1,     18'hBBBBB);
            check_field("tag_w2",     out_tag_w2,     18'hCCCCC);
            check_field("tag_w3",     out_tag_w3,     18'hDDDDD);
            check_field("valid_w0",   out_valid_w0,   1);
            check_field("valid_w1",   out_valid_w1,   1);
            check_field("valid_w2",   out_valid_w2,   0);
            check_field("valid_w3",   out_valid_w3,   1);
            check_field("victim_way", out_victim_way, 2'd2);
            check_field("plru_bits",  out_plru_bits,  3'b110);
            if (fail_count == local_fail) begin
                $display("[PASS] All fields latched correctly");
                pass_count++;
            end
        end

        // Test 3: Back-to-back transfers
        @(negedge clk);
        in_valid = 1; in_req_type = 2'b00; in_addr = 32'hAAAA_BBBB;
        in_tag = 18'h3FFFF; in_index = 7'd127; in_offset = 7'd0;
        @(posedge clk); #1;

        @(negedge clk);
        in_valid = 0; in_addr = 32'hCCCC_DDDD;
        in_tag = 18'h00001; in_index = 7'd1;

        // First transfer should be visible now
        if (out_addr === 32'hAAAA_BBBB && out_valid === 1) begin
            $display("[PASS] Back-to-back: first transfer visible");
            pass_count++;
        end else begin
            $display("[FAIL] Back-to-back: first transfer not visible");
            fail_count++;
        end

        @(posedge clk); #1;
        if (out_addr === 32'hCCCC_DDDD && out_valid === 0) begin
            $display("[PASS] Back-to-back: second transfer visible");
            pass_count++;
        end else begin
            $display("[FAIL] Back-to-back: second transfer not visible");
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
