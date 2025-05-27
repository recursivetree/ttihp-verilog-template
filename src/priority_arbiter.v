`timescale 1ns/1ps

/*
A priority arbiter implementation
*/
module priority_arbiter
#(
     parameter INPUTS = 4
)
(
   input[INPUTS-1:0] req,
   output[INPUTS-1:0] grant
);

   wire[INPUTS-1:0] higher_priority_req;
   assign higher_priority_req[0] = 0;
   for(genvar i=0;i<INPUTS-1;i=i+1) begin
      assign higher_priority_req[i+1] = higher_priority_req[i] | req[i];
   end

   assign grant = req & ~higher_priority_req;
  
endmodule