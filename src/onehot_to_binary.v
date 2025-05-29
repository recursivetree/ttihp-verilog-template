
module onehot_to_binary #(
    parameter INPUTS=4,
    parameter WIDTH=4,
    parameter OFFSET=0
)(
    input[INPUTS-1:0] in,
    output reg[WIDTH-1:0] out
);
    always @(*) begin
        out = {WIDTH{1'bx}};
        for(integer i=0; i<INPUTS; i=i+1) begin
            if(in[i] == 1) begin
                out = OFFSET+i;
            end
        end
    end

endmodule