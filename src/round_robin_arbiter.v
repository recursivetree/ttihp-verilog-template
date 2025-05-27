

/*
A round-robin arbiter implementation
*/
module round_robin_arbiter
#(
     parameter INPUTS = 4
)
(
   input[INPUTS-1:0] req,
   input[$clog2(INPUTS)-1:0] state,
   output[INPUTS-1:0] grant
);

   wire[(INPUTS-1):0] mask = {(INPUTS){1'b1}} << state;

   wire[(INPUTS-1):0] masked_req = mask & req;
   wire masked_is_empty = |masked_req == 0;

   // TODO: check what is more efficient: multiplesing or two instances
   priority_arbiter #(.INPUTS(INPUTS)) arb(.req(masked_is_empty ? req : masked_req), .grant(grant));
  
endmodule