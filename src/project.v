/*
 * Copyright (c) 2003-2024 DaveX
 * SPDX-License-Identifier: Apache-2.0
 */

`include "dj8.v"
`include "alu.v"
`include "register_file.v"
`default_nettype none

module tt_um_dvxf_dj8v (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // ROM
  reg [7:0] rom[0:31]; 
  initial begin
    rom[0] = 8'hF8; rom[1] = 8'h01;   // 0000: movi A, 0x01
    rom[2] = 8'h9C; rom[3] = 8'h00;   // 0002: movr E,A
    rom[4] = 8'h99; rom[5] = 8'h12;   // 0004: movr B,(EF)
    rom[6] = 8'h10; rom[7] = 8'h08;   // 0006: jz 0010
    rom[8] = 8'hC3; rom[9] = 8'h01;   // 0008: add D, 0x01
    rom[10] = 8'hCA; rom[11] = 8'h00;   // 000A: addc C, 0x00
    rom[12] = 8'hC9; rom[13] = 8'h00;   // 000C: addc B, 0x00
    rom[14] = 8'h20; rom[15] = 8'h02;   // 000E: jnz 0004
    rom[16] = 8'h80; rom[17] = 8'h00;   // 0010: add A,A,A
    rom[18] = 8'hD4; rom[19] = 8'h20;   // 0012: subc E, 0x20
    rom[20] = 8'h10; rom[21] = 8'h00;   // 0014: jz 0000
    rom[22] = 8'h30; rom[23] = 8'h01;   // 0016: jmp 0002
    rom[24] = 8'h28; rom[25] = 8'h63;   // 0018: jnz 10C6
    rom[26] = 8'h29; rom[27] = 8'h44;   // 001A: jnz 1288
    rom[28] = 8'h61; rom[29] = 8'h76;   // 001C: jmp gh
    rom[30] = 8'h65; rom[31] = 8'h58;   // 001E: jmp gh
  end

  // TT07 mapping
  wire [15:0] cpu_address_out;
  wire [7:0] cpu_data_out;
  wire cpu_we;
  wire cpu_write_cycle;

  wire reset;
  wire [7:0] rom_data, cpu_data_in;

  assign reset = !rst_n;
  assign uo_out = {cpu_we, cpu_address_out[14:8]};
  assign uio_out = (cpu_write_cycle) ? cpu_data_out : cpu_address_out[7:0];
  assign uio_oe = 8'b11111111;
  assign rom_data = rom[cpu_address_out[4:0]];
  assign cpu_data_in = cpu_address_out[15] ? rom_data : ui_in;

  dj8 DJ8 (
      .reset(reset),
      .clk(clk),
      .address_out(cpu_address_out),
      .data_out(cpu_data_out),
      .data_in(cpu_data_in),
      .we(cpu_we),
      .write_cycle(cpu_write_cycle)
  );


endmodule
