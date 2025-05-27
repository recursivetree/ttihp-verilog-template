`timescale 1ns/1ps

/*
The alu reservation station listens to the CDB bus for operands. Once it has all operands, it issues a CDB write request
wit the ALU operation result.

rst_n resets the design. It takes priority over any other command.

If a new listen command is issued at the same time as the result of the current command is accepted, the module handles it just fine.
*/

module alu_reservation_station
#(
     parameter DATA_WIDTH = 4,      // the bitwidth of a data word
     parameter CDB_TAG_WIDTH = 4    // the bitwidth of a CDB tag. Ensure CDB_TAG_WIDTH<=DATA_WIDTH
)
(
    // clock
    input clk,
    input rst_n,

    // cdb consumer
    input cdb_in_valid,
    input[CDB_TAG_WIDTH-1:0] cdb_in_tag,
    input[DATA_WIDTH-1:0] cdb_in_data,

    // commands
    input command_update_en,
    input[DATA_WIDTH-1:0] command_a_data,
    input command_a_data_is_valid,
    input[DATA_WIDTH-1:0] command_b_data,
    input command_b_data_is_valid,

    // cdb producer
    output cdb_out_request,
    output[DATA_WIDTH-1:0] cdb_out_data,
    input cdb_out_accepted,

    // general state
    output reg reserved
);
    wire operands_valid;
    wire operand_a_valid;
    wire operand_b_valid;
    wire[DATA_WIDTH-1:0] operand_a;
    wire[DATA_WIDTH-1:0] operand_b;

    cdb_result_listener #(.DATA_WIDTH(DATA_WIDTH), .CDB_TAG_WIDTH(CDB_TAG_WIDTH)) operand_a_cdb_listener(
        .clk(clk), 
        .cdb_in_valid(cdb_in_valid),
        .cdb_in_tag(cdb_in_tag),
        .cdb_in_data(cdb_in_data),
        .valid(operand_a_valid),
        .data(operand_a),
        .command_update_en(command_update_en),
        .command_data(command_a_data),
        .command_data_is_valid(command_b_data_is_valid)
    );
    cdb_result_listener #(.DATA_WIDTH(DATA_WIDTH), .CDB_TAG_WIDTH(CDB_TAG_WIDTH)) operand_b_cdb_listener(
        .clk(clk), 
        .cdb_in_valid(cdb_in_valid),
        .cdb_in_tag(cdb_in_tag),
        .cdb_in_data(cdb_in_data),
        .valid(operand_b_valid),
        .data(operand_b),
        .command_update_en(command_update_en),
        .command_data(command_b_data),
        .command_data_is_valid(command_b_data_is_valid)
    );

    assign operands_valid = operand_a_valid && operand_b_valid;
    assign cdb_out_request = reserved && operands_valid;
    assign cdb_out_data = operand_a - operand_b; // The actual ALU operation

    always @(posedge clk) begin
        if(!rst_n) begin
            reserved <= 0; // set to not reserved when resetting
        end else begin 
            if(command_update_en) begin
                reserved <= 1;
            end else if(reserved && cdb_out_request && cdb_out_accepted) begin 
                reserved <= 0;
            end
        end
    end


endmodule