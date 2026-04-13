module comparator_tb;

    logic [17:0] req_tag;
    logic [17:0] tag_w0, tag_w1, tag_w2, tag_w3;
    logic        valid_w0, valid_w1, valid_w2, valid_w3;
    logic        hit;
    logic [1:0]  hit_way;
    logic [3:0]  hit_way_oh;

    comparator dut (.*);

    int pass_count = 0;
    int fail_count = 0;

    task check(input string name,
               input logic  exp_hit,
               input logic [1:0] exp_way);
        #1;
        if (hit === exp_hit && (exp_hit == 0 || hit_way === exp_way)) begin
            $display("[PASS] %s: hit=%0b way=%0d oh=%04b", name, hit, hit_way, hit_way_oh);
            pass_count++;
        end else begin
            $display("[FAIL] %s: expected hit=%0b way=%0d, got hit=%0b way=%0d oh=%04b",
                     name, exp_hit, exp_way, hit, hit_way, hit_way_oh);
            fail_count++;
        end
    endtask

    initial begin
        $display("\n===== comparator Testbench =====\n");

        // Test 1: Hit on way 0
        req_tag = 18'hAAAA;
        {tag_w0, tag_w1, tag_w2, tag_w3} = {18'hAAAA, 18'hBBBB, 18'hCCCC, 18'hDDDD};
        {valid_w0, valid_w1, valid_w2, valid_w3} = 4'b1111;
        check("Hit W0", 1, 2'd0);

        // Test 2: Hit on way 1
        req_tag = 18'hBBBB;
        check("Hit W1", 1, 2'd1);

        // Test 3: Hit on way 2
        req_tag = 18'hCCCC;
        check("Hit W2", 1, 2'd2);

        // Test 4: Hit on way 3
        req_tag = 18'hDDDD;
        check("Hit W3", 1, 2'd3);

        // Test 5: Miss (no tag match)
        req_tag = 18'h1234;
        check("Miss (no match)", 0, 2'dx);

        // Test 6: Tag matches but valid=0 (should miss)
        req_tag = 18'hAAAA;
        {valid_w0, valid_w1, valid_w2, valid_w3} = 4'b0000;
        check("Miss (all invalid)", 0, 2'dx);

        // Test 7: Tag matches W2 but only W2 is valid
        {valid_w0, valid_w1, valid_w2, valid_w3} = 4'b0100;
        req_tag = 18'hCCCC;
        check("Hit W2 (only W2 valid)", 1, 2'd2);

        // Test 8: Duplicate tags across ways -- W0 valid only
        tag_w0 = 18'h5555; tag_w1 = 18'h5555; tag_w2 = 18'h5555; tag_w3 = 18'h5555;
        {valid_w0, valid_w1, valid_w2, valid_w3} = 4'b0001;
        req_tag = 18'h5555;
        check("Dup tags, only W0 valid", 1, 2'd0);

        $display("\n----- Results: %0d PASSED, %0d FAILED -----\n", pass_count, fail_count);
        $finish;
    end

endmodule
