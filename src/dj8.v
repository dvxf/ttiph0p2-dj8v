// DJ8 CPU (C) DaveX 2003-2024

module dj8(
    input reset,
    input clk,
    output reg [15:0] address_out,
    input [7:0] data_in,
    output [7:0] data_out,
    output reg we,
    output reg write_cycle // write execution or writeback
);

    `define I_JUMP 2'b00
    `define I_JMP_GH 2'b01
    `define J_JMP 2'b11
    `define J_JZ 2'b01
    `define J_JNZ 2'b10

    // Definitions for states
    typedef enum {fetch1, fetch2, execute, writeback} stateType;
    stateType state;

    // Registers
    reg [14:0] pc;
    reg [15:0] ir; 
    reg flag_C, flag_Z;

    // ALU 
    wire [7:0] ALU_a, ALU_b, ALU_result;
    wire ALU_c_out, ALU_z_out, ALU_c_in;
    wire [2:0] ALU_opalu;
    wire [1:0] ALU_shift;

    // IR related
    wire [2:0] ir_opalu;
    wire [2:0] ir_dest;
    wire [2:0] ir_src;
    wire [7:0] ir_imm8;
    wire [11:0] ir_imm12;     
    wire [1:0] ir_instruction;
    wire [1:0] ir_jumpcode;
    wire [1:0] ir_shift;
    wire ir_AluOpToReg, ir_immE, ir_toMem, ir_fromMem, ir_useEF;

    assign ir_opalu = ir[13:11];
    assign ir_dest = ir[10:8];
    assign ir_src = ir[7:5];
    assign ir_imm8 = ir[7:0];
    assign ir_imm12 = ir[11:0];
    assign ir_instruction = ir[15:14];
    assign ir_jumpcode = ir[13:12];
    assign ir_AluOpToReg = ir[15];
    assign ir_immE = ir[14];
    assign ir_toMem = ir[0];
    assign ir_fromMem = ir[1];
    assign ir_useEF = ir[4];
    assign ir_shift = ir[3:2];

    // Other signals
    wire [7:0] REGS_data_out;

    // Instantiation of ALU and Register File
    alu ALU (
        .a(ALU_a),
        .b(ALU_b),
        .result(ALU_result),
        .opalu(ALU_opalu),
        .c_in(ALU_c_in),
        .c_out(ALU_c_out),
        .z(ALU_z_out),
        .shift(ALU_shift)
    );

    // Register file
    wire [2:0] REGS_read_A, REGS_write_A;
    wire [7:0] REGS_data_in;
    wire [7:0] ACC;
    wire [15:0] EF, GH;
    wire REGS_we;
    assign REGS_we = (state == execute && ir_AluOpToReg && !(!ir_immE && ir_toMem)) ? 1'b1 : 1'b0;
    register_file REGS (
        .clk(clk),
        .reset(reset),
        .read_addr(REGS_read_A),
        .data_in(REGS_data_in),
        .write_addr(REGS_write_A),
        .data_out(REGS_data_out),
        .we(REGS_we),
        .ACC(ACC),
        .EF(EF),
        .GH(GH)
    );
    assign REGS_read_A = (ir_immE) ? ir_dest : ir_src;
    assign REGS_write_A = ir_dest;
    assign REGS_data_in = ALU_result;

    // data bus
    assign data_out = REGS_data_out;

    // address_bus
    always @(*) begin
        write_cycle = 1'b0;
        // address_bus_out
        if (state == fetch1) begin
            address_out <= {pc[14:0], 1'b0};
        end else if (state == fetch2) begin
            address_out <= {pc[14:0], 1'b1};
        end else if (ir_AluOpToReg && !ir_immE && (ir_toMem || ir_fromMem)) begin // execute or writeback
            if (ir_toMem) begin
                write_cycle = 1;
            end
            if (ir_useEF) begin
                address_out <= EF;
            end else begin
                address_out <= GH;
            end
        end else begin
            address_out <= {pc[14:0], 1'b1};
        end
    end

    // ALU signals
    assign ALU_shift = ir_immE ? 2'b00 : ir_shift;
    assign ALU_opalu = ir_opalu;
    assign ALU_a = (ir_fromMem && !ir_immE) ? data_in : REGS_data_out;
    assign ALU_b = (ir_immE) ? ir_imm8 : ACC;
    assign ALU_c_in = flag_C;

    // State machine on pos edge
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= fetch1;
            pc <= 15'b010000000000000; // Starting at address 0x4000
            ir <= 16'b0;
            flag_C <= 1'b0;
            flag_Z <= 1'b0;
        end else begin
            case (state)
                fetch1: begin
                    ir[15:8] <= data_in;
                    state <= fetch2;
                end
                fetch2: begin
                    ir[7:0] <= data_in; 
                    state <= execute; // Move to the execute phase
                end
                execute: begin
                    if (ir_AluOpToReg) begin
                        flag_C <= ALU_c_out;
                        flag_Z <= ALU_z_out;
                    end
                    if ((ir_instruction == `I_JUMP && ir_jumpcode == `J_JMP) ||
                            (ir_instruction == `I_JUMP && ir_jumpcode == `J_JZ && flag_Z) ||
                            (ir_instruction == `I_JUMP && ir_jumpcode == `J_JNZ && !flag_Z)) begin
                            pc <= {pc[14:12], ir_imm12};  
                        end else if (ir_instruction == `I_JMP_GH) begin
                            pc <= GH[15:1];
                        end else begin
                            pc <= pc + 1;
                        end 
                    if (ir_AluOpToReg && !ir_immE && ir_toMem) begin
                        state <= writeback;
                    end else begin
                        state <= fetch1;
                    end
                end
                writeback: begin
                    state <= fetch1;
                end 
            endcase
        end
    end

    // Registers on neg edge
    always @(negedge clk or posedge reset) begin
        if (reset) begin
            we <= 1'b1;
        end else begin
            case (state)
                execute: begin
                    if (ir_AluOpToReg && !ir_immE && ir_toMem) begin
                    we <= 1'b0;
                    end
                end
                writeback: begin
                    we <= 1'b1;
                end
            endcase
        end
    end

endmodule
