`timescale 1ns/1ps

module serializer_64to1_serdes (
    input wire clk_serial, 
    input wire rst_n,
    input wire [63:0] data_in,
    input wire valid_in,
    output wire ready_out,
    output reg serial_out
);

    reg [63:0] buffer_a, buffer_b;
    reg select_buffer;     // 0 = reading from A, 1 = reading from B
    reg buffer_a_full, buffer_b_full;
    reg [5:0] bit_count;
    reg active;            // Indicates if we are currently transmitting

    // Ready to accept data if the "next" buffer in line is empty
    assign ready_out = (select_buffer == 0) ? !buffer_b_full : !buffer_a_full;

    //------------------------------------------
    // Load & Control Logic
    //------------------------------------------
    always @(posedge clk_serial or negedge rst_n) begin
        if (!rst_n) begin
            buffer_a <= 64'd0;
            buffer_b <= 64'd0;
            buffer_a_full <= 1'b0;
            buffer_b_full <= 1'b0;
            select_buffer <= 1'b0;
            bit_count <= 6'd0;
            active <= 1'b0;
            serial_out <= 1'b0;
        end else begin
            // 1. Loading Logic
            if (valid_in && ready_out) begin
                if (!active) begin
                    buffer_a <= data_in;
                    buffer_a_full <= 1'b1;
                    active <= 1'b1; // Start transmitting immediately
                end else if (select_buffer == 0) begin
                    buffer_b <= data_in;
                    buffer_b_full <= 1'b1;
                end else begin
                    buffer_a <= data_in;
                    buffer_a_full <= 1'b1;
                end
            end

            // 2. Shifting Logic
            if (active) begin
                // Output bit from the active buffer
                if (select_buffer == 0)
                    serial_out <= buffer_a[63 - bit_count];
                else
                    serial_out <= buffer_b[63 - bit_count];

                bit_count <= bit_count + 1'b1;

                // 3. Buffer Toggling
                if (bit_count == 6'd63) begin
                    if (select_buffer == 0) begin
                        buffer_a_full <= 1'b0; // A is now empty
                        if (buffer_b_full) begin
                            select_buffer <= 1'b1;
                        end else begin
                            active <= 1'b0; // Nothing in B, stop
                        end
                    end else begin
                        buffer_b_full <= 1'b0; // B is now empty
                        if (buffer_a_full) begin
                            select_buffer <= 1'b0;
                        end else begin
                            active <= 1'b0; // Nothing in A, stop
                        end
                    end
                end
            end
        end
    end
endmodule
