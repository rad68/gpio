`timescale 1ns/1ps

/*
  FOR PORT_NUM = 8:

  Config 0:
  [7:0] direction
  [15:8] enable

  Config 1
  [15:0]  each two consecutive bits 00 - low level trigger, 
                                    01 - posedge trigger, 
                                    10 - negedge trigger,
                                    11 - high level trigger
  [23:16] interrupt enable
  [31:24] interrupt status

  Note:
    3. To clear interrupt ir handshake should occur
*/

module gpio_top
#(
   parameter PORT_NUM = 8
  ,parameter SYNC_STAGE = 2
)
(
   input                    clock
  ,input                    reset

  ,inout  [PORT_NUM  -1:0]  io

  ,input                    async_req_req
  ,output                   async_req_ack

  ,input                    async_din_req
  ,output                   async_din_ack
  ,input  [PORT_NUM  -1:0]  async_din

  ,output                   async_dout_req
  ,input                    async_dout_ack
  ,output [PORT_NUM  -1:0]  async_dout

  ,output [PORT_NUM  -1:0]  async_ir_req
  ,input  [PORT_NUM  -1:0]  async_ir_ack

  ,input                    async_conf_0_req
  ,output                   async_conf_0_ack
  ,input  [2*PORT_NUM-1:0]  async_conf_0

  ,input                    async_conf_1_req
  ,output                   async_conf_1_ack
  ,input  [4*PORT_NUM-1:0]  async_conf_1
);

wire sync_din_valid, sync_din_ready;
wire [PORT_NUM-1:0] sync_din;
async_to_sync_ctrl #(
   .DATA_WIDTH  (PORT_NUM)
  ,.SYNC_STAGE  (SYNC_STAGE)
) async_to_sync_din (
   .clock       (clock)
  ,.reset       (reset)
  ,.async_req   (async_din_req)
  ,.async_ack   (async_din_ack)
  ,.async_d     (async_din)
  ,.sync_valid  (sync_din_valid)
  ,.sync_ready  (sync_din_ready)
  ,.sync_d      (sync_din)
);

wire sync_dout_valid, sync_dout_ready;
wire [PORT_NUM-1:0] sync_dout;
sync_to_async_ctrl #(
   .DATA_WIDTH  (PORT_NUM)
  ,.SYNC_STAGE  (SYNC_STAGE)
) sync_to_async_dout (
   .clock       (clock)
  ,.reset       (reset)
  ,.sync_valid  (sync_dout_valid)
  ,.sync_ready  (sync_dout_ready)
  ,.sync_d      (sync_dout)
  ,.async_req   (async_dout_req)
  ,.async_ack   (async_dout_ack)
  ,.async_d     (async_dout)
);

wire [PORT_NUM-1:0] sync_ir_valid, sync_ir_ready;
genvar i;
generate
for (i = 0; i < PORT_NUM; i = i + 1) begin
sync_to_async_ctrl #(
   .DATA_WIDTH  (0)
  ,.SYNC_STAGE  (SYNC_STAGE)
) sync_to_async_dout (
   .clock       (clock)
  ,.reset       (reset)
  ,.sync_valid  (sync_ir_valid[i])
  ,.sync_ready  (sync_ir_ready[i])
  ,.sync_d      ()
  ,.async_req   (async_ir_req[i])
  ,.async_ack   (async_ir_ack[i])
  ,.async_d     ()
);
end
endgenerate

wire sync_conf_0_valid, sync_conf_0_ready;
wire [2*PORT_NUM-1:0] sync_conf_0;
async_to_sync_ctrl #(
   .DATA_WIDTH  (2*PORT_NUM)
  ,.SYNC_STAGE  (SYNC_STAGE)
) async_to_sync_conf_0 (
   .clock       (clock)
  ,.reset       (reset)
  ,.async_req   (async_conf_0_req)
  ,.async_ack   (async_conf_0_ack)
  ,.async_d     (async_conf_0)
  ,.sync_valid  (sync_conf_0_valid)
  ,.sync_ready  (sync_conf_0_ready)
  ,.sync_d      (sync_conf_0)
);

wire sync_conf_1_valid, sync_conf_1_ready;
wire [4*PORT_NUM-1:0] sync_conf_1;
async_to_sync_ctrl #(
     .DATA_WIDTH    (4*PORT_NUM)
    ,.SYNC_STAGE    (SYNC_STAGE)
) async_to_sync_conf_1 (
   .clock       (clock)
  ,.reset       (reset)
  ,.async_req   (async_conf_1_req)
  ,.async_ack   (async_conf_1_ack)
  ,.async_d     (async_conf_1)
  ,.sync_valid  (sync_conf_1_valid)
  ,.sync_ready  (sync_conf_1_ready)
  ,.sync_d      (sync_conf_1)
);

wire sync_req_valid, sync_req_ready;
wire [2*PORT_NUM-1:0] sync_req;
async_to_sync_ctrl #(
     .DATA_WIDTH    (0)
    ,.SYNC_STAGE    (SYNC_STAGE)
) async_to_sync_req (
   .clock       (clock)
  ,.reset       (reset)
  ,.async_req   (async_req_req)
  ,.async_ack   (async_req_ack)
  ,.async_d     ()
  ,.sync_valid  (sync_req_valid)
  ,.sync_ready  (sync_req_ready)
  ,.sync_d      ()
);

gpio #(
  .PORT_NUM(PORT_NUM)
) gpio (
   .clock       (clock)
  ,.reset       (reset)

  ,.req_valid   (sync_req_valid)
  ,.req_ready   (sync_req_ready)

  ,.din_valid   (sync_din_valid)
  ,.din_ready   (sync_din_ready)
  ,.din         (sync_din)

  ,.dout_valid  (sync_dout_valid)
  ,.dout_ready  (sync_dout_ready)
  ,.dout        (sync_dout)

  ,.ir_valid    (sync_ir_valid)
  ,.ir_ready    (sync_ir_ready)

  ,.conf_0_valid(sync_conf_0_valid)
  ,.conf_0_ready(sync_conf_0_ready)
  ,.conf_0      (sync_conf_0)

  ,.conf_1_valid(sync_conf_1_valid)
  ,.conf_1_ready(sync_conf_1_ready)
  ,.conf_1      (sync_conf_1)

  ,.io          (io)
);

endmodule
