module tag_ram_tb;

    logic clk, rst_n;

    // Read port
    logic [6:0]  rd_index;
    logic [17:0] rd_tag_w0, rd_tag_w1, rd_tag_w2, rd_tag_w3;
    logic        rd_valid_w0, rd_valid_w1, rd_valid_w2, rd_valid_w3;
    logic [1:0]  rd_victim_way;
    logic [2:0]  rd_plru_bits;

    // Write port
    logic        wr_en;
    logic [6:0]  wr_index;
    logic [1:0]  wr_way;
    logic [17:0] wr_tag;
    logic        wr_valid_bit;

    // PLRU update
    logic        plru_update_en;
    logic [6:0]  plru_index;
    logic [1:0]  plru_way_used;

    tag_ram dut (.*);

    int pass_count = 0;
    int fail_count = 0;

    always #5 clk = ~clk;

    task write_tag(input logic [6:0] idx, input logic [1:0] way,
                   input logic [17:0] tag, input logic vld);
        @(negedge clk);
        wr_en = 1; wr_index = idx; wr_way = way; wr_tag = tag; wr_valid_bit = vld;
        @(posedge clk); #1;
        wr_en = 0;
    endtask

    task update_plru(input logic [6:0] idx, input logic [1:0] way);
        @(negedge clk);
        plru_update_en = 1; plru_index = idx; plru_way_used = way;
        @(posedge clk); #1;
        plru_update_en = 0;
    endtask

    initial begin
        $display("\n===== tag_ram Testbench =====\n");
        clk = 0; rst_n = 0;
        wr_en = 0; wr_index = 0; wr_way = 0; wr_tag = 0; wr_valid_bit = 0;
        plru_update_en = 0; plru_index = 0; plru_way_used = 0;
        rd_index = 0;

        // Let reset propagate
        @(posedge clk); @(posedge clk);
        #1;

        // ---- Test 1: All valid bits zero after reset ----
        rd_index = 7'd0;
        #1;
        if (rd_valid_w0 === 0 && rd_valid_w1 === 0 && rd_valid_w2 === 0 && rd_valid_w3 === 0) begin
            $display("[PASS] Reset: all valid bits are 0 for set 0");
            pass_count++;
        end else begin
            $display("[FAIL] Reset: valid bits not cleared");
            fail_count++;
        end

        rd_index = 7'd127;
        #1;
        if (rd_valid_w0 === 0 && rd_valid_w1 === 0 && rd_valid_w2 === 0 && rd_valid_w3 === 0) begin
            $display("[PASS] Reset: all valid bits are 0 for set 127");
            pass_count++;
        end else begin
            $display("[FAIL] Reset: valid bits not cleared for set 127");
            fail_count++;
        end

        // ---- Test 2: PLRU bits zero after reset ----
        rd_index = 7'd0;
        #1;
        if (rd_plru_bits === 3'b000) begin
            $display("[PASS] Reset: PLRU bits are 000 for set 0");
            pass_count++;
        end else begin
            $display("[FAIL] Reset: PLRU bits = %03b (expected 000)", rd_plru_bits);
            fail_count++;
        end

        // Release reset
        rst_n = 1;

        // ---- Test 3: Write and read back tag to set 10, way 0 ----
        write_tag(7'd10, 2'd0, 18'hABCDE, 1'b1);
        rd_index = 7'd10; #1;
        if (rd_tag_w0 === 18'hABCDE && rd_valid_w0 === 1) begin
            $display("[PASS] Write/read: set 10 way 0 tag=0x%05h valid=%0b", rd_tag_w0, rd_valid_w0);
            pass_count++;
        end else begin
            $display("[FAIL] Write/read: set 10 way 0 tag=0x%05h valid=%0b", rd_tag_w0, rd_valid_w0);
            fail_count++;
        end

        // ---- Test 4: Write to different ways in same set ----
        write_tag(7'd10, 2'd1, 18'h11111, 1'b1);
        write_tag(7'd10, 2'd2, 18'h22222, 1'b1);
        write_tag(7'd10, 2'd3, 18'h33333, 1'b1);
        rd_index = 7'd10; #1;
        if (rd_tag_w0 === 18'hABCDE && rd_tag_w1 === 18'h11111 &&
            rd_tag_w2 === 18'h22222 && rd_tag_w3 === 18'h33333 &&
            rd_valid_w0 && rd_valid_w1 && rd_valid_w2 && rd_valid_w3) begin
            $display("[PASS] All 4 ways written and read back correctly in set 10");
            pass_count++;
        end else begin
            $display("[FAIL] Multi-way write/read mismatch in set 10");
            $display("       W0=0x%05h W1=0x%05h W2=0x%05h W3=0x%05h",
                     rd_tag_w0, rd_tag_w1, rd_tag_w2, rd_tag_w3);
            fail_count++;
        end

        // ---- Test 5: Write to set 10 does NOT affect set 11 ----
        rd_index = 7'd11; #1;
        if (rd_valid_w0 === 0 && rd_valid_w1 === 0 && rd_valid_w2 === 0 && rd_valid_w3 === 0) begin
            $display("[PASS] Set 11 unaffected by writes to set 10");
            pass_count++;
        end else begin
            $display("[FAIL] Set 11 corrupted by writes to set 10");
            fail_count++;
        end

        // ---- Test 6: Overwrite tag in existing way ----
        write_tag(7'd10, 2'd0, 18'hFFFFF, 1'b1);
        rd_index = 7'd10; #1;
        if (rd_tag_w0 === 18'hFFFFF) begin
            $display("[PASS] Tag overwrite: set 10 way 0 now 0x%05h", rd_tag_w0);
            pass_count++;
        end else begin
            $display("[FAIL] Tag overwrite failed: got 0x%05h", rd_tag_w0);
            fail_count++;
        end

        // ---- Test 7: Invalidate a way ----
        write_tag(7'd10, 2'd1, 18'h11111, 1'b0);
        rd_index = 7'd10; #1;
        if (rd_valid_w1 === 0) begin
            $display("[PASS] Invalidation: set 10 way 1 valid=%0b", rd_valid_w1);
            pass_count++;
        end else begin
            $display("[FAIL] Invalidation did not clear valid bit");
            fail_count++;
        end

        // ---- Test 8: PLRU victim after reset (initial state 000) ----
        // Use a clean set (set 50) with plru = 000
        rd_index = 7'd50; #1;
        $display("[INFO] Set 50 initial PLRU=%03b victim_way=%0d", rd_plru_bits, rd_victim_way);
        // plru=000: bit2=0->left, bit1=0->W1
        if (rd_victim_way === 2'd1) begin
            $display("[PASS] Initial victim for plru=000 is W1");
            pass_count++;
        end else begin
            $display("[FAIL] Initial victim expected W1, got W%0d", rd_victim_way);
            fail_count++;
        end

        // ---- Test 9: PLRU update and victim change ----
        // Access W0 in set 50 -> PLRU should update
        update_plru(7'd50, 2'd0);
        rd_index = 7'd50; #1;
        $display("[INFO] After accessing W0: PLRU=%03b victim_way=%0d", rd_plru_bits, rd_victim_way);
        // NOTE: Due to known PLRU bug, victim may point TO W0 instead of away.
        // With current code: plru={0,1,0}=010, victim: bit2=0->left, bit1=1->W0
        // Expected (correct): victim should NOT be W0
        if (rd_victim_way !== 2'd0) begin
            $display("[PASS] After accessing W0, victim is not W0 (W%0d)", rd_victim_way);
            pass_count++;
        end else begin
            $display("[FAIL] After accessing W0, victim is still W0 (PLRU bug confirmed)");
            fail_count++;
        end

        // ---- Test 10: Successive PLRU updates ----
        // Access W2 in set 50
        update_plru(7'd50, 2'd2);
        rd_index = 7'd50; #1;
        $display("[INFO] After accessing W2: PLRU=%03b victim_way=%0d", rd_plru_bits, rd_victim_way);
        if (rd_victim_way !== 2'd2) begin
            $display("[PASS] After accessing W2, victim is not W2 (W%0d)", rd_victim_way);
            pass_count++;
        end else begin
            $display("[FAIL] After accessing W2, victim is W2 (PLRU bug)");
            fail_count++;
        end

        $display("\n----- Results: %0d PASSED, %0d FAILED -----\n", pass_count, fail_count);
        $finish;
    end

endmodule
