`timescale 1ns/1ps

module tb();

localparam WIDTH = 8;

reg clock_slow;
initial clock_slow = 0;
always clock_slow = #17 ~clock_slow;

reg clock_fast;
initial clock_fast = 0;
always clock_fast = #3 ~clock_fast;

wire din_ack, dout_req;
wire [WIDTH-1:0] io, dout;
wire [WIDTH:0] ir_req;
reg din_req, dout_ack;
reg [WIDTH-1:0] din;
reg [WIDTH:0] ir_ack;

reg conf_0_req, conf_1_req;
wire conf_0_ack, conf_1_ack;
reg [23:0] conf_0;
reg [16:0] conf_1;

task delay;
input [31:0] d;
begin
    repeat (d) @(posedge clock_fast);
end
endtask

reg test_0, test_1;
reg reset;
task reset_task;
begin
    reset = 0;
    test_0 = 0;
    test_1 = 0;
    conf_0_req = 0;
    conf_1_req = 0;
    delay(100);
    reset = 1;
    delay(100);
    reset = 0;
end
endtask

task set_conf;
input [23:0] c0;
input [16:0] c1;
begin
    conf_0_req = 1;conf_1_req = 1;
    conf_0 = c0; conf_1 = c1;
    delay(1);
    while(!(conf_0_req & conf_0_ack)) delay(1);
    conf_0_req = 0;conf_1_req = 0;
end
endtask

initial begin
    reset_task();
    delay(100);
    set_conf({8'b0,8'b0011_1100,8'b1111_0000},{17'h0});
    delay(10);
    test_0 = 1;
    delay(1);
    test_1 = 1;
    delay(1000);
    set_conf({8'h0,8'b0000_0000,8'b1111_0000},{17'h0});
    delay(1000);
    set_conf({8'h0,8'b1111_1111,8'b1111_0000},{17'h0});
    delay(1000);
    set_conf({8'h0,8'b0000_0000,8'b1111_0000},{17'h0});
    delay(1000);
    set_conf({8'hFF,8'b1111_1111,8'b1111_0000},{17'h0AAAA});
    delay(1000);
    set_conf({8'hFF,8'b1111_1111,8'b0000_1111},{17'h05555});
    delay(1000);
    set_conf({8'hFF,8'b1111_1111,8'b0000_1111},{17'b1_00110011_00110011});
    delay(1000);
    set_conf({8'hFF,8'b1111_1111,8'b0000_1111},{17'b1_00110011_11001100});
    delay(1000);
    $finish;
end

reg dout_req_d;
always @(posedge clock_fast)
if (reset) dout_req_d <= 0;
else dout_req_d <= dout_req;

wire pos_dout_req;
assign pos_dout_req =  dout_req & ~dout_req_d;
wire neg_dout_req;
assign neg_dout_req = ~dout_req &  dout_req_d;

always @(posedge clock_fast)
if (reset)              dout_ack <= 0;
else if (neg_dout_req)  dout_ack <= 0;
else if (pos_dout_req)  dout_ack <= 1;
else                    dout_ack <= dout_ack;

reg din_ack_d;
always @(posedge clock_fast)
if (reset) din_ack_d <= 0;
else din_ack_d <= din_ack;

wire pos_din_ack;
assign pos_din_ack =  din_ack & ~din_ack_d;
wire neg_din_ack;
assign neg_din_ack = ~din_ack &  din_ack_d;

always @(posedge clock_fast)
if (reset) begin
    din_req <= 0;
    din <= 0;
end
else if (pos_din_ack) begin
    din_req <= 0;
    din <= din;
end
else if (neg_din_ack) begin
    din_req <= 1;
    din <= $random;
end
else if (test_0 & !test_1) begin
    din_req <= 1;
    din <= $random;
end
else begin
    din_req <= din_req;
    din <= din;
end

reg [WIDTH-1:0] data;
always @(posedge clock_fast)
if (reset)  data <= $random;
else        #500 data <= $random;

genvar i;
generate
    for (i = 0; i < WIDTH; i = i + 1) begin
        assign io[i] = conf_0[i] ? data[i] : 1'bz;
    end
endgenerate        

generate
    for (i = 0; i < WIDTH+1; i = i + 1) begin       
        always @(posedge clock_fast)
        if (reset)                      ir_ack[i] <= 0;
        else if (ir_req[i] & ir_ack[i]) ir_ack[i] <= 0;
        else if (ir_req[i])             ir_ack[i] <= 1;
        else                            ir_ack[i] <= ir_ack[i];
    end
endgenerate

gpio_top
#(
   .PORT_NUM(8)
  ,.SYNC_STAGE(2)
) gpio_top (
   .clock           (clock_slow)
  ,.reset           (reset)
  ,.io              (io)
  ,.async_din_req   (din_req)
  ,.async_din_ack   (din_ack)
  ,.async_din       (din)
  ,.async_dout_req  (dout_req)
  ,.async_dout_ack  (dout_ack)
  ,.async_dout      (dout)
  ,.async_ir_req    (ir_req)
  ,.async_ir_ack    (ir_ack)
  ,.async_conf_0_req(conf_0_req)
  ,.async_conf_0_ack(conf_0_ack)
  ,.async_conf_0    (conf_0)
  ,.async_conf_1_req(conf_1_req)
  ,.async_conf_1_ack(conf_1_ack)
  ,.async_conf_1    (conf_1)
);

endmodule