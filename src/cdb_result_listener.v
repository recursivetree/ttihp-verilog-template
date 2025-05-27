`timescale 1ns/1ps

/*
A CDB listener implementation

With the command signals, a new cdb request can be configured.
For this, when command_update_en is asserted, we are now listening for the new cdb tag in command_data.
Alternatively, when additionally command_data_is_valid is asserted, we store the data from command_data as already valid data.
When a command is applied that leads to already valid data in this clock cycle, the output valid signal is raised after the next clock cycle.

When a matching CDB request comes in, the data is copied into the internal registers and made available.

Outputs only change after a clock cycle if a command is applied.

If a command instructing the module to wait for a CDB tag that is currently being provided on the CDB, the module uses the data from the CDB event.

To minimize internal state, having an valid=0 means we are listening on the cdb. The module doesn't have an incative state where it isn't listening and not valid.
The only possible states are listening or valid. Reservation stations are expected to implement their own valid bit for such states.
*/
module cdb_result_listener
#(
     parameter DATA_WIDTH = 4,      // the bitwidth of a data word
     parameter CDB_TAG_WIDTH = 4    // the bitwidth of a CDB tag. Ensure CDB_TAG_WIDTH<=DATA_WIDTH
)
(
    input clk,      // clock

    // cdb consumer
    input cdb_in_valid,
    input[CDB_TAG_WIDTH-1:0] cdb_in_tag,
    input[DATA_WIDTH-1:0] cdb_in_data,

    // module output
    output reg valid,
    output reg[DATA_WIDTH-1:0] data,

    // module inputs
    input command_update_en,
    input[DATA_WIDTH-1:0] command_data,
    input command_data_is_valid
);
    // next states
    wire next_valid;
    wire[DATA_WIDTH-1:0] next_data;

    // if the cdb command is waiting for a tag that is currently being asserted, take the value from the cdb
    wire[DATA_WIDTH-1:0] effective_command_data = (!command_data_is_valid && cdb_in_valid && cdb_in_tag==command_data[CDB_TAG_WIDTH-1:0]) ? cdb_in_data : command_data;
    wire effective_command_data_is_valid = command_data_is_valid || (!command_data_is_valid && cdb_in_valid && cdb_in_tag==command_data[CDB_TAG_WIDTH-1:0]);

    // normal cdb hit detection
    wire is_cdb_hit = !valid && cdb_in_valid && cdb_in_tag==data[CDB_TAG_WIDTH-1:0];

    // compute next state
    assign next_valid = command_update_en ? effective_command_data_is_valid : is_cdb_hit ? 1 : valid;
    assign next_data = command_update_en ? effective_command_data : is_cdb_hit ? cdb_in_data : data;
    
    always @(posedge clk) begin 
        data <= next_data;
        valid <= next_valid;
    end;

endmodule