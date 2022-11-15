`timescale 1ns / 1ps

module gpio_conf
(
     input              clock
    ,input              reset
    
    ,input              conf_0_valid
    ,output reg         conf_0_ready
    ,input      [23:0]  conf_0_in
    ,output reg [23:0]  conf_0_out
    ,input              conf_1_valid
    ,output reg         conf_1_ready
    ,input      [16:0]  conf_1_in
    ,output reg [16:0]  conf_1_out
);

always @(posedge clock)
if (reset)                              conf_0_ready <= 0;
else if (conf_0_valid & conf_0_ready)   conf_0_ready <= 0;
else if (conf_0_valid)                  conf_0_ready <= 1;
else                                    conf_0_ready <= conf_0_ready;

always @(posedge clock)
if (reset)                              conf_0_out <= 0;
else if (conf_0_valid & conf_0_ready)   conf_0_out <= conf_0_in;
else                                    conf_0_out <= conf_0_out;

always @(posedge clock)
if (reset)                              conf_1_ready <= 0;
else if (conf_1_valid & conf_1_ready)   conf_1_ready <= 0;
else if (conf_1_valid)                  conf_1_ready <= 1;
else                                    conf_1_ready <= conf_1_ready;

always @(posedge clock)
if (reset)                              conf_1_out <= 0;
else if (conf_1_valid & conf_1_ready)   conf_1_out <= conf_1_in;
else                                    conf_1_out <= conf_1_out;

endmodule
