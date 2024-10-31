// DJ8 CPU (C) DaveX 2003-2024

module alu(
    input [7:0] a,
    input [7:0] b,
    output reg [7:0] result,
    input [2:0] opalu,
    input c_in,
    output reg c_out,
    output reg z,
    input [1:0] shift
);

    `define OP_ADD  3'h0
    `define OP_ADDC 3'h1
    `define OP_SUBC 3'h2
    `define OP_MOVR 3'h3
    `define OP_XOR  3'h4
    `define OP_OR   3'h5
    `define OP_AND  3'h6
    `define OP_MOVI 3'h7

    `define S_SHL 2'b01
    `define S_SAR 2'b10

    reg [8:0] temp;

    always @(*) begin
        temp = 9'b0;
        result = 8'b0;

        // Operations
        case (opalu)
            `OP_ADD: temp = {1'b0, a} + {1'b0, b};
            `OP_ADDC: temp = {1'b0, a} + {1'b0, b} + {8'b0,c_in};
            `OP_SUBC: temp = {1'b0, a} - ({1'b0, b} + {8'b0,c_in});
            `OP_MOVR: temp = {1'b0, a};
            `OP_XOR: temp = {1'b0, a ^ b};
            `OP_OR: temp = {1'b0, a | b};
            `OP_AND: temp = {1'b0, a & b};
            `OP_MOVI: temp = {1'b0, b};
        endcase

        c_out = temp[8];

        // Handle shifts
        case (shift)
            `S_SHL: result = {1'b0, temp[7:1]}; 
            `S_SAR: result = {temp[7], temp[7:1]};
            default: result = temp[7:0]; 
        endcase

    end

    // Zero flag update
    always @(result) begin
        if (result == 8'h00)
            z = 1'b1;
        else
            z = 1'b0;
    end
endmodule
