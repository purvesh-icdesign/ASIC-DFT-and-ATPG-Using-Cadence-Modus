`timescale 1ns / 1ns

module counter_test;

reg clk, rst, m;

wire [7:0] count;

initial

begin

clk=0;

rst=0; 

#5; 

rst=1;

end

initial

begin

#160;

m=0;

end

counter counter1(clk, m, rst, count);

always #5 clk=~clk;

initial $monitor("Time=%t rst=%b clk=%b m=%b count=%d", $time,rst,clk,m,count);

initial

#320 $finish;

endmodule
