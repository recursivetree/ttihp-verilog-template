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
  //assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena};

  alu_reservation_station sta(
    .clk(clk),
    .rst_n(rst_n),
    .cdb_in_valid(uio_in[0]),
    .cdb_in_tag(ui_in[3:0]),
    .cdb_in_data(ui_in[7:4]),
    .command_update_en(uio_in[1]),
    .command_a_data(ui_in[3:0]),
    .command_b_data(ui_in[7:4]),
    .command_a_data_is_valid(uio_in[2]),
    .command_b_data_is_valid(uio_in[3]),
    .cdb_out_request(uo_out[0]),
    .cdb_out_data(uo_out[7:4]),
    .cdb_out_accepted(uio_in[4]),
    .reserved(uo_out[1])
  );

endmodule
