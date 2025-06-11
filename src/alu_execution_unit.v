

/*
Exposes a ALU command interface for the frontend, but distributes commands over all reservation stations.
If there is no free reservation station, command_update_accepted stay low so the computer stalls.

The module also handles CDB output arbitration for the alu reservation stations
*/
module alu_execution_unit #(
     parameter DATA_WIDTH = 4,      // the bitwidth of a data word
     parameter CDB_TAG_WIDTH = 4    // the bitwidth of a CDB tag. Ensure CDB_TAG_WIDTH<=DATA_WIDTH
)(
    // general inputs
    input clk,
    input rst_n,
    input[$clog2(RESERVATION_STATIONS)-1:0] arbiter_state,

    // cdb consumer
    input cdb_in_valid,
    input[CDB_TAG_WIDTH-1:0] cdb_in_tag,
    input[DATA_WIDTH-1:0] cdb_in_data,

    // cdb producer
    output cdb_out_request,
    output reg[DATA_WIDTH-1:0] cdb_out_data,
    output reg[CDB_TAG_WIDTH-1:0] cdb_out_tag,
    input cdb_out_accepted,

    // commands
    input command_update_en,
    input[DATA_WIDTH-1:0] operand_a_data,
    input operand_a_data_is_valid,
    input[DATA_WIDTH-1:0] operand_b_data,
    input operand_b_data_is_valid,
    output command_update_accepted,
    output[CDB_TAG_WIDTH-1:0] command_result_cdb_tag
);

    localparam RESERVATION_STATIONS = 6;
    localparam CDB_TAG_OFFSET = 0;

    wire[RESERVATION_STATIONS-1:0] cdb_out_requests;
    wire[RESERVATION_STATIONS-1:0] cdb_out_requests_granted;

    wire[RESERVATION_STATIONS-1:0] reserved_reservation_stations;
    wire[RESERVATION_STATIONS-1:0] selected_available_reservation_stations;

    wire[DATA_WIDTH-1:0] cdb_out_results[RESERVATION_STATIONS-1:0];

    round_robin_arbiter #(.INPUTS(RESERVATION_STATIONS)) cdb_out_arb(
        .req(cdb_out_requests),
        .grant(cdb_out_requests_granted),
        .state(arbiter_state)
    );

    priority_arbiter #(.INPUTS(RESERVATION_STATIONS)) free_reservation_station_arb(
        .req(~reserved_reservation_stations),
        .grant(selected_available_reservation_stations)
    );

    onehot_to_binary #(.INPUTS(RESERVATION_STATIONS), .WIDTH(CDB_TAG_WIDTH), .OFFSET(CDB_TAG_OFFSET)) command_cdb_result_tag (
        .in(selected_available_reservation_stations),
        .out(command_result_cdb_tag)
    );

    assign command_update_accepted = command_update_en && |selected_available_reservation_stations;
    assign cdb_out_request = |cdb_out_requests;

    generate
        for(genvar i=0;i<RESERVATION_STATIONS;i=i+1) begin: alu_reservation_stations
            alu_reservation_station #(.DATA_WIDTH(DATA_WIDTH), .CDB_TAG_WIDTH(CDB_TAG_WIDTH)) alu_res_1(
                .clk(clk),
                .rst_n(rst_n),
                // cdb in
                .cdb_in_valid(cdb_in_valid),
                .cdb_in_tag(cdb_in_tag),
                .cdb_in_data(cdb_in_data),
                // cdb out
                .cdb_out_request(cdb_out_requests[i]),
                .cdb_out_accepted(cdb_out_accepted && cdb_out_requests_granted[i]),
                .cdb_out_data(cdb_out_results[i]),
                // command
                .command_update_en(command_update_en && selected_available_reservation_stations[i]),
                .command_a_data(operand_a_data),
                .command_a_data_is_valid(operand_a_data_is_valid),
                .command_b_data(operand_b_data),
                .command_b_data_is_valid(operand_b_data_is_valid),
                // status
                .reserved(reserved_reservation_stations[i])
            );
        end
    endgenerate

    always @(*) begin
        cdb_out_data = {DATA_WIDTH{1'bx}};
        cdb_out_tag = {CDB_TAG_WIDTH{1'bx}};
        for (integer i = 0; i < RESERVATION_STATIONS; i = i + 1) begin
            if (cdb_out_requests_granted[i]) begin
                cdb_out_data = cdb_out_results[i];
                cdb_out_tag = CDB_TAG_OFFSET+i;
            end
        end
    end

endmodule