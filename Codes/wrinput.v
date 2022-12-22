`timescale 1ns/1ns
module wraperInput(input clk, rst, ready ,drdy ,obe ,input [7:0] bus, output reg[15:0] x, output reg[7:0] y, output reg start, dac);
//-------------------------counter for select registers-------------------------//
  reg cntCarry, incCnt, initialCnt, ldBus, initialReg1, initialReg2, initialReg3;
  reg [1:0] init, cntOut;
  reg [7:0] Busin;
  always @(posedge clk, posedge rst) begin
    if(rst) cntOut <= 2'b0;
    else if(initialCnt) cntOut <=init;
    else if(incCnt) cntOut <= cntOut + 1;
    init <= 2'b01;
    cntCarry <= &{cntOut};  
  end
//-------------------------Dcd to select destination reg-------------------------//
  reg reg1en, reg2en, reg3en;
  always @(cntOut)begin
    {reg1en, reg2en, reg3en} = 3'b0;
    case(cntOut)
      2'b01: reg1en = 1'b1;
      2'b10: reg2en = 1'b1;
      2'b11: reg3en = 1'b1;
    endcase
  end
//-------------------------reg One-------------------------//
reg [7:0] regout1;
always @(posedge clk, posedge rst)begin
  if (rst) regout1 <= 8'b0;
    else if (reg1en) regout1 <= Busin;
    else if(initialReg1) regout1 <= 8'b0;
end
//-------------------------reg Two-------------------------//
reg [7:0] regOut2;
always @(posedge clk, posedge rst)begin
  if (rst) regOut2 <= 8'b0;
    else if (reg2en) regOut2 <= Busin;
    else if(initialReg2) regOut2 <= 8'b0;
end
//-------------------------reg three-------------------------//
reg [7:0] regOut3;
always @(posedge clk, posedge rst)begin
  if (rst) regOut3 <= 8'b0;
    else if (reg3en) regOut3 <= Busin;
    else if(initialReg3) regOut3 <= 8'b0;
end
//-------------------------bus reg-------------------------//
reg initBusReg;
always @(posedge clk, posedge rst)begin
  if (rst) Busin <= 8'b0;
    else if (ldBus) Busin <= bus;
    else if(initBusReg) Busin <= 8'b0;
end
always@(regOut2, regout1)begin
  x = {regOut2, regout1};
end
always@(regOut3)begin
  y = regOut3;
end
//-------------------------controller for wr input-------------------------//
  parameter [2:0] idle = 3'b000, load = 3'b001, acc = 3'b010, ic = 3'b011,
             drw = 3'b100, Wait = 3'b101, starting = 3'b110, calc = 3'b111;
  reg [2:0] ns, ps;
  always @(ps, ready, cntCarry, drdy, obe,cntOut)begin
  {incCnt, initialCnt, ldBus, initialReg1, initialReg2, initialReg3, start, dac,initBusReg} = 9'b0;
    ns = idle;
    case(ps)
      idle:begin
      ns = drdy ? load : idle;
      initialCnt = 1'b1;
    end
      load:begin
       ns = acc;
       ldBus = 1'b1;
     end
     acc:begin
      ns = drdy ? acc : ic;
      dac = 1'b1;
    end
     ic:begin
      ns = cntCarry ? Wait : drw;
      if(cntOut==2'b11) incCnt = 1'b0;
      else incCnt = 1'b1; 
    end
     drw:begin
       ns = drdy ? load : drw;
     end
     Wait:begin
        if(ready == 1 & obe == 1)
          ns = starting;
       else
         ns = Wait;
     end
     starting:begin
       ns = ready ? starting : calc;
       start = 1'b1;
     end
     calc:begin
       ns = ready ? idle : calc;
     end
   endcase
 end
 always@(posedge clk, posedge rst)begin
   if(rst) ps <= idle;
   else ps <= ns;
  end
endmodule
