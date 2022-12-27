`timescale 1 ns/1 ns
/*module inst_mem(inst,addr,instruction);
	input [31:0]addr;
	output logic[31:0]inst;
	output logic [31:0]instruction[0:65536];
	
	initial begin
	$readmemb ("instruction.txt",instruction);
	end

	always @(addr) begin
	#5
		inst=instruction[addr>>2];
	end
endmodule */
//////////////////////////////
module ALU(z,c,a,b,alusel);
	input [31:0]a,b;
	input [2:0]alusel;
	output logic [31:0]c;
	output z;
	always @(a,b,alusel) begin
	
		case(alusel)
			3'b000:c=a+b;
			3'b001:c=a-b;
			3'b010:c=a&b;
			3'b011:c=a|b;
			3'b100:c=(a<b)? 1:0;
		endcase
	end
	assign z=(c==0)?1:0;
endmodule
//////////////////////////////
module REG32(parout,parin,ld,clk,rst);
	output logic[31:0]parout;
	input [31:0]parin;
	input ld,clk,rst;
	always @(posedge clk) begin
		
		if(rst==1) parout<=32'b0;
		else if(ld)
		parout<=parin;
	end
endmodule
///////////////////////////////
module MUX(c,a,b,sel);
	output [31:0]c;
	input [31:0]a,b;
	input sel;
	assign c=(sel)?b:a;
endmodule
///////////////////////////////
module MUX1(c,a,b,sel);
	output c;
	input a,b;
	input sel;
	assign  c=(sel==1)?b:a;
endmodule
///////////////////////////////
module MUX5(c,a,b,sel);
	output [4:0]c;
	input [4:0]a,b;
	input sel;
	assign c=(sel==1)?b:a;
endmodule
///////////////////////////////
module MUX4_1(e,a,b,c,d,sel);
	output [31:0]e;
	input [31:0]a,b,c,d;
	input [1:0]sel;
	assign  e=(sel==2'b00)? a:(sel==2'b01)? b:(sel==2'b10)? c:d;
endmodule
///////////////////////////////
module MUX3_1(d,a,b,c,sel);
	output [31:0]d;
	input [31:0]a,b,c;
	input [1:0]sel;
	assign d=(sel==2'b00)? a:(sel==2'b01)? b:(sel==2'b10)? c:a;
endmodule
///////////////////////////////
module MEM_FILE(memory,readdata,addr,writedata,memread,memwrite,clk);
	input [31:0]addr,writedata;
	input memread,memwrite,clk;
	output logic[31:0]readdata;
	output logic [31:0]memory[0:65536];
	
	initial begin
	$readmemb("memory.txt",memory);
	end

	always @(addr,memread,memwrite) begin
		//#5
		if(memread) 
			readdata=memory[addr[17:2]];
		//else readdata=32'b0;
	end
	always@(posedge clk) begin
		// #5
		if (memwrite)
			memory[addr[17:2]] = writedata;
	end
endmodule
//////////////////////////////
module REG_FILE(register,readdata1,readdata2,readreg1,readreg2,writereg,writedata,regwrite,clk);
	input [31:0]writedata;
	input [4:0]readreg1,readreg2,writereg;
	input regwrite,clk;
	output logic[31:0]readdata1,readdata2;
	output logic [31:0]register[0:31];
	
	initial begin
   		register[0]=32'b0;
  	end

	always @(readreg1,readreg2) begin
		//#5
			readdata1=register[readreg1];
			readdata2=register[readreg2];
	end

	always @(posedge clk) begin
		//#4
		if(regwrite)
			register[writereg]<=writedata;
		else
			register[writereg]<=register[writereg];
	end
endmodule
///////////////////////////////////
module ALU_CONTROL(alusel,func,aluop);
	input [5:0]func;
	input [1:0]aluop;
	output logic[2:0]alusel;

	always @(aluop,func) begin
		//#1
		if(aluop==2'b01) begin
			case(func)
				6'b100000:alusel=3'b000; //add
				6'b100001:alusel=3'b001; //sub	
				6'b100100:alusel=3'b010; //and
				6'b100101:alusel=3'b011; //or
				6'b101010:alusel=3'b100; //slt
			endcase
		end
		else if(aluop==2'b00) alusel=3'b000; //add
		else if(aluop==2'b11) alusel=3'b010; //and
		else if(aluop==2'b10) alusel=3'b001; //sub
		else alusel=3'b000;
	end
endmodule
////////////////////
module CONTROL(aluop,pcsrc,alusrcb,pcwrite,pcwritecond,notbranch,iord,memwrite,memread,r31sel,irwrite,pc4sel,regdst,memtoreg,regwrite,alusrca,opc,clk,ps,ns,rst);
	input clk,rst;
	input [5:0]opc;
	output logic[1:0] aluop,pcsrc,alusrcb;
	output logic pcwrite,pcwritecond,notbranch,iord,memwrite,memread,r31sel,irwrite,pc4sel,
		     regdst,memtoreg,regwrite,alusrca;
	
	output logic [3:0]ns,ps;
	parameter IF=0,ID=1,J=2,BEQ=3,BNE=4,RT1=5,RT2=6,MREF=7,SW=8,LW1=9,LW2=10,JAL=11,JR=12,ADDI=13,ANDI=14,RTI=15;

	always @(opc,ps,rst) begin
		//#1
		pcwrite=0; pcwritecond=0; notbranch=0; iord=0; memwrite=0; memread=0; r31sel=0; irwrite=0; pc4sel=0;
		regdst=0; memtoreg=0; regwrite=0; alusrca=0; alusrcb=2'b00; aluop=2'b00; pcsrc=2'b00; ns=5'b0;

		case(ps)
			IF:begin ns=ID; memread=1; alusrca=0; iord=0; irwrite=1; alusrcb=2'b01; aluop=2'b00; pcwrite=1; pcsrc=2'b00; end
			ID:begin case(opc)
					6'b000000: ns=RT1;	//rt
					6'b001000: ns=ADDI;	//addi
					6'b001100: ns=ANDI;	//andi
					6'b100011: ns=MREF;	//lw
					6'b101011: ns=MREF;	//sw
					6'b000100: ns=BEQ;	//beq				
					6'b000101: ns=BNE;	//bne
					6'b000010: ns=J;	//j
					6'b000011: ns=JAL;	//jal
					6'b000001: ns=JR;	//jr
					default:ns=IF;
				endcase  alusrca=0; alusrcb=2'b11; aluop=2'b00; end
			J:begin ns=IF; pcwrite=1; pcsrc=2'b01; end
			BEQ:begin ns=IF; alusrca=1; alusrcb=2'b00; aluop=2'b10; pcwritecond=1; pcsrc=2'b10; end
			BNE:begin ns=IF; alusrca=1; alusrcb=2'b00; aluop=2'b10; pcwritecond=1; pcsrc=2'b10; notbranch=1; end
			RT1:begin ns=RT2; alusrca=1; alusrcb=2'b00; aluop=2'b01; end
			RT2:begin ns=IF; regdst=1; regwrite=1; memtoreg=0; end
			MREF:begin ns=(opc==6'b100011)? LW1:SW; alusrca=1; alusrcb=2'b10; aluop=2'b00; end
			SW:begin ns=IF; memwrite=1; iord=1; end
			LW1:begin ns=LW2; memread=1; iord=1; end
			LW2:begin ns=IF; regdst=0; regwrite=1; memtoreg=1; end
			JAL:begin ns=IF; regwrite=1; pcwrite=1; pcsrc=2'b01; r31sel=1; pc4sel=1; end
			JR:begin ns=IF; alusrca=1; alusrcb=2'b00; aluop=2'b00; pcsrc=2'b00; pcwrite=1; end
			ADDI:begin ns=RTI; alusrca=1; alusrcb=2'b10; aluop=2'b00; end
			ANDI:begin ns=RTI; alusrca=1; alusrcb=2'b10; aluop=2'b11; end
			RTI:begin ns=IF; regdst=0; regwrite=1; memtoreg=0; end
			default: ns=IF;
		endcase
	end

	always @(posedge clk) begin	
		if(rst) ps<=IF;
		else
		 ps<=ns;
	end

endmodule
/////////////////////	
module DATA_PATH(register,clk,rst,memory);
	input clk,rst;
	output logic [31:0]register[0:31];
	output logic [31:0]memory[0:65536];
  	
	logic [3:0]ps,ns;
	logic[2:0]alusel;
	logic[1:0] aluop,pcsrc,alusrcb;
	logic pcwrite,pcwritecond,notbranch,memwrite,memread,r31sel,irwrite,pc4sel,
		     regdst,memtoreg,regwrite,alusrca,pcld,zero,notzero,m8,andout,iord;
	logic[31:0]pcin,aluout,bout,aout,mdr,m4,writedata,readdata1,readdata2,m6,m7,ext,shl2,aluin,jump,ir,readdata,pcout,addr;
	logic[4:0]m2,writereg;

	REG32 PC(pcout,pcin,pcld,clk,rst);
	MUX M1(addr,pcout,aluout,iord);
	MEM_FILE mf(memory,readdata,addr,bout,memread,memwrite,clk);
	REG32 IR(ir,readdata,irwrite,clk,1'b0);
	REG32 MDR(mdr,readdata,1'b1,clk,1'b0);
	MUX5 M2(m2,ir[20:16],ir[15:11],regdst);
	MUX5 M3(writereg,m2,5'b11111,r31sel);
	MUX M4(m4,aluout,mdr,memtoreg);
	MUX M5(writedata,m4,pcout,pc4sel);
	REG_FILE RF(register,readdata1,readdata2,ir[25:21],ir[20:16],writereg,writedata,regwrite,clk);
	REG32 A(aout,readdata1,1'b1,clk,1'b0);
	REG32 B(bout,readdata2,1'b1,clk,1'b0);
	MUX M6(m6,pcout,aout,alusrca);
	MUX4_1 M7(m7,bout,32'h00000004,ext,shl2,alusrcb);
	ALU alu(zero,aluin,m6,m7,alusel);
	REG32 ALUOUT(aluout,aluin,1'b1,clk,1'b0);
	MUX1 M8(m8,zero,notzero,notbranch);
	MUX3_1 M9(pcin,aluin,jump,aluout,pcsrc);
	
	ALU_CONTROL aluc(alusel,ir[5:0],aluop);
	CONTROL cr(aluop,pcsrc,alusrcb,pcwrite,pcwritecond,notbranch,iord,memwrite,memread,r31sel,irwrite,pc4sel,regdst,memtoreg,regwrite,alusrca,ir[31:26],clk,ps,ns,rst);

	not n1(notzero,zero);
	and a1(andout,m8,pcwritecond);
	or  o1(pcld,pcwrite,andout);
	assign ext[15:0]=ir[15:0];
	assign ext[31:16]={16{ir[15]}};
	assign shl2={ext[29:0],2'b00};
	assign jump={pcout[31:28],ir[25:0],2'b00};
endmodule

