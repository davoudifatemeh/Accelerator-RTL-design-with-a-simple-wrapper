`timescale 1ns/1ns
module sine(input start, input [15:0] x1, input [7:0] y, input clk, rst, output reg[15:0] z, output reg ready);
//-------------------------Comperetor for select X-------------------------//
parameter [15:0] PI = 16'b00000011_00100011;
parameter [15:0] PI_2 = 16'b00000001_10010001;
reg[15:0] x;
always @(x1) begin
  x = 16'b0;
  if(x1>PI_2) x =  PI-x1;
  else x = x1;
end
//-------------------------Calculate x reg-------------------------//
reg[31:0] xx; 
always @(x) begin
  xx = x*x;
end  
reg[15:0] x2tempreg; 
always @(xx) begin
  x2tempreg = xx[23:8];
end  
reg[15:0] x2Reg;
reg ld_x2;
always@(posedge clk, posedge rst)begin
  if(rst) x2Reg <= 16'b0;
  else if(ld_x2) x2Reg <= x2tempreg;
end
  //-------------------------counter for select Rom-------------------------//
reg initialCnt, incCnt, cntCarry;
reg [2:0] cntIn, cntOut;
always @(posedge clk, posedge rst) begin
   if(rst) cntOut <= 3'b0;
  else if(initialCnt) cntOut <=cntIn;
  else if(incCnt) cntOut <= cntOut + 1;
  cntIn <= 3'b011;
  cntCarry <= &{incCnt, cntOut};  
end
  //-------------------------set Rom-------------------------//
reg[15:0] romOut, tempRom;
reg ld_rom;
always @(cntOut, ld_rom)begin
  case(cntOut)
    3'b011: tempRom = 16'b00000000_00101010; //(1/2*3)
    3'b100: tempRom = 16'b00000000_00001100; //(1/4*5)
    3'b101: tempRom = 16'b00000000_00000101; //(1/6*7)
    3'b110: tempRom = 16'b00000000_00000011; //(1/8*9)
    3'b111: tempRom = 16'b00000000_00000010; //(1/10*11)
  endcase
  if(ld_rom)
    romOut = tempRom;
end
  //-------------------------select between rom or x2reg-------------------------//
reg[15:0] forcal;
reg selectR, selectx2;
always @(selectR, selectx2)begin
  forcal = 16'b00000001_00000000;
  if(selectR) forcal = romOut;
  else if(selectx2) forcal = x2Reg;
end
  //-------------------------mult term-------------------------//
reg[15:0] termOut, termIn;
reg [31:0] tempCal;
always @(termOut, forcal)begin
  tempCal = termOut * forcal;
  end
always @(tempCal)begin
  termIn = tempCal[23:8];
  end
  //-------------------------term reg-------------------------//
reg ldTerm;
always@(posedge clk, posedge rst)begin
  if(rst) termOut <= 16'b0;
  else if(ldTerm) termOut <= termIn;
end
  //-------------------------MUX for term reg-------------------------//
reg selectx, selectcal;
always @(selectx, selectcal)begin
  termIn = 16'b00000001_00000000;
  if(selectx) termIn = x;
  else if(selectcal) termIn = termOut;
end
  //-------------------------sine reg-------------------------//
reg ldSine;
reg[15:0] sineIn, sineOut;
always@(posedge clk, posedge rst)begin
  if(rst) z <= 16'b0;
  else if(ldSine) z <= sineIn;
end
  //-------------------------MUX for sine reg-------------------------//
reg selectsinecal;
always @(selectx, selectsinecal)begin
  sineIn = 16'b00000000_00000000;
  if(selectx) sineIn = x;
  else if(selectsinecal) sineIn = sineOut;
end
  //-------------------------toggle for "-" or "+"-------------------------//
reg negate;
reg initialT, tg;
always@(posedge clk, posedge rst)begin
  if(rst) negate <= 1'b0;
  else if(initialT) negate <= 1'b0;
  else if(tg) negate = ~negate;
end
  //-------------------------add or sub-------------------------//
always @(negate, termOut, z)begin
  sineOut = 16'b0;
  if(negate) sineOut = z - termOut;
  else sineOut = z + termOut;
end
  //-------------------------y reg-------------------------//
reg ldY, initialY;
reg [7:0] outY;
always @(posedge clk, posedge rst)begin
  if (rst) outY <= 8'b0;
    else if (ldY) outY <= y;
    else if(initialY) outY <= 8'b0;
end
  //-------------------------comperetor for select a term for z reg-------------------------//
reg  lessT;
always @(outY, termOut)begin
  if(outY> termOut[7:0]) lessT = 1'b1;
  else  lessT = 1'b0;
end
initial lessT = &{~termOut[15:8],  lessT}; 
//-------------------------controller-------------------------//
reg [2:0] ns, ps;
parameter [2:0] idle=3'b000, starting=3'b001, load=3'b010,
               mul1=3'b011, mul2=3'b100, addsub=3'b101, check=3'b110;
always @(start, lessT, ps)begin
  {ready, selectx, initialCnt, ldY, ldSine, selectR, ld_x2,initialT, selectcal, selectx2, ldTerm, ld_rom, tg, selectsinecal, ldSine,incCnt} = 15'b0;
  ns = idle;
  case(ps)
    idle:begin
     ns = start ? starting:idle;
     ready = 1'b1;
   end
    starting:begin
      ns = start?starting:load;
      selectx = 1'b1;
      initialCnt = 1'b1;
    end
    load:begin
      ns = mul1;
      selectx = 1'b1;
      ldSine = 1'b1;
      ldTerm = 1'b1;
      ldY = 1'b1;
      ld_x2 = 1'b1;
      initialT = 1'b1;
    end
    mul1:begin
      ns = mul2;
      selectcal = 1'b1;
      selectx2 = 1'b1;
      ldTerm = 1'b1;
      ld_rom = 1'b1;
      tg = 1'b1;
    end
    mul2:begin
      ns = addsub;
      selectcal = 1'b1;
      selectR = 1'b1;
      
selectsinecal = 1'b1;
      ldTerm = 1'b1;
    end
    addsub:begin
      ns = check;
      selectsinecal = 1'b1;
      ldSine = 1'b1;
    end
    check:begin
      selectsinecal = 1'b1;
      ns= lessT ? idle : mul1;
      incCnt = 1'b1;
    end
  endcase
end

always@(posedge clk, posedge rst)begin
  if(rst) ps<=idle;
  else ps <= ns;
end
endmodule
