// DJ8 CPU (C) DaveX 2003-2024

module register_file(
    input wire clk,
    input wire reset,
    input wire [2:0] read_addr,
    input wire [2:0] write_addr,
    input wire [7:0] data_in,
    output wire [7:0] data_out,
    input wire we,
    output wire [7:0] ACC,
    output wire [15:0] EF,
    output wire [15:0] GH
);

    reg [7:0] regs[0:7]; // Register array
    integer i;

    // Register update
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            // Initialize registers on reset
            for (i = 0; i < 8; i = i + 1) begin
                regs[i] <= 8'b10000000; // Reset value
            end
        end else begin
            if (we) begin
                regs[write_addr] <= data_in; // Write data to the register
            end
        end
    end

    // Read register
    assign data_out = regs[read_addr];

    // Special registers
    assign ACC = regs[0];
    assign EF = {regs[4], regs[5]};
    assign GH = {regs[6], regs[7]};

endmodule
