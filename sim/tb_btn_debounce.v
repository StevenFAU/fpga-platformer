`timescale 1ns / 1ps

module tb_btn_debounce;

    reg  clk;
    reg  rst_n;
    reg  btn_in;
    wire btn_out;

    btn_debounce uut (
        .clk(clk),
        .rst_n(rst_n),
        .btn_in(btn_in),
        .btn_out(btn_out)
    );

    // 25 MHz clock → 40 ns period
    initial clk = 0;
    always #20 clk = ~clk;

    // DEBOUNCE_LIMIT = 500_000 cycles
    // We need to hold a stable value for > 500_000 cycles to pass through
    // and toggle rapidly (< 500_000 cycles per state) to test rejection

    integer errors;
    integer i;

    // Task: advance N clock cycles
    task tick;
        input integer n;
        integer j;
        begin
            for (j = 0; j < n; j = j + 1)
                @(posedge clk);
        end
    endtask

    // Task: generate bounce noise — toggle btn_in rapidly for N cycles
    task bounce;
        input integer n;
        integer j;
        begin
            for (j = 0; j < n; j = j + 1) begin
                @(posedge clk);
                if (j % 50 == 0)  // toggle every 50 cycles
                    btn_in = ~btn_in;
            end
        end
    endtask

    initial begin
        $dumpfile("btn_debounce.vcd");
        $dumpvars(0, tb_btn_debounce);

        errors = 0;
        rst_n  = 0;
        btn_in = 0;

        #200;
        rst_n = 1;
        #100;

        // ── Test 1: Output starts low after reset ──
        if (btn_out == 1'b0)
            $display("PASS: Output low after reset");
        else begin
            $display("FAIL: Output should be low after reset, got %b", btn_out);
            errors = errors + 1;
        end

        // ── Test 2: Noisy input (bouncing) does NOT propagate ──
        // Simulate a bouncy press: toggle rapidly for 100_000 cycles (< 500_000 limit)
        // The output should remain low because no stable state lasts long enough
        btn_in = 1;
        bounce(100000);
        btn_in = 0;  // release before reaching limit
        tick(100);
        if (btn_out == 1'b0)
            $display("PASS: Noisy input rejected — output stayed low");
        else begin
            $display("FAIL: Noisy input propagated — output is %b, expected 0", btn_out);
            errors = errors + 1;
        end

        // ── Test 3: Stable high input propagates after debounce period ──
        btn_in = 1;
        tick(510000);  // hold stable for > 500_000 cycles
        if (btn_out == 1'b1)
            $display("PASS: Stable high propagated after debounce period");
        else begin
            $display("FAIL: Stable high not propagated — output is %b, expected 1", btn_out);
            errors = errors + 1;
        end

        // ── Test 4: Stable low input propagates (release) ──
        btn_in = 0;
        tick(510000);  // hold stable low for > 500_000 cycles
        if (btn_out == 1'b0)
            $display("PASS: Stable low propagated (button released)");
        else begin
            $display("FAIL: Stable low not propagated — output is %b, expected 0", btn_out);
            errors = errors + 1;
        end

        // ── Test 5: Bounce on press followed by stable hold ──
        // Simulate realistic press: bounce for a bit, then settle high
        btn_in = 1;
        bounce(5000);      // brief bounce
        btn_in = 1;        // settle high
        tick(510000);       // hold stable
        if (btn_out == 1'b1)
            $display("PASS: Bounce then stable high — output went high");
        else begin
            $display("FAIL: Bounce then stable — output is %b, expected 1", btn_out);
            errors = errors + 1;
        end

        // ── Test 6: Reset clears output mid-press ──
        // btn_out is currently 1
        rst_n = 0;
        tick(5);
        if (btn_out == 1'b0)
            $display("PASS: Reset clears output to low");
        else begin
            $display("FAIL: Reset did not clear output — got %b", btn_out);
            errors = errors + 1;
        end
        rst_n = 1;
        btn_in = 0;
        tick(100);

        $display("========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);
        $display("========================================");
        $finish;
    end

endmodule
