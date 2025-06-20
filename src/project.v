/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  wire _unused = &{ena, clk, rst_n, uio_in, 1'b0};

  top top(
      .clk(clk),
      .rst_n(rst_n),
      .command_kind(uio_in[2:0]),
      .command_operand1(ui_in[3:0]),
      .command_operand2(ui_in[7:0]),
      .optimization_stopper(uo_out[3:0])
    );

  assign uo_out[7:4] = 0;

endmodule
