`timescale 1ns/1ns
module ISTB();
  reg clk,rst,drdy;
  reg [7:0] bus;
  wire [7:0] y;
  wire [15:0] x;
  wire ready,dac,start,obe;
  wire [15:0] z;
  wire brdy,reqe,grdy;
  reg gdata,gacc,gnte;
  wire [7:0] outbus;
  wr_input UUT1(clk,rst,ready,drdy,obe,bus,x,y,start,dac);
  sin UUT2(start,x,y,clk,rst,z,ready);
  wr_output UUT3(z,clk,rst,ready,gdata,gacc,gnte,brdy,reqe,obe,grdy,outbus);
  initial begin
    forever begin
    clk=0;
    #100
    clk=1;
    #100
    clk=0;
    end
  end
  initial begin
    gdata=1'b0;gacc=1'b0;gnte=1'b0;
    rst = 1'b1;
    #1 rst = 1'b0;
    #200 bus = 8'b00000100;
    #200 drdy = 1'b0;
    #200 drdy = 1'b1;
    #200 drdy = 1'b0;
    #200 bus = 8'b00000000;
    #200 drdy = 1'b0;
    #200 drdy = 1'b1;
    #200 drdy = 1'b0;
    #200 bus = 8'b00000001;
    #200 drdy = 1'b0;
    #200 drdy = 1'b1;
    #200 drdy = 1'b0;
    #500 gdata = 1'b1;
    #2000 gnte = 1'b1;
    #300 gacc = 1'b1;
    #4150 gnte = 1'b0;
    #10000 $stop;
  end
  
endmodule
