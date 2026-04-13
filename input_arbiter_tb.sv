module input_arbiter_tb;

    logic clk, rst_n;

    logic        cpu_req_valid;
    logic [31:0] cpu_req_addr;
    logic        cpu_req_write;
    logic [31:0] cpu_req_wdata;
    logic [3:0]  cpu_req_wstrb;
    logic        cpu_req_ready;

    logic        mshr_replay_valid;
    logic [31:0] mshr_replay_addr;
    logic [1023:0] mshr_replay_line;

    logic mshr_full;
    logic wb_full;

    logic        win_valid;
    logic [1:0]  win_req_type;
    logic [31:0] win_addr;
    logic [31:0] win_wdata;
    logic [3:0]  win_wstrb;
    logic [1023:0] win_line_data;

    input_arbiter dut (.*);

    int pass_count = 0;
    int fail_count = 0;

    localparam REQ_READ   = 2'b00;
    localparam REQ_WRITE  = 2'b01;
    localparam REQ_REPLAY = 2'b10;

    task clear_inputs();
        cpu_req_valid = 0; cpu_req_addr = 0; cpu_req_write = 0;
        cpu_req_wdata = 0; cpu_req_wstrb = 0;
        mshr_replay_valid = 0; mshr_replay_addr = 0; mshr_replay_line = 0;
        mshr_full = 0; wb_full = 0;
    endtask

    task check(input string name,
               input logic  exp_valid,
               input logic [1:0] exp_type,
               input logic  exp_ready);
        #1;
        if (win_valid === exp_valid && win_req_type === exp_type && cpu_req_ready === exp_ready) begin
            $display("[PASS] %s: valid=%0b type=%02b ready=%0b addr=0x%08h",
                     name, win_valid, win_req_type, cpu_req_ready, win_addr);
            pass_count++;
        end else begin
            $display("[FAIL] %s", name);
            $display("       Expected: valid=%0b type=%02b ready=%0b", exp_valid, exp_type, exp_ready);
            $display("       Got:      valid=%0b type=%02b ready=%0b", win_valid, win_req_type, cpu_req_ready);
            fail_count++;
        end
    endtask

    initial begin
        $display("\n===== input_arbiter Testbench =====\n");
        clear_inputs();

        // Test 1: No requests -- idle
        check("Idle", 0, REQ_READ, 0);

        // Test 2: CPU read request
        clear_inputs();
        cpu_req_valid = 1; cpu_req_write = 0; cpu_req_addr = 32'hDEAD_0000;
        check("CPU read", 1, REQ_READ, 1);

        // Test 3: CPU write request
        clear_inputs();
        cpu_req_valid = 1; cpu_req_write = 1;
        cpu_req_addr = 32'hBEEF_0000; cpu_req_wdata = 32'hCAFE; cpu_req_wstrb = 4'hF;
        check("CPU write", 1, REQ_WRITE, 1);

        // Test 4: MSHR replay beats CPU request (priority)
        clear_inputs();
        cpu_req_valid = 1; cpu_req_write = 0; cpu_req_addr = 32'h1111_0000;
        mshr_replay_valid = 1; mshr_replay_addr = 32'h2222_0000;
        check("Replay > CPU", 1, REQ_REPLAY, 0);

        // Test 5: CPU read blocked when MSHR full
        clear_inputs();
        cpu_req_valid = 1; cpu_req_write = 0; cpu_req_addr = 32'hAAAA_0000;
        mshr_full = 1;
        check("Read blocked (MSHR full)", 0, REQ_READ, 0);

        // Test 6: CPU write blocked when WB full
        clear_inputs();
        cpu_req_valid = 1; cpu_req_write = 1;
        cpu_req_addr = 32'hBBBB_0000; cpu_req_wdata = 32'h99;
        wb_full = 1;
        check("Write blocked (WB full)", 0, REQ_READ, 0);

        // Test 7: MSHR replay works even when MSHR/WB full
        clear_inputs();
        mshr_replay_valid = 1; mshr_replay_addr = 32'hCCCC_0000;
        mshr_full = 1; wb_full = 1;
        check("Replay ignores full flags", 1, REQ_REPLAY, 0);

        // Test 8: Write has priority over read (both valid)
        clear_inputs();
        cpu_req_valid = 1; cpu_req_write = 1;
        cpu_req_addr = 32'hDDDD_0000; cpu_req_wdata = 32'hFF;
        cpu_req_wstrb = 4'hF;
        check("Write > Read (write flag set)", 1, REQ_WRITE, 1);

        $display("\n----- Results: %0d PASSED, %0d FAILED -----\n", pass_count, fail_count);
        $finish;
    end

endmodule
