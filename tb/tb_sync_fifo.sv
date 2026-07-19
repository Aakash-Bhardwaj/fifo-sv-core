`timescale 1ns/1ps

module tb_sync_fifo;

    // Configuration parameters
    localparam int DATA_WIDTH        = 8;
    localparam int DEPTH             = 8;
    localparam int LEVEL_WIDTH       = $clog2(DEPTH + 1);
    `ifdef FWFT_MODE
        localparam bit FWFT          = 1;
    `else
        localparam bit FWFT          = 0;
    `endif
    localparam int AFULL_THRESHOLD   = DEPTH - 1;
    localparam int AEMPTY_THRESHOLD  = 1;

    // Parameters for reference and timing
    localparam time CLOCK_PERIOD_NS  = 10ns;
    localparam int RANDOM_ITERATIONS = 10000;
    localparam int TIMEOUT_CYCLES    = 19000 + RANDOM_ITERATIONS;
    localparam int RESET_CYCLES      = 3;

    // DUT Signals
    logic                   clk;
    logic                   rst_n;
    logic                   wr_en;
    logic                   rd_en;
    logic [DATA_WIDTH-1:0]  wr_data;
    logic [DATA_WIDTH-1:0]  rd_data;
    logic                   full;
    logic                   empty;
    logic                   almost_full;
    logic                   almost_empty;
    logic                   overflow;
    logic                   underflow;
    logic [LEVEL_WIDTH-1:0] level;

    // Verification statistics
    int tests_run    = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    // Reference Model
    logic [DATA_WIDTH-1:0] expected_queue[$];
    logic [DATA_WIDTH-1:0] expected_rd_data;
    logic [DATA_WIDTH-1:0] expected_rd_data_reg;
    bit expected_full, expected_empty,
        expected_afull, expected_aempty,
        expected_overflow, expected_underflow;
    bit transaction_accepted;

    // Test Variable
    logic [DATA_WIDTH-1:0] test_data;
    logic [1:0] operation;
    bit wr_accepted, rd_accepted;
    bit stress_passed;

    // DUT Instantiation
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .LEVEL_WIDTH(LEVEL_WIDTH),
        .FWFT(FWFT),
        .AFULL_THRESHOLD(AFULL_THRESHOLD),
        .AEMPTY_THRESHOLD(AEMPTY_THRESHOLD)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .full(full),
        .empty(empty),
        .almost_full(almost_full),
        .almost_empty(almost_empty),
        .overflow(overflow),
        .underflow(underflow),
        .level(level)
    );

    // Assertions
    sva_sync_fifo #(
        .DEPTH(DEPTH),
        .LEVEL_WIDTH(LEVEL_WIDTH),
        .AFULL_THRESHOLD(AFULL_THRESHOLD),
        .AEMPTY_THRESHOLD(AEMPTY_THRESHOLD)
    ) sva (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .full(full),
        .empty(empty),
        .almost_full(almost_full),
        .almost_empty(almost_empty),
        .overflow(overflow),
        .underflow(underflow),
        .level(level)
    );

    // Clock generation
    initial clk = 1'b0;
    always #(CLOCK_PERIOD_NS/2.0) clk = ~clk;

    // Timeout watchdog
    initial begin
        repeat(TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1,"[TIMEOUT] Simulation hung! Watchdog triggered after %0d cycles.", TIMEOUT_CYCLES);
    end

    // Waveform generation
    initial begin
        `ifdef FWFT_MODE
            $dumpfile("fwft_fifo_waveform.vcd");
        `else
            $dumpfile("standard_fifo_waveform.vcd");
        `endif
        $dumpvars(0, tb_sync_fifo);
    end

    // Record test results
    task automatic record_test(input string test_name, input bit passed);
        begin
            tests_run++;
            if (passed) begin
                tests_passed++;
                $display("[PASS] %s", test_name);
            end else begin
                tests_failed++;
                $error("[FAIL] %s", test_name);
            end
        end
    endtask

    // Helper tasks

    // Apply reset
    task automatic apply_reset;
        begin
            // Apply Reset
            rst_n   = 1'b0;
            wr_en   = 1'b0;
            rd_en   = 1'b0;
            wr_data = '0;

            // Reference model also reset
            expected_queue.delete();
            expected_rd_data_reg     = '0;
            transaction_accepted =  0;

            // Hold reset
            repeat(RESET_CYCLES) @(posedge clk);

            // Release reset
            rst_n = 1'b1;

            @(posedge clk);
        end
    endtask

    // Drive write
    task automatic drive_write(
        input logic [DATA_WIDTH-1:0] data
        );
        begin
            // Assert write
            @(negedge clk);
            wr_en   = 1'b1;
            wr_data = data;

            // Valid for 1 clock cycle
            @(posedge clk);

            // Deassert write
            @(negedge clk);
            wr_en = 1'b0;
            #1;
        end
    endtask

    // Drive read
    task automatic drive_read();
        begin
            // Assert read
            @(negedge clk);
            rd_en   = 1'b1;

            // Valid for 1 clock cycle
            @(posedge clk);

            // Deassert read
            @(negedge clk);
            rd_en = 1'b0;
            #1;
        end
    endtask

    // Write FIFO
    task automatic fifo_write(
        input logic [DATA_WIDTH-1:0] data
    );
        begin
            // Check if write is to be accepted
            transaction_accepted = (expected_queue.size() < DEPTH);

            // Drive write
            drive_write(data);

            // Update reference model queue
            if (transaction_accepted) begin
                expected_queue.push_back(data);
            end
        end
    endtask

    // Read FIFO
    task automatic fifo_read();
        begin
            // Check if read is to be accepted
            transaction_accepted = (expected_queue.size() > 0);

            // Drive read
            drive_read();

            // Update reference model queue
            if (transaction_accepted) begin
                expected_rd_data_reg = expected_queue.pop_front();
            end
        end
    endtask

    // Update expected flags
    task automatic update_flags();
        begin
            expected_full      = (expected_queue.size() == DEPTH);
            expected_empty     = (expected_queue.size() == 0);
            expected_afull     = (expected_queue.size() >= AFULL_THRESHOLD);
            expected_aempty    = (expected_queue.size() <= AEMPTY_THRESHOLD);
            expected_overflow  = (wr_en && (expected_queue.size() == DEPTH));
            expected_underflow = (rd_en && (expected_queue.size() == 0));

            if (FWFT) begin
                if (expected_queue.size() > 0) begin
                    expected_rd_data = expected_queue[0];
                end else begin
                    expected_rd_data = '0;
                end
            end else begin
                expected_rd_data = expected_rd_data_reg;
            end
        end
    endtask

    // Print Summary
    task automatic print_summary;
        begin

            $display("\n==================================================");
            $display("             FIFO TEST SUMMARY");
            $display("==================================================");

            $display("Tests Run    : %0d", tests_run);
            $display("Tests Passed : %0d", tests_passed);
            $display("Tests Failed : %0d", tests_failed);

            if (tests_failed == 0)
                $display("OVERALL RESULT : PASS");
            else
                $display("OVERALL RESULT : FAIL");

            $display("==================================================");

        end
    endtask

    // Helper tasks end

    // Test tasks

    // Reset behaviour test
    task automatic test_reset();
        begin
            apply_reset();
            update_flags();

            record_test("FULL deasserted", full == expected_full);
            record_test("EMPTY asserted", empty == expected_empty);
            record_test("ALMOST FULL deasserted", almost_full == expected_afull);
            record_test("ALMOST EMPTY asserted", almost_empty == expected_aempty);
            record_test("OVERFLOW deasserted", overflow == expected_overflow);
            record_test("UNDERFLOW deasserted", underflow == expected_underflow);
            record_test("Occupancy cleared", level == expected_queue.size());
        end
    endtask

    // One write test
    task automatic test_one_write();
        begin
            // Generate random data
            test_data = $urandom;
            // Write data and update outputs
            fifo_write(test_data);
            update_flags();

            record_test("Check FULL", (full == expected_full));
            record_test("Check EMPTY", (empty == expected_empty));
            record_test("Check ALMOST FULL", (almost_full == expected_afull));
            record_test("Check ALMOST EMPTY",(almost_empty == expected_aempty));
            record_test("Check OVERFLOW", (overflow == expected_overflow));
            record_test("Check UNDERFLOW", (underflow == expected_underflow));
            record_test("Check Occupancy", level == expected_queue.size());
        end
    endtask

    // One read test
    task automatic test_one_read();
        begin
            // Read data and update outputs
            fifo_read();
            update_flags();

            record_test("Check rd_data", (rd_data == expected_rd_data));
            record_test("Check FULL", (full == expected_full));
            record_test("Check EMPTY", (empty == expected_empty));
            record_test("Check ALMOST FULL", (almost_full == expected_afull));
            record_test("Check ALMOST EMPTY",(almost_empty == expected_aempty));
            record_test("Check OVERFLOW", (overflow == expected_overflow));
            record_test("Check UNDERFLOW", (underflow == expected_underflow));
            record_test("Check Occupancy", (level == expected_queue.size()));
        end
    endtask

    // Multiple write test
    task automatic test_multi_write(int num);
        begin
            for (int i = 0; i < num; i++) begin
                $display("Write %0d", i+1);
                test_one_write();
            end
        end
    endtask

    // Multiple read test
    task automatic test_multi_read(int num);
        begin
            for (int i = 0; i < num; i++) begin
                $display("Read %0d", i+1);
                test_one_read();
            end
        end
    endtask

    // Full FIFO behaviour test
    task automatic test_fill_fifo();
        begin
            // Reset before attempting to fill
            apply_reset();
            // Filling the FIFO
            for (int i = 0; i < DEPTH; i++) begin
                test_data = $urandom;
                fifo_write(test_data);
            end
            // Update outputs
            update_flags();

            record_test("Check FULL", (full == expected_full));
            record_test("Check EMPTY", (empty == expected_empty));
            record_test("Check ALMOST FULL", (almost_full == expected_afull));
            record_test("Check ALMOST EMPTY",(almost_empty == expected_aempty));
            record_test("Check OVERFLOW", (overflow == expected_overflow));
            record_test("Check UNDERFLOW", (underflow == expected_underflow));
            record_test("Check Occupancy", (level == expected_queue.size()));
        end
    endtask

    // Empty FIFO behaviour test
    task automatic test_empty_fifo();
        begin
            // Emptying the FIFO
            for (int i = DEPTH; i > 0; i--) begin
                fifo_read();
            end
            // Update outputs
            update_flags();

            record_test("Check rd_data", (rd_data == expected_rd_data));
            record_test("Check FULL", (full == expected_full));
            record_test("Check EMPTY", (empty == expected_empty));
            record_test("Check ALMOST FULL", (almost_full == expected_afull));
            record_test("Check ALMOST EMPTY",(almost_empty == expected_aempty));
            record_test("Check OVERFLOW", (overflow == expected_overflow));
            record_test("Check UNDERFLOW", (underflow == expected_underflow));
            record_test("Check Occupancy", (level == expected_queue.size()));
        end
    endtask

    // Overflow behaviour test
    task automatic test_overflow();
        begin
            // Fill FIFO and verify
            $display("Filled FIFO Verification");
            test_fill_fifo();

            // Assert wr_en
            @(negedge clk);
            wr_en = 1'b1;

            // Update outputs and verify
            @(posedge clk); #1;
            update_flags();
            $display("Overflow State Verification");

            record_test("Check FULL", (full == expected_full));
            record_test("Check EMPTY", (empty == expected_empty));
            record_test("Check ALMOST FULL", (almost_full == expected_afull));
            record_test("Check ALMOST EMPTY",(almost_empty == expected_aempty));
            record_test("Check OVERFLOW", (overflow == expected_overflow));
            record_test("Check UNDERFLOW", (underflow == expected_underflow));
            record_test("Check Occupancy", (level == expected_queue.size()));

            // Deassert wr_en
            @(negedge clk);
            wr_en = 1'b0;

            @(posedge clk); #1;
            update_flags();
            record_test("Check OVERFLOW after wr_en deasserted", (overflow == expected_overflow));
        end
    endtask

    // Underflow behaviour test
    task automatic test_underflow();
        begin
            // Empty FIFO and verify
            $display("Empty FIFO Verification");
            test_empty_fifo();

            // Assert rd_en
            @(negedge clk);
            rd_en = 1'b1;

            // Update outputs and verify
            @(posedge clk); #1;
            update_flags();
            $display("Underflow State Verification");

            record_test("Check rd_data", (rd_data == expected_rd_data));
            record_test("Check FULL", (full == expected_full));
            record_test("Check EMPTY", (empty == expected_empty));
            record_test("Check ALMOST FULL", (almost_full == expected_afull));
            record_test("Check ALMOST EMPTY",(almost_empty == expected_aempty));
            record_test("Check OVERFLOW", (overflow == expected_overflow));
            record_test("Check UNDERFLOW", (underflow == expected_underflow));
            record_test("Check Occupancy", (level == expected_queue.size()));

            // Deassert rd_en
            @(negedge clk);
            rd_en = 1'b0;

            @(posedge clk); #1;
            update_flags();
            record_test("Check UNDERFLOW after rd_en deasserted",(underflow == expected_underflow));
        end
    endtask

    // Overflow data integrity
    task automatic test_wr_ignore();
        begin
            // Reset before filling
            apply_reset();

            // Filling the FIFO and verifying
            for (int i = 0; i < DEPTH; i++) begin
                test_data = $urandom;
                fifo_write(test_data);
            end
            update_flags();
            record_test("Check if FIFO is full", full == 1'b1);

            // Attempt to write
            @(negedge clk);
            wr_en = 1'b1;
            test_data = $urandom;
            wr_data = test_data;

            // Check if write attempted
            @(posedge clk); #1;
            update_flags();
            record_test("Check if write attempted", overflow == 1'b1);

            @(negedge clk);
            wr_en = 1'b0;

            // Check if data integrity maintained
            $display("Verifying FIFO data integrity:");
            for (int i = 0; i < DEPTH; i++) begin
                fifo_read();
                update_flags();
                record_test($sformatf("Read %0d", i + 1), rd_data == expected_rd_data);
            end
        end
    endtask

    // Almost full behaviour test
    task automatic test_afull();
        begin
            apply_reset();

            for (int i = 0; i < AFULL_THRESHOLD; i++) begin
                test_data = $urandom;
                fifo_write(test_data);
            end

            update_flags();

            record_test("Check FULL", (full == expected_full));
            record_test("Check EMPTY", (empty == expected_empty));
            record_test("Check ALMOST FULL", (almost_full == expected_afull));
            record_test("Check ALMOST EMPTY",(almost_empty == expected_aempty));
            record_test("Check OVERFLOW", (overflow == expected_overflow));
            record_test("Check UNDERFLOW", (underflow == expected_underflow));
            record_test("Check Occupancy", (level == expected_queue.size()));
        end
    endtask

    // Almost empty behaviour test
    task automatic test_aempty();
        begin
            apply_reset();

            for (int i = 0; i <= AEMPTY_THRESHOLD; i++) begin
                test_data = $urandom;
                fifo_write(test_data);
            end

            update_flags();

            record_test("Check FULL", (full == expected_full));
            record_test("Check EMPTY", (empty == expected_empty));
            record_test("Check ALMOST FULL", (almost_full == expected_afull));
            record_test("Check ALMOST EMPTY",(almost_empty == expected_aempty));
            record_test("Check OVERFLOW", (overflow == expected_overflow));
            record_test("Check UNDERFLOW", (underflow == expected_underflow));
            record_test("Check Occupancy", (level == expected_queue.size()));
        end
    endtask

    // Simultaneous read write when full
    task automatic test_simultaneous_rw_full();
        begin
            // Reset before filling
            apply_reset();

            // Filling the FIFO and verifying
            for (int i = 0; i < DEPTH; i++) begin
                test_data = $urandom;
                fifo_write(test_data);
            end
            update_flags();
            record_test("Check if FIFO is full", full == 1'b1);
            record_test("Check if occupancy is correct", level == DEPTH);

            // Read and write
            @(negedge clk);
            test_data = $urandom;
            wr_en   = 1'b1;
            rd_en   = 1'b1;
            wr_data = test_data;

            @(posedge clk); #1;
            expected_rd_data_reg = expected_queue.pop_front();
            update_flags();
            record_test("Check OVERFLOW", overflow == expected_overflow);

            @(negedge clk);
            wr_en = 0;
            rd_en = 0;

            // Verifying
            record_test("Verify read data", rd_data == expected_rd_data);
            update_flags();
            record_test("Check if occupancy decreased by one", level == DEPTH - 1);

            $display("Verifying FIFO data integrity maintained");
            for (int i = 0; i < DEPTH-1; i++) begin
                fifo_read();
                update_flags();
                record_test($sformatf("Read %0d", i + 1), rd_data == expected_rd_data);
            end
            update_flags();
            record_test("Check if empty", empty == 1'b1);
        end
    endtask

    // Simultaneous read write when empty
    task automatic test_simultaneous_rw_empty();
        begin
            // Emptying the FIFO and verifying
            apply_reset();
            update_flags();
            record_test("Check if FIFO is empty", empty == 1'b1);
            record_test("Check if occupancy is correct", level == 0);

            // Read and write
            @(negedge clk);
            test_data = $urandom;
            wr_en   = 1'b1;
            rd_en   = 1'b1;
            wr_data = test_data;

            @(posedge clk); #1;
            expected_queue.push_back(test_data);
            update_flags();
            record_test("Check UNDERFLOW", underflow == expected_underflow);

            @(negedge clk);
            wr_en = 0;
            rd_en = 0;

            // Verifying
            update_flags();
            record_test("Check if occupancy increased to 1", level == 1'b1);

            $display("Verifying write:");
            fifo_read();
            update_flags();
            record_test("Verify written data", rd_data == expected_rd_data);
            record_test("Check if empty", empty == 1'b1);
        end
    endtask

    // Simultaneous read write when partially filled
    task automatic test_simultaneous_rw_pfill();
        begin
            // Reset before filling
            apply_reset();

            // Partially filling the FIFO and verifying
            for (int i = 0; i < DEPTH-2; i++) begin
                test_data = $urandom;
                fifo_write(test_data);
            end
            update_flags();
            record_test("Check if FIFO is partially full", full !== 1'b1 && empty !== 1'b1);
            record_test("Check if occupancy is correct", level == DEPTH - 2);

            // Read and write
            @(negedge clk);
            test_data = $urandom;
            wr_en   = 1'b1;
            rd_en   = 1'b1;
            wr_data = test_data;

            @(posedge clk); #1;
            expected_rd_data_reg = expected_queue.pop_front();
            expected_queue.push_back(test_data);

            @(negedge clk);
            wr_en = 0;
            rd_en = 0;

            // Verifying
            update_flags();
            record_test("Verify read data", rd_data == expected_rd_data);
            record_test("Check if occupancy unchanged", level == DEPTH - 2);

            $display("Verifying FIFO data integrity maintained");
            for (int i = 0; i < DEPTH - 2; i++) begin
                fifo_read();
                update_flags();
                record_test($sformatf("Read %0d", i + 1), rd_data == expected_rd_data);
            end
            update_flags();
            record_test("Check if empty", empty == 1'b1);
        end
    endtask

    // Random stress test
    task automatic test_random_stress();
        begin
            // Reset before test
            apply_reset();

            for (int i = 0; i < RANDOM_ITERATIONS; i++) begin
                // Randomly choose operation
                operation     = $urandom_range(3);
                test_data     = $urandom;
                stress_passed = 1'b1;

                // Drive signals as per chosen operation
                @(negedge clk);
                wr_data = test_data;
                case (operation)
                    2'b00: begin
                        wr_en = 0;
                        rd_en = 0;
                    end
                    2'b01: begin
                        wr_en = 0;
                        rd_en = 1;
                    end
                    2'b10: begin
                        wr_en = 1;
                        rd_en = 0;
                    end
                    2'b11: begin
                        wr_en = 1;
                        rd_en = 1;
                    end
                    default: begin
                        wr_en = 0;
                        rd_en = 0;
                    end
                endcase

                // Determine read write validity
                wr_accepted = wr_en && (expected_queue.size() !== DEPTH);
                rd_accepted = rd_en && (expected_queue.size() !== 0);

                // Update reference model
                @(posedge clk); #1;
                if (rd_accepted)
                    expected_rd_data_reg = expected_queue.pop_front();
                if (wr_accepted)
                    expected_queue.push_back(test_data);

                // Verify data if read occured
                update_flags();
                if (rd_accepted && (rd_data !== expected_rd_data)) begin
                    $error("Iteration %0d : Read Data Mismatch! DUT: %h, REF: %h",
                             i, rd_data, expected_rd_data);
                    stress_passed = 1'b0;
                end

                // Verify Outputs
                if (full !== expected_full) begin
                    $error("Iteration %0d : FULL Mismatch!", i);
                    stress_passed = 1'b0;
                end
                if (empty !== expected_empty) begin
                    $error("Iteration %0d : EMPTY Mismatch!", i);
                    stress_passed = 1'b0;
                end
                if (almost_full !== expected_afull) begin
                    $error("Iteration %0d : ALMOST FULL Mismatch!", i);
                    stress_passed = 1'b0;
                end
                if (almost_empty !== expected_aempty) begin
                    $error("Iteration %0d : ALMOST EMPTY Mismatch!", i);
                    stress_passed = 1'b0;
                end
                if (overflow !== expected_overflow) begin
                    $error("Iteration %0d : OVERFLOW Mismatch!", i);
                    stress_passed = 1'b0;
                end
                if (underflow !== expected_underflow) begin
                    $error("Iteration %0d : UNDERFLOW Mismatch!", i);
                    stress_passed = 1'b0;
                end
                if (level !== expected_queue.size()) begin
                    $error("Iteration %0d : OCCUPANCY Mismatch!", i);
                    stress_passed = 1'b0;
                end

                record_test($sformatf("Iteration %0d", i+1), stress_passed);
            end
            // Deassert controls
            @(negedge clk);
            wr_en = 1'b0;
            rd_en = 1'b0;

            $display("\n=== RANDOM STRESS TEST OVER ===");
        end
    endtask

    // Test tasks end

    // Main test sequence
    initial begin
        // Reset behaviour test
        $display("\n=== TEST 1: RESET BEHAVIOUR ===");
        test_reset();

        // One write test
        $display("\n=== TEST 2: ONE WRITE TEST ===");
        test_one_write();

        // One read test
        $display("\n=== TEST 3: ONE READ TEST ===");
        test_one_read();

        // Multiple write test
        $display("\n=== TEST 4: MULTIPLE WRITE TEST ===");
        test_multi_write(DEPTH - 2);

        // Multiple read test
        $display("\n=== TEST 5: MULTIPLE READ TEST ===");
        test_multi_read(DEPTH - 2);

        // Full FIFO behaviour test
        $display("\n=== TEST 6: FULL FIFO BEHAVIOR ===");
        test_fill_fifo();

        // Empty FIFO behaviour test
        $display("\n=== TEST 7: EMPTY FIFO BEHAVIOR ===");
        test_empty_fifo();

        // Overflow behaviour test
        $display("\n=== TEST 8: OVERFLOW BEHAVIOR ===");
        test_overflow();

        // Underflow behaviour test
        $display("\n=== TEST 9: UNDERFLOW BEHAVIOR ===");
        test_underflow();

        // FIFO memory test when full and wr_en
        $display("\n=== TEST 10: OVERFLOW MEMORY INTEGRITY ===");
        test_wr_ignore();

        // Almost full FIFO behaviour test
        $display("\n=== TEST 11: ALMOST FULL FIFO BEHAVIOR ===");
        test_afull();

        // Almost empty FIFO behaviour test
        $display("\n=== TEST 12: ALMOST EMPTY FIFO BEHAVIOR ===");
        test_aempty();

        // Simultaneous read write when full test
        $display("\n=== TEST 14: SIMULTANEOUS READ WRITE BEHAVIOUR WHEN FULL ===");
        test_simultaneous_rw_full();

        // Simultaneous read write when empty test
        $display("\n=== TEST 15: SIMULTANEOUS READ WRITE BEHAVIOUR WHEN EMPTY ===");
        test_simultaneous_rw_empty();

        // Simultaneous read write when partially full test
        $display("\n=== TEST 16: SIMULTANEOUS READ WRITE BEHAVIOUR WHEN PARTIALLY FILLED ===");
        test_simultaneous_rw_pfill();

        // Random stress test
        $display("\n=== TEST 17: RANDOM STRESS TEST (%0d ITERATIONS) ===", RANDOM_ITERATIONS);
        test_random_stress();

        print_summary();
        $finish;
    end

endmodule
