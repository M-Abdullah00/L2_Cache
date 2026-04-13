module add_split_tb;

    logic [31:0] addr_in;
    logic [17:0] tag_out;
    logic [6:0]  index_out;
    logic [6:0]  offset_out;

    add_split dut (.*);

    int pass_count = 0;
    int fail_count = 0;

    task check(input string name,
               input logic [31:0] addr,
               input logic [17:0] exp_tag,
               input logic [6:0]  exp_idx,
               input logic [6:0]  exp_off);
        addr_in = addr;
        #1;
        if (tag_out === exp_tag && index_out === exp_idx && offset_out === exp_off) begin
            $display("[PASS] %s: addr=0x%08h -> tag=0x%05h idx=%0d off=%0d",
                     name, addr, tag_out, index_out, offset_out);
            pass_count++;
        end else begin
            $display("[FAIL] %s: addr=0x%08h", name, addr);
            $display("       Expected: tag=0x%05h idx=%0d off=%0d", exp_tag, exp_idx, exp_off);
            $display("       Got:      tag=0x%05h idx=%0d off=%0d", tag_out, index_out, offset_out);
            fail_count++;
        end
    endtask

    initial begin
        $display("\n===== add_split Testbench =====\n");

        //                     addr         tag     index  offset
        check("All zeros",    32'h0000_0000, 18'h0,  7'd0,  7'd0);
        check("All ones",     32'hFFFF_FFFF, 18'h3FFFF, 7'd127, 7'd127);
        check("Tag only",     32'hABCD_0000, 18'h2AF34, 7'd0,   7'd0);
        check("Index only",   32'h0000_2F80, 18'h0,     7'd95,  7'd0);
        check("Offset only",  32'h0000_003F, 18'h0,     7'd0,   7'd63);
        check("Mixed",        32'h1234_5678, 18'h048D1, 7'd44,  7'd120);

        $display("\n----- Results: %0d PASSED, %0d FAILED -----\n", pass_count, fail_count);
        $finish;
    end

endmodule
