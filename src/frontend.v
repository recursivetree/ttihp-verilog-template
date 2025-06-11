
module frontend(
    input clk,
    input rst_n
);

    localparam UOP_COMMAND_WIDTH = 3;
    localparam UOP_COMMAND_KIND_NOP  = 3'b000;
    localparam UOP_COMMAND_KIND_ALU  = 3'b001;
    localparam UOP_COMMAND_KIND_IMM  = 3'b010;
    localparam UOP_COMMAND_KIND_COPY = 3'b011;
    localparam UOP_COMMAND_KIND_OUT  = 3'b100;
    
endmodule