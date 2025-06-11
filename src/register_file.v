
module register_file #(
    parameter REGISTER_COUNT = 8,
    parameter DATA_WIDTH = 4,      // the bitwidth of a data word
    parameter CDB_TAG_WIDTH = 4    // the bitwidth of a CDB tag. Ensure CDB_TAG_WIDTH<=DATA_WIDTH
)
(
    input clk,
    input rst_n,

    // cdb in
    input cdb_in_valid,
    input[CDB_TAG_WIDTH-1:0] cdb_in_tag,
    input[DATA_WIDTH-1:0] cdb_in_data,

    // write port
    input write_en,
    input[$clog2(REGISTER_COUNT)-1:0] write_reg_addr,
    input[EFFECTIVE_REGISTER_WIDTH-1:0] write_data,
    input write_data_valid,

    // read port 1
    input[$clog2(REGISTER_COUNT)-1:0] read_port1_addr,
    output reg[EFFECTIVE_REGISTER_WIDTH-1:0] read_port1_data,
    output reg read_port1_valid,

    // read port 2
    input[$clog2(REGISTER_COUNT)-1:0] read_port2_addr,
    output reg[EFFECTIVE_REGISTER_WIDTH-1:0] read_port2_data,
    output reg read_port2_valid
);
    localparam EFFECTIVE_REGISTER_WIDTH = (DATA_WIDTH > CDB_TAG_WIDTH) ? DATA_WIDTH : CDB_TAG_WIDTH;

    wire[EFFECTIVE_REGISTER_WIDTH-1:0] registers_data[REGISTER_COUNT-1:0];
    wire registers_valid[REGISTER_COUNT-1:0];

    wire[REGISTER_COUNT-1:0] write_en_vec = (write_en ? (1 << write_reg_addr) : 0) 
                                            | ((!rst_n) ? {REGISTER_COUNT{1'b1}} : 0);

    // register cell instantiation+write logic
    generate
        for(genvar i=0;i<REGISTER_COUNT;i=i+1) begin
            cdb_result_listener #(
                .DATA_WIDTH(EFFECTIVE_REGISTER_WIDTH),
                .CDB_TAG_WIDTH(CDB_TAG_WIDTH)
            ) register(
                .clk(clk),
                // cdb consumer
                .cdb_in_valid(cdb_in_valid),
                .cdb_in_tag(cdb_in_tag),
                .cdb_in_data(cdb_in_data),
                // commands
                .command_update_en(write_en_vec[i]),
                .command_data(write_data),
                .command_data_is_valid(!rst_n ? 1'b1 : write_data_valid),
                // output
                .valid(registers_valid[i]),
                .data(registers_data[i])
            );
        end
    endgenerate

    // register reads
    always @(*) begin
        read_port1_data = {EFFECTIVE_REGISTER_WIDTH{1'bx}};
        read_port2_data = {EFFECTIVE_REGISTER_WIDTH{1'bx}};

        read_port1_valid = 1'bx;
        read_port2_valid = 1'bx;

        for(integer i=0;i<REGISTER_COUNT;i=i+1) begin
            if (i==read_port1_addr) begin
                read_port1_data = registers_data[i];
                read_port1_valid = registers_valid[i];
            end
            if (i==read_port2_addr) begin
                read_port2_data = registers_data[i];
                read_port2_valid = registers_valid[i];
            end
        end
    end

    // reset


endmodule