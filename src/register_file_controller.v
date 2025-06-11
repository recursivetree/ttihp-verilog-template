
module register_file_controller #(
    parameter REGISTER_COUNT = 8,
    parameter DATA_WIDTH = 4,      // the bitwidth of a data word
    parameter CDB_TAG_WIDTH = 4,   // the bitwidth of a CDB tag. Ensure CDB_TAG_WIDTH<=DATA_WIDTH
    parameter UOP_COMMAND_WIDTH = 3     // the bitwidth of a uop command
)
(
    input clk,
    input rst_n,

    // cdb in
    input cdb_in_valid,
    input[CDB_TAG_WIDTH-1:0] cdb_in_tag,
    input[DATA_WIDTH-1:0] cdb_in_data,

    // decode stage interface
    output reg rf_controller_stall,
    input[UOP_COMMAND_WIDTH-1:0] command_kind,
    input[$clog2(REGISTER_COUNT)-1:0] command_operand1,
    input[COMMAND_OP2_SIZE-1:0] command_operand2,

    // alu execution unit interface
    output reg alu_eu_command_update_en,
    output reg[DATA_WIDTH-1:0] alu_eu_operand_a_data,
    output reg alu_eu_operand_a_data_is_valid,
    output reg[DATA_WIDTH-1:0] alu_eu_operand_b_data,
    output reg alu_eu_operand_b_data_is_valid,
    input alu_eu_command_update_accepted,
    input[CDB_TAG_WIDTH-1:0] alu_eu_command_result_cdb_tag
);
    localparam EFFECTIVE_REGISTER_WIDTH = (DATA_WIDTH > CDB_TAG_WIDTH) ? DATA_WIDTH : CDB_TAG_WIDTH;
    localparam COMMAND_OP2_SIZE = (DATA_WIDTH > $clog2(REGISTER_COUNT)) ? DATA_WIDTH : $clog2(REGISTER_COUNT);

    localparam UOP_COMMAND_KIND_NOP  = 3'b000;
    localparam UOP_COMMAND_KIND_ALU  = 3'b001;
    localparam UOP_COMMAND_KIND_IMM  = 3'b010;
    localparam UOP_COMMAND_KIND_COPY = 3'b011;
    localparam UOP_COMMAND_KIND_OUT  = 3'b100;

    // RF write interface
    reg rf_write_en;
    reg[$clog2(REGISTER_COUNT)-1:0] rf_write_reg_addr;
    reg[EFFECTIVE_REGISTER_WIDTH-1:0] rf_write_data;
    reg rf_write_data_valid;

    // RF read port 1
    reg[$clog2(REGISTER_COUNT)-1:0] rf_read_port1_addr;
    wire[EFFECTIVE_REGISTER_WIDTH-1:0] rf_read_port1_data;
    wire rf_read_port1_valid;

    // RF read port 2
    reg[$clog2(REGISTER_COUNT)-1:0] rf_read_port2_addr;
    wire[EFFECTIVE_REGISTER_WIDTH-1:0] rf_read_port2_data;
    wire rf_read_port2_valid;


    always @(*) begin
        case (command_kind)
            UOP_COMMAND_KIND_ALU: begin
                // RF write
                rf_write_en = alu_eu_command_update_accepted;   // alu operations produce a result, but only update the RF once eu accepts
                rf_write_reg_addr = 0;                          // alu result goes to ACC
                rf_write_data = alu_eu_command_result_cdb_tag;  // result will be made available fom alu eu
                rf_write_data_valid = 0;                        // alu result is not yet ready
                // RF read ports
                rf_read_port1_addr = command_operand1;  // alu operands are the register
                rf_read_port2_addr = command_operand2;  // alu operands are the register
                // alu execution unit
                alu_eu_command_update_en = 1;                           // we want to execute on the ALU
                alu_eu_operand_a_data = rf_read_port1_data;             // take alu operand data from register file
                alu_eu_operand_a_data_is_valid = rf_read_port1_valid;   // take alu operand validity from register file
                alu_eu_operand_b_data = rf_read_port2_data;             // take alu operand data from register file
                alu_eu_operand_b_data_is_valid = rf_read_port2_valid;   // take alu operand validity from register file
                // stall output
                rf_controller_stall = alu_eu_command_update_accepted;
            end
            UOP_COMMAND_KIND_IMM: begin
                // RF write
                rf_write_en = 1;                    // load immediates can always execute in one cycle  
                rf_write_reg_addr = 0;              // load immediate data goes to the accumulator                          
                rf_write_data = command_operand2;   // the immeidate data is stored in the second operand
                rf_write_data_valid = 0;                        
                // RF read ports
                rf_read_port1_addr = {$clog2(REGISTER_COUNT){1'bx}};  // we don't want to read anything
                rf_read_port2_addr = {$clog2(REGISTER_COUNT){1'bx}};  // we don't want to read anything
                // alu execution unit
                alu_eu_command_update_en = 0;                   // don't update alu eu file
                alu_eu_operand_a_data =  {DATA_WIDTH{1'bx}};    // meaning we don't care about data
                alu_eu_operand_a_data_is_valid = 1'bx;          // meaning we don't care about data
                alu_eu_operand_b_data = {DATA_WIDTH{1'bx}};     // meaning we don't care about data
                alu_eu_operand_b_data_is_valid = 1'bx;          // meaning we don't care about data
                // stall output
                rf_controller_stall = 0;    // load immediate can always execute in one cycle  
            end
            UOP_COMMAND_KIND_COPY: begin
                // RF write
                rf_write_en = 1;                            // copy can always execute in one cycle  
                rf_write_reg_addr = command_operand2;       // operand2 is the destination of the copy
                rf_write_data = rf_read_port1_data;         // we write the data from the read port
                rf_write_data_valid = rf_read_port1_valid;  // we write the data from the read port
                // RF read ports
                rf_read_port1_addr = command_operand1;                // operand1 is the copy source. we use port 1 for copying
                rf_read_port2_addr = {$clog2(REGISTER_COUNT){1'bx}};  // we don't want to read anything on port 2
                // alu execution unit
                alu_eu_command_update_en = 0;                   // don't update alu eu file
                alu_eu_operand_a_data =  {DATA_WIDTH{1'bx}};    // meaning we don't care about data
                alu_eu_operand_a_data_is_valid = 1'bx;          // meaning we don't care about data
                alu_eu_operand_b_data = {DATA_WIDTH{1'bx}};     // meaning we don't care about data
                alu_eu_operand_b_data_is_valid = 1'bx;          // meaning we don't care about data
                // stall output
                rf_controller_stall = 0;    // copy can always execute in one cycle  
            end
            // NOP or not implement(treat as NOP), still have to assign though
            default: begin
                // RF write
                rf_write_en = 0;                                    // don't update register file
                rf_write_reg_addr = {$clog2(REGISTER_COUNT){1'bx}}; // meaning address can be anything
                rf_write_data = {EFFECTIVE_REGISTER_WIDTH{1'bx}};   // same for data
                rf_write_data_valid = 1'bx;                         // and if valid
                // RF read ports
                rf_read_port1_addr = {$clog2(REGISTER_COUNT){1'bx}};  // we don't want to read anything
                rf_read_port2_addr = {$clog2(REGISTER_COUNT){1'bx}};  // we don't want to read anything
                // alu execution unit
                alu_eu_command_update_en = 0;                   // don't update alu eu file
                alu_eu_operand_a_data =  {DATA_WIDTH{1'bx}};    // meaning we don't care about data
                alu_eu_operand_a_data_is_valid = 1'bx;          // meaning we don't care about data
                alu_eu_operand_b_data = {DATA_WIDTH{1'bx}};     // meaning we don't care about data
                alu_eu_operand_b_data_is_valid = 1'bx;          // meaning we don't care about data
                // stall output
                rf_controller_stall = 0;
            end
        endcase
    end


    register_file #(
        .REGISTER_COUNT(REGISTER_COUNT),
        .DATA_WIDTH(DATA_WIDTH),
        .CDB_TAG_WIDTH(CDB_TAG_WIDTH)
    ) rf(
        .clk(clk),
        .rst_n(rst_n),

        // cdb in
        .cdb_in_valid(cdb_in_valid),
        .cdb_in_tag(cdb_in_tag),
        .cdb_in_data(cdb_in_data),

        // write port
        .write_en(rf_write_en),
        .write_reg_addr(rf_write_reg_addr),
        .write_data(rf_write_data),
        .write_data_valid(rf_write_data_valid),

        // read port 1
        .read_port1_addr(rf_read_port1_addr),
        .read_port1_data(rf_read_port1_data),
        .read_port1_valid(rf_read_port1_valid),

        // read port 2
        .read_port2_addr(rf_read_port2_addr),
        .read_port2_data(rf_read_port2_data),
        .read_port2_valid(rf_read_port2_valid)
    );
    
endmodule