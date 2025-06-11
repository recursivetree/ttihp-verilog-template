`timescale 1ns/1ps
module top
#(
     parameter DATA_WIDTH = 4,      // the bitwidth of a data word
     parameter CDB_TAG_WIDTH = 4,    // the bitwidth of a CDB tag. Ensure CDB_TAG_WIDTH<=DATA_WIDTH
     parameter REGISTER_COUNT = 4
)(
    input clk,
    input rst_n,

    // temporary for testing
    input[2:0] command_kind,
    input[$clog2(REGISTER_COUNT)-1:0] command_operand1,
    input[3:0] command_operand2
);
    localparam CDB_OUT_PARTICIPANTS = 1;
    localparam CDB_OUT_ALU_PRIO = 0;

    wire cdb_valid;
    wire[CDB_TAG_WIDTH-1:0] cdb_tag;
    wire[DATA_WIDTH-1:0] cdb_data;
    wire[CDB_OUT_PARTICIPANTS-1:0] cdb_out_requests;
    wire[CDB_OUT_PARTICIPANTS-1:0] cdb_out_request_granted;

    wire[CDB_TAG_WIDTH-1:0] alu_cdb_out_tag;
    wire[DATA_WIDTH-1:0] alu_cdb_out_data;

    reg[2:0] arbiter_state;

    wire alu_eu_command_update_en;
    wire[DATA_WIDTH-1:0] alu_eu_operand_a_data;
    wire alu_eu_operand_a_data_is_valid;
    wire[DATA_WIDTH-1:0] alu_eu_operand_b_data;
    wire alu_eu_operand_b_data_is_valid;
    wire alu_eu_command_update_accepted;
    wire[CDB_TAG_WIDTH-1:0] alu_eu_command_result_cdb_tag;

    assign cdb_valid = |cdb_out_requests;
    assign cdb_tag = alu_cdb_out_tag;
    assign cdb_data = alu_cdb_out_data;

    priority_arbiter #(.INPUTS(CDB_OUT_PARTICIPANTS)) cdb_out_arbiter(
        .req(cdb_out_requests),
        .grant(cdb_out_request_granted)
    );

    alu_execution_unit #(.DATA_WIDTH(DATA_WIDTH), .CDB_TAG_WIDTH(CDB_TAG_WIDTH)) alu_execution_unit(
        // general signals
        .clk(clk),
        .rst_n(rst_n),
        .arbiter_state(arbiter_state),
        // cdb consumer
        .cdb_in_valid(cdb_valid),
        .cdb_in_tag(cdb_tag),
        .cdb_in_data(cdb_data),
        // cdb producer
        .cdb_out_request(cdb_out_requests[CDB_OUT_ALU_PRIO]),
        .cdb_out_tag(alu_cdb_out_tag),
        .cdb_out_data(alu_cdb_out_data),
        .cdb_out_accepted(cdb_out_request_granted[CDB_OUT_ALU_PRIO]),
        // commands
        .command_update_en(alu_eu_command_update_en),
        .operand_a_data(alu_eu_operand_a_data),
        .operand_a_data_is_valid(alu_eu_operand_a_data_is_valid),
        .operand_b_data(alu_eu_operand_b_data),
        .operand_b_data_is_valid(alu_eu_operand_b_data_is_valid),
        .command_update_accepted(alu_eu_command_update_accepted),
        .command_result_cdb_tag(alu_eu_command_result_cdb_tag)
    );

    register_file_controller #(
        .REGISTER_COUNT(REGISTER_COUNT),
        .DATA_WIDTH(DATA_WIDTH),
        .CDB_TAG_WIDTH(CDB_TAG_WIDTH),
        .UOP_COMMAND_WIDTH(3)
    ) register_file_controller (
        .clk(clk),
        .rst_n(rst_n),
        // cdb consumer
        .cdb_in_valid(cdb_valid),
        .cdb_in_tag(cdb_tag),
        .cdb_in_data(cdb_data),
        // alu exectuion unit interface
        .alu_eu_command_update_en(alu_eu_command_update_en),
        .alu_eu_operand_a_data(alu_eu_operand_a_data),
        .alu_eu_operand_a_data_is_valid(alu_eu_operand_a_data_is_valid),
        .alu_eu_operand_b_data(alu_eu_operand_b_data),
        .alu_eu_operand_b_data_is_valid(alu_eu_operand_b_data_is_valid),
        .alu_eu_command_update_accepted(alu_eu_command_update_accepted),
        .alu_eu_command_result_cdb_tag(alu_eu_command_result_cdb_tag),
        // uop interface
        .command_kind(command_kind),
        .command_operand1(command_operand1),
        .command_operand2(command_operand2)
    );

    // update arbiter state
    always @(posedge clk) begin
        if(!rst_n) begin
            arbiter_state <= 0; // reset arbiter state
        end else begin 
            arbiter_state <= arbiter_state + 1;
        end
    end

endmodule