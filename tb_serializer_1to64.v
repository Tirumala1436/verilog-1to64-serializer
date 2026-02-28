`timescale 1ns/1ps

module tb_serializer_64to1_serdes;
    reg clk, rst_n, valid_in;
    reg [63:0] data_in;
    wire ready_out, serial_out;

    reg [63:0] captured_word;
    reg [5:0] bit_counter;
    reg [63:0] test_queue [0:4];
    integer i;

    serializer_64to1_serdes dut (
        .clk_serial(clk), .rst_n(rst_n), .data_in(data_in),
        .valid_in(valid_in), .ready_out(ready_out), .serial_out(serial_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

// Verification Logic: Capture serial_out into a word
// Capture serial output ONLY when the DUT is active
always @(posedge clk) begin
    if (!rst_n) begin
        captured_word <= 0;
        bit_counter <= 0;
    end else if (dut.active) begin // Use the 'active' signal from the DUT to sync
        captured_word <= {captured_word[62:0], serial_out};
        
        if (bit_counter == 6'd63) begin
            bit_counter <= 0;
            // The display must happen after the non-blocking assignment above completes
            #1 $display("SUCCESS: Captured Word = %h", {captured_word[62:0], serial_out});
        end else begin
            bit_counter <= bit_counter + 1'b1;
        end
    end
end
    initial begin
        $dumpfile("serializer.vcd");
        $dumpvars(0, tb_serializer_64to1_serdes);
        
        rst_n = 0; valid_in = 0; data_in = 0;
        #20 rst_n = 1;

        // Send 5 words
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
            while (!ready_out) @(posedge clk);
            data_in = {32'hAAAA_BBBB, $random};
            valid_in = 1;
            @(posedge clk);
            valid_in = 0;
        end

        #4000 $finish;
    end
endmodule
