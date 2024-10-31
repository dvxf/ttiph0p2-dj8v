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
  reg [7:0] rom[0:255]; 
  initial begin
    rom[0] = 8'h10; rom[1] = 8'h83;   // 8000: jz 0106
    rom[2] = 8'hED; rom[3] = 8'h80;   // 8002: or F, 0x80
    rom[4] = 8'h30; rom[5] = 8'hA6;   // 8004: jmp 014C
    rom[6] = 8'h98; rom[7] = 8'h00;   // 8006: movr A,A
    rom[8] = 8'h30; rom[9] = 8'hA6;   // 8008: jmp 014C
    rom[10] = 8'h98; rom[11] = 8'h64;   // 800A: movr A,D,shr
    rom[12] = 8'h98; rom[13] = 8'h04;   // 800C: movr A,A,shr
    rom[14] = 8'h9D; rom[15] = 8'h04;   // 800E: movr F,A,shr
    rom[16] = 8'h98; rom[17] = 8'h40;   // 8010: movr A,C
    rom[18] = 8'h80; rom[19] = 8'h00;   // 8012: add A,A,A
    rom[20] = 8'h80; rom[21] = 8'h00;   // 8014: add A,A,A
    rom[22] = 8'h80; rom[23] = 8'h00;   // 8016: add A,A,A
    rom[24] = 8'h80; rom[25] = 8'h00;   // 8018: add A,A,A
    rom[26] = 8'h80; rom[27] = 8'h00;   // 801A: add A,A,A
    rom[28] = 8'hAD; rom[29] = 8'hA0;   // 801C: or F,F,A
    rom[30] = 8'h98; rom[31] = 8'h02;   // 801E: movr A,(GH)
    rom[32] = 8'hE0; rom[33] = 8'hEA;   // 8020: xor A, 0xEA
    rom[34] = 8'hF0; rom[35] = 8'h30;   // 8022: and A, 0x30
    rom[36] = 8'hB4; rom[37] = 8'h60;   // 8024: and E,D,A
    rom[38] = 8'h98; rom[39] = 8'h02;   // 8026: movr A,(GH)
    rom[40] = 8'hE0; rom[41] = 8'hEA;   // 8028: xor A, 0xEA
    rom[42] = 8'hF0; rom[43] = 8'hC0;   // 802A: and A, 0xC0
    rom[44] = 8'h98; rom[45] = 8'h04;   // 802C: movr A,A,shr
    rom[46] = 8'h98; rom[47] = 8'h04;   // 802E: movr A,A,shr
    rom[48] = 8'h98; rom[49] = 8'h04;   // 8030: movr A,A,shr
    rom[50] = 8'h98; rom[51] = 8'h04;   // 8032: movr A,A,shr
    rom[52] = 8'hB0; rom[53] = 8'h40;   // 8034: and A,C,A
    rom[54] = 8'hA8; rom[55] = 8'h80;   // 8036: or A,E,A
    rom[56] = 8'h10; rom[57] = 8'hA1;   // 8038: jz 0142
    rom[58] = 8'h98; rom[59] = 8'h60;   // 803A: movr A,D
    rom[60] = 8'h80; rom[61] = 8'h00;   // 803C: add A,A,A
    rom[62] = 8'h80; rom[63] = 8'h00;   // 803E: add A,A,A
    rom[64] = 8'h30; rom[65] = 8'hA5;   // 8040: jmp 014A
    rom[66] = 8'h98; rom[67] = 8'h60;   // 8042: movr A,D
    rom[68] = 8'h98; rom[69] = 8'h00;   // 8044: movr A,A
    rom[70] = 8'h98; rom[71] = 8'h00;   // 8046: movr A,A
    rom[72] = 8'h30; rom[73] = 8'hA5;   // 8048: jmp 014A
    rom[74] = 8'hAD; rom[75] = 8'hA0;   // 804A: or F,F,A
    rom[76] = 8'h98; rom[77] = 8'hA1;   // 804C: movr (GH),F
    rom[78] = 8'h98; rom[79] = 8'h20;   // 804E: movr A,B
    rom[80] = 8'hF0; rom[81] = 8'h10;   // 8050: and A, 0x10
    rom[82] = 8'h20; rom[83] = 8'hB5;   // 8052: jnz 016A
    rom[84] = 8'h9C; rom[85] = 8'hA0;   // 8054: movr E,F
    rom[86] = 8'hE4; rom[87] = 8'hFF;   // 8056: xor E, 0xFF
    rom[88] = 8'hC4; rom[89] = 8'h01;   // 8058: add E, 0x01
    rom[90] = 8'hC5; rom[91] = 8'h01;   // 805A: add F, 0x01
    rom[92] = 8'h38; rom[93] = 8'hAF;   // 805C: jmp 115E
    rom[94] = 8'hC5; rom[95] = 8'hFF;   // 805E: add F, 0xFF
    rom[96] = 8'h28; rom[97] = 8'hAF;   // 8060: jnz 115E
    rom[98] = 8'h30; rom[99] = 8'hB2;   // 8062: jmp 0164
    rom[100] = 8'hC4; rom[101] = 8'hFF;   // 8064: add E, 0xFF
    rom[102] = 8'h20; rom[103] = 8'hB2;   // 8066: jnz 0164
    rom[104] = 8'hFE; rom[105] = 8'h00;   // 8068: movi G, 0x00
    rom[106] = 8'h98; rom[107] = 8'h20;   // 806A: movr A,B
    rom[108] = 8'hF0; rom[109] = 8'h03;   // 806C: and A, 0x03
    rom[110] = 8'hC0; rom[111] = 8'h01;   // 806E: add A, 0x01
    rom[112] = 8'h83; rom[113] = 8'h60;   // 8070: add D,D,A
    rom[114] = 8'hCA; rom[115] = 8'h00;   // 8072: addc C, 0x00
    rom[116] = 8'h30; rom[117] = 8'h57;   // 8074: jmp 00AE
    rom[118] = 8'h00; rom[119] = 8'h00;   // 8076: ???
    rom[120] = 8'h00; rom[121] = 8'h00;   // 8078: ???
    rom[122] = 8'h00; rom[123] = 8'h00;   // 807A: ???
    rom[124] = 8'h00; rom[125] = 8'h00;   // 807C: ???
    rom[126] = 8'h00; rom[127] = 8'h00;   // 807E: ???
    rom[128] = 8'hFE; rom[129] = 8'h00;   // 8080: movi G, 0x00
    rom[130] = 8'h98; rom[131] = 8'h02;   // 8082: movr A,(GH)
    rom[132] = 8'hF0; rom[133] = 8'h20;   // 8084: and A, 0x20
    rom[134] = 8'h20; rom[135] = 8'h54;   // 8086: jnz 00A8
    rom[136] = 8'hF8; rom[137] = 8'h01;   // 8088: movi A, 0x01
    rom[138] = 8'h9C; rom[139] = 8'h00;   // 808A: movr E,A
    rom[140] = 8'h99; rom[141] = 8'h12;   // 808C: movr B,(EF)
    rom[142] = 8'h10; rom[143] = 8'h4C;   // 808E: jz 0098
    rom[144] = 8'hC3; rom[145] = 8'h01;   // 8090: add D, 0x01
    rom[146] = 8'hCA; rom[147] = 8'h00;   // 8092: addc C, 0x00
    rom[148] = 8'hC9; rom[149] = 8'h00;   // 8094: addc B, 0x00
    rom[150] = 8'h20; rom[151] = 8'h46;   // 8096: jnz 008C
    rom[152] = 8'h80; rom[153] = 8'h00;   // 8098: add A,A,A
    rom[154] = 8'hD4; rom[155] = 8'h20;   // 809A: subc E, 0x20
    rom[156] = 8'h10; rom[157] = 8'h44;   // 809C: jz 0088
    rom[158] = 8'h30; rom[159] = 8'h45;   // 809E: jmp 008A
    rom[160] = 8'h28; rom[161] = 8'h63;   // 80A0: jnz 10C6
    rom[162] = 8'h29; rom[163] = 8'h44;   // 80A2: jnz 1288
    rom[164] = 8'h61; rom[165] = 8'h76;   // 80A4: jmp gh
    rom[166] = 8'h65; rom[167] = 8'h58;   // 80A6: jmp gh
    rom[168] = 8'hFA; rom[169] = 8'h00;   // 80A8: movi C, 0x00
    rom[170] = 8'hFB; rom[171] = 8'h00;   // 80AA: movi D, 0x00
    rom[172] = 8'h99; rom[173] = 8'h02;   // 80AC: movr B,(GH)
    rom[174] = 8'h98; rom[175] = 8'h02;   // 80AE: movr A,(GH)
    rom[176] = 8'hE0; rom[177] = 8'hEA;   // 80B0: xor A, 0xEA
    rom[178] = 8'hF0; rom[179] = 8'h0C;   // 80B2: and A, 0x0C
    rom[180] = 8'hB4; rom[181] = 8'h60;   // 80B4: and E,D,A
    rom[182] = 8'h98; rom[183] = 8'h02;   // 80B6: movr A,(GH)
    rom[184] = 8'hE0; rom[185] = 8'hEA;   // 80B8: xor A, 0xEA
    rom[186] = 8'hF0; rom[187] = 8'h03;   // 80BA: and A, 0x03
    rom[188] = 8'h20; rom[189] = 8'h61;   // 80BC: jnz 00C2
    rom[190] = 8'h98; rom[191] = 8'h02;   // 80BE: movr A,(GH)
    rom[192] = 8'h30; rom[193] = 8'h63;   // 80C0: jmp 00C6
    rom[194] = 8'hE8; rom[195] = 8'h10;   // 80C2: or A, 0x10
    rom[196] = 8'h30; rom[197] = 8'h63;   // 80C4: jmp 00C6
    rom[198] = 8'hB0; rom[199] = 8'h40;   // 80C6: and A,C,A
    rom[200] = 8'hA8; rom[201] = 8'h80;   // 80C8: or A,E,A
    rom[202] = 8'h20; rom[203] = 8'h85;   // 80CA: jnz 010A
    rom[204] = 8'h98; rom[205] = 8'h44;   // 80CC: movr A,C,shr
    rom[206] = 8'h98; rom[207] = 8'h04;   // 80CE: movr A,A,shr
    rom[208] = 8'h98; rom[209] = 8'h04;   // 80D0: movr A,A,shr
    rom[210] = 8'h9C; rom[211] = 8'h04;   // 80D2: movr E,A,shr
    rom[212] = 8'h98; rom[213] = 8'h64;   // 80D4: movr A,D,shr
    rom[214] = 8'h98; rom[215] = 8'h04;   // 80D6: movr A,A,shr
    rom[216] = 8'h98; rom[217] = 8'h04;   // 80D8: movr A,A,shr
    rom[218] = 8'h9D; rom[219] = 8'h04;   // 80DA: movr F,A,shr
    rom[220] = 8'h98; rom[221] = 8'h40;   // 80DC: movr A,C
    rom[222] = 8'h80; rom[223] = 8'h00;   // 80DE: add A,A,A
    rom[224] = 8'h80; rom[225] = 8'h00;   // 80E0: add A,A,A
    rom[226] = 8'h80; rom[227] = 8'h00;   // 80E2: add A,A,A
    rom[228] = 8'h80; rom[229] = 8'h00;   // 80E4: add A,A,A
    rom[230] = 8'hAD; rom[231] = 8'hA0;   // 80E6: or F,F,A
    rom[232] = 8'h98; rom[233] = 8'h60;   // 80E8: movr A,D
    rom[234] = 8'hAD; rom[235] = 8'hA0;   // 80EA: or F,F,A
    rom[236] = 8'h98; rom[237] = 8'h40;   // 80EC: movr A,C
    rom[238] = 8'hAC; rom[239] = 8'h80;   // 80EE: or E,E,A
    rom[240] = 8'h98; rom[241] = 8'h00;   // 80F0: movr A,A
    rom[242] = 8'h98; rom[243] = 8'h00;   // 80F2: movr A,A
    rom[244] = 8'h98; rom[245] = 8'h00;   // 80F4: movr A,A
    rom[246] = 8'h98; rom[247] = 8'h00;   // 80F6: movr A,A
    rom[248] = 8'h98; rom[249] = 8'h00;   // 80F8: movr A,A
    rom[250] = 8'h98; rom[251] = 8'h00;   // 80FA: movr A,A
    rom[252] = 8'h9D; rom[253] = 8'hA4;   // 80FC: movr F,F,shr
    rom[254] = 8'hF4; rom[255] = 8'h01;   // 80FE: and E, 0x01
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
  assign rom_data = rom[cpu_address_out[7:0]];
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
