`timescale 1ns/1ps

module gpio
#(
   parameter WIDTH = 8
)(
   input  clock
  ,input  reset

  ,input                  din_valid
  ,output reg             din_ready
  ,input      [WIDTH-1:0] din

  ,output reg             dout_valid
  ,input                  dout_ready
  ,output reg [WIDTH-1:0] dout

  ,output reg [WIDTH  :0] ir_valid
  ,input      [WIDTH  :0] ir_ready
  
  ,input      [     23:0] conf_0
  ,input      [     16:0] conf_1
  
  ,inout      [WIDTH-1:0] io
);

reg [WIDTH-1:0] din_buf;

genvar i;

generate
for (i = 0; i < WIDTH; i = i + 1) begin
  assign io[i] = conf_0[i] ? 1'bz : din_buf[i];
end
endgenerate

always @(posedge clock)
if (reset)                      din_buf <= 0;
else if (din_valid & din_ready) din_buf <= din;
else                            din_buf <= din_buf;

always @(posedge clock)
if (reset)                                  din_ready <= 0;
else if (!(|conf_0[15:8]) | (&conf_0[7:0])) din_ready <= 0; //at least one io is enabled output
else if (|conf_0[15:8] & !(&conf_0[7:0]))   din_ready <= 1; //at least one io is enabled output
else                                        din_ready <= din_ready;

wire [WIDTH-1:0] io_posedge, io_negedge;
wire [WIDTH-1:0] ir_cond;

generate
for (i = 0; i < WIDTH; i = i + 1) begin
  assign io_posedge[i] = ~dout[i] &  io[i] & conf_0[i] & conf_0[i+8];
  assign io_negedge[i] =  dout[i] & ~io[i] & conf_0[i] & conf_0[i+8];
  assign ir_cond[i] = conf_0[i] & conf_0[i+8] & conf_0[i+16] & //port enabled as input and corresponding interrupt enabled
        ((~conf_1[2*i+1] & ~conf_1[2*i] & ~io[i]) |
         (~conf_1[2*i+1] &  conf_1[2*i] & io_posedge[i]) | 
         ( conf_1[2*i+1] & ~conf_1[2*i] & io_negedge[i]) | 
         ( conf_1[2*i+1] &  conf_1[2*i] &  io[i]));
  
  always @(posedge clock)
  if (reset)                          ir_valid[i] <= 0;
  else if (ir_valid[i] & ir_ready[i]) ir_valid[i] <= 0;
  else if (ir_cond[i] & !conf_1[16])  ir_valid[i] <= 1;
  else                                ir_valid[i] <= ir_valid[i];
end
endgenerate

wire all_ir_cond;
assign all_ir_cond = &(ir_cond | ~(conf_0[16:8] & conf_0[7:0])) & conf_1[16];
always @(posedge clock)
if (reset)                          ir_valid[8] <= 0;
else if (ir_valid[8] & ir_ready[8]) ir_valid[8] <= 0;
else if (all_ir_cond)               ir_valid[8] <= 1;
else                                ir_valid[8] <= ir_valid[8];

generate
for (i = 0; i < WIDTH; i = i + 1) begin
  always @(posedge clock)
  if (reset)                          dout[i] <= 0;
  else if ( conf_0[i] & conf_0[i+8])  dout[i] <= io[i];
  else if (~conf_0[i] & conf_0[i+8])  dout[i] <= din_buf[i];
  else                                dout[i] <= dout[i];
end
endgenerate

always @(posedge clock)
if (reset)                                    dout_valid <= 0;
else if (!(|conf_0[15:8]) | !(|conf_0[7:0]))  dout_valid <= 0;  //at least one io is enabled input
else if (|conf_0[15:8] & | conf_0[7:0])       dout_valid <= 1;  //at least one io is enabled input
else if (dout_valid & dout_ready)             dout_valid <= 0;
else                                          dout_valid <= dout_valid;

endmodule
