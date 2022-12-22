module wraperOutput(input [15:0] z, input clk, rst, ready, gdata, gacc, gnte, output reg brdy, reqe, obe, grdy, output reg[7:0] outbus );
  reg initDreq, initFreg, ldDreg, ldFreg, incCnt, initialCnt, cntCarry, cntOut;
  reg [7:0] regFout, regDout, outSelect;
  //-------------------------D reg-------------------------//
  always @(posedge clk, posedge rst)begin
    if(rst) regDout <= 8'b0;
    else if(initDreq) regDout <= 8'b0;
    else if(ldDreg) regDout <= z[15:8];
  end
  //-------------------------F reg-------------------------//
  always @(posedge clk, posedge rst)begin
    if(rst) regFout <= 8'b0;
    else if(initFreg) regFout <= 8'b0;
    else if(ldFreg) regFout <= z[7:0];
  end
  //-------------------------counter for select registers-------------------------//
  always @(posedge clk, posedge rst)begin
    if(rst) cntOut <= 1'b0;
    else if(initialCnt) cntOut <= 1'b0;
    else if(incCnt) cntOut <= cntOut + 1;
  end
  always@(cntOut, incCnt)begin
    cntCarry = cntOut & incCnt;
  end
  //-------------------------MUX for select between F or D reg-------------------------//
  always@(cntOut,regFout, regDout)begin
    outSelect = cntOut ? regFout : regDout;
  end
  //-------------------------set outBus-------------------------//
  always@(gnte,outSelect)begin
    outbus = gnte ? outSelect : 8'bz;
  end
  //-------------------------controller for wr output-------------------------//
  parameter [2:0] idle = 3'b000, load = 3'b001, Brdy = 3'b010, waitfordata = 3'b011,
                  waitforaccept = 3'b100, nextdata = 3'b101;
  reg [2:0] ns, ps;
  always @(ps, gdata, gnte, gacc, cntCarry,ready)begin
    {initFreg, initDreq, ldDreg, ldFreg, brdy, reqe, obe, grdy, initialCnt, incCnt} = 10'b0;
    case(ps)
    idle:begin
      ns = ready ? load : idle;
      obe = 1'b1; initialCnt = 1'b1;
    end
    load:begin
      ns = Brdy;
      ldDreg = 1'b1; ldFreg = 1'b1;
    end
    Brdy:begin
      ns = gdata ? waitfordata : Brdy;
      brdy = 1'b1;
    end
    waitfordata:begin
      ns = gnte ? waitforaccept : waitfordata;
      reqe = 1'b1; grdy = 1'b1;
    end
    waitforaccept:begin
      ns = gacc ? nextdata : waitforaccept;
      reqe = 1'b1;
    end
    nextdata:begin
      ns = cntCarry ? idle : waitforaccept;
      incCnt = 1'b1; reqe = 1'b1;
    end
  endcase
  end
  always @(posedge clk, posedge rst)begin
    if(rst) ps <= idle;
    else ps <=ns;
    end
 endmodule