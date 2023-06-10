`timescale 1ns/1ps

module gpio
#(
   parameter PORT_NUM = 8
)(
   input  clock
  ,input  reset

  ,input                      req_valid
  ,output reg                 req_ready

  ,input                      din_valid
  ,output reg                 din_ready
  ,input      [PORT_NUM-1:0]  din

  ,output reg                 dout_valid
  ,input                      dout_ready
  ,output reg [PORT_NUM-1:0]  dout

  ,output reg [PORT_NUM-1:0]  ir_valid
  ,input      [PORT_NUM-1:0]  ir_ready
  
  ,input                       conf_0_valid
  ,output reg                  conf_0_ready
  ,input      [2*PORT_NUM-1:0] conf_0

  ,input                       conf_1_valid
  ,output reg                  conf_1_ready
  ,input      [4*PORT_NUM-1:0] conf_1
  
  ,inout      [PORT_NUM-1:0]  io
);

reg [2*PORT_NUM-1:0] conf_0_loc;
reg [4*PORT_NUM-1:0] conf_1_loc;
always @(posedge clock)
if (reset)                              conf_0_ready <= 0;
else if (conf_0_valid & conf_0_ready)   conf_0_ready <= 0;
else if (conf_0_valid)                  conf_0_ready <= 1;
else                                    conf_0_ready <= conf_0_ready;

always @(posedge clock)
if (reset)                              conf_0_loc <= 0;
else if (conf_0_valid & conf_0_ready)   conf_0_loc <= conf_0;
else                                    conf_0_loc <= conf_0_loc;

always @(posedge clock)
if (reset)                              conf_1_ready <= 0;
else if (conf_1_valid & conf_1_ready)   conf_1_ready <= 0;
else if (conf_1_valid)                  conf_1_ready <= 1;
else                                    conf_1_ready <= conf_1_ready;

always @(posedge clock)
if (reset)                              conf_1_loc <= 0;
else if (conf_1_valid & conf_1_ready)   conf_1_loc <= conf_1;
else                                    conf_1_loc <= conf_1_loc;

reg [PORT_NUM-1:0] din_buf;

genvar i;
generate
for (i = 0; i < PORT_NUM; i = i + 1) begin
  assign io[i] = conf_0_loc[i] & conf_0_loc[i+8] ? 1'bz : din_buf[i];
end
endgenerate

generate
for (i = 0; i < PORT_NUM; i = i + 1) begin
  always @(posedge clock)
  if (reset)                  din_buf[i] <= 0;
  else if (!conf_0_loc[i+8])  din_buf[i] <= 0;
  else if (din_valid)         din_buf[i] <= din[i];
  else                        din_buf[i] <= din_buf[i];
end
endgenerate

always @(posedge clock)
if (reset)                      din_ready <= 0;
else if (din_valid & din_ready) din_ready <= 0;
else if (din_valid)             din_ready <= 1;
else                            din_ready <= din_ready;

wire [PORT_NUM-1:0] io_posedge, io_negedge;
wire [PORT_NUM-1:0] ir_cond;
wire [PORT_NUM-1:0] ir_lo, ir_hi, ir_po, ir_ne;
reg  [PORT_NUM-1:0] ir_stat;
reg  [PORT_NUM-1:0] io_d;


generate
for (i = 0; i < PORT_NUM; i = i + 1) begin
  always @(posedge clock)
  if (reset)                                                    io_d[i] <= 0;
  else if (conf_0_loc[i] & conf_0_loc[i+8] & conf_1_loc[i+16])  io_d[i] <= io[i];
  else                                                          io_d[i] <= io_d[i];

  assign io_posedge[i] = ~io_d[i] &  io[i] & conf_0_loc[i] & conf_0_loc[i+8];
  assign ir_po[i] = ~conf_1_loc[2*i+1] &  conf_1_loc[2*i] &  io_posedge[i];

  assign io_negedge[i] =  io_d[i] & ~io[i] & conf_0_loc[i] & conf_0_loc[i+8];
  assign ir_ne[i] =  conf_1_loc[2*i+1] & ~conf_1_loc[2*i] &  io_negedge[i];

  assign ir_lo[i] = ~conf_1_loc[2*i+1] & ~conf_1_loc[2*i] & ~io[i];
  assign ir_hi[i] =  conf_1_loc[2*i+1] &  conf_1_loc[2*i] &  io[i];

  assign ir_cond[i] = conf_0_loc[i] & conf_0_loc[i+8] & conf_1_loc[i+16] &
        ((ir_lo[i]) | (ir_po[i]) | (ir_ne[i]) | (ir_hi[i]));
  
  always @(posedge clock)
  if (reset)                          ir_valid[i] <= 0;
  else if (ir_valid[i] & ir_ready[i]) ir_valid[i] <= 0;
  else if (ir_cond[i] & !ir_stat[i])  ir_valid[i] <= 1;
  else                                ir_valid[i] <= ir_valid[i];

  always @(posedge clock)
  if (reset)                                          ir_stat[i] <= 0;
  else if (ir_valid[i] & ir_ready[i])                 ir_stat[i] <= 1;
  else if (ir_stat[i] & conf_1_valid & !conf_1[i+24]) ir_stat[i] <= 0;
  else                                                ir_stat[i] <= ir_stat[i];
end
endgenerate

generate
for (i = 0; i < PORT_NUM; i = i + 1) begin
  always @(posedge clock)
  if (reset)                              dout[i] <= 0;
  else if (req_valid & !conf_0_loc[i+8])  dout[i] <= 0;
  else if (req_valid &  conf_0_loc[i])    dout[i] <= io[i];
  else                                    dout[i] <= dout[i];
end
endgenerate

always @(posedge clock)
if (reset)                        dout_valid <= 0;
else if (dout_valid & dout_ready) dout_valid <= 0;
else if (req_valid)               dout_valid <= 1;
else                              dout_valid <= dout_valid;

always @(posedge clock)
if (reset)                      req_ready <= 0;
else if (req_valid & req_ready) req_ready <= 0;
else if (req_valid)             req_ready <= 1;
else                            req_ready <= req_ready;

endmodule
