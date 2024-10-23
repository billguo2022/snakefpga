
module snake_top (MemOE, MemWR, RamCS, QuadSpiFlashCS,
				ClkPort, BtnL, BtnR, BtnU, BtnD, BtnC, Sw0,
				Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0,
				Dp, Cg, Cf, Ce, Cd, Cc, Cb, Ca,
				An7, An6, An5, An4, An3, An2, An1, An0,
				hSync, vSync, vgaR, vgaG, vgaB);

// Inputs
input ClkPort;
input BtnL, BtnR, BtnU, BtnD, BtnC;
input Sw0;

// Outputs

output 	MemOE, MemWR, RamCS, QuadSpiFlashCS;

output Ld7, Ld6, Ld5, Ld4, Ld3, Ld2, Ld1, Ld0;
output Dp, Cg, Cf, Ce, Cd, Cc, Cb, Ca;
output An7, An6, An5, An4, An3, An2, An1, An0;

output hSync, vSync;
output [3:0] vgaR, vgaG, vgaB;

// Clock Signals
wire ClkPort;

wire board_clk, game_clk, ssd_clk;
reg [32:0] div_clk;

// Other
wire reset;
wire Qi, Qm, Qc, Qh, Qe, Qw, Ql, Qu;
wire [7:0] food;
wire [3:0] length;

// cannot input/output byte arrays in Verilog (without SystemVerilog). instead, we pack the byte array into a 128-bit
// wire and i/o this wire
wire [127:0] locations_flat;

// DC, SC Outputs
wire [9:0] vc;
wire [9:0] hc;
wire [11:0] rgb;
wire [11:0] background;

assign vgaR = rgb[11 : 8];
assign vgaG = rgb[7  : 4];
assign vgaB = rgb[3  : 0];

// SSD
reg [7:0] SSD;
wire SSD2;
wire [3:0] SSD1;
reg [7:0] SSD_CATHODES;


assign reset = Sw0;

// disable memory ports
assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;

// Clock Division
BUFGP BUFGP1 (board_clk, ClkPort);
always @(posedge board_clk, posedge reset)
begin
	if (reset) begin
		div_clk <= 0;
	end
	else begin
		div_clk <= div_clk + 1'b1;
	end
end

assign game_clk = div_clk[22]; 
assign vga_clk = div_clk[19];



snake_core snake_core1 (.Left(BtnL), .Right(BtnR), .Up(BtnU), .Down(BtnD), .Ack(BtnC), .Reset(reset), .Clk(game_clk), .Qi(Qi), .Qm(Qm), .Qc(Qc), .Qh(Qh), .Qe(Qe), 
					.Qw(Qw), .Ql(Ql), .Qu(Qu), .Food(food), .Length(length), .Locations_Flat(locations_flat));

display_controller dc(.clk(board_clk), .hSync(hSync), .vSync(vSync), .bright(bright), .hCount(hc), .vCount(vc));
snake_controller sc(.Clk(vga_clk), .Bright(bright), .Reset(BtnC), .Qi(Qi), .Qw(Qw), .Ql(Ql), .Qc(Qc), .hCount(hc), .vCount(vc), .Food(food), .Length(length), .Locations_Flat(locations_flat), .rgb(rgb), .background(background));
	

assign {Ld7, Ld6, Ld5, Ld4} = {Qi, Qm, Qc, Qh};
assign {Ld3, Ld2, Ld1, Ld0} = {Qe, Qw, Ql, Qu};


assign SSD7 = 4'b0000;
assign SSD6 = background[11:8];
assign SSD5 = background[7:4];
assign SSD4 = background[3:0];
assign ssdscan_clk = div_clk[19:18];

assign SSD1 = (length >= 10) ? 1'b1 : 1'b0;
assign SSD2 = (length % 10);

assign An7 = 1'b1;
assign An6 = 1'b1;
assign An5 = 1'b1;
assign An4 = 1'b1;
assign An3 = 1'b1;
assign An2 = 1'b1;
assign An1 = ~ssdscan_clk;
assign An0 = ssdscan_clk;

always @ (ssdscan_clk, SSD1, SSD2)
begin
	case (ssdscan_clk) 
		1'b1: SSD = {4'b0000, SSD1};
		1'b0: SSD = {7'b0000000, SSD2};
	endcase 
end

always @ (ssdscan_clk, SSD4, SSD5, SSD6, SSD7)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
				  3'b100: SSD = SSD4;
				  3'b101: SSD = SSD5;
				  3'b110: SSD = SSD6;
				  3'b111: SSD = SSD7;
		endcase 
	end

assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};

always @( SSD )
begin
	case (SSD)
		8'd0: SSD_CATHODES = 8'b00000011; // 0
		8'd1: SSD_CATHODES = 8'b10011111; // 1
		8'd2: SSD_CATHODES = 8'b00100101; // 2
		8'd3: SSD_CATHODES = 8'b00001101; // 3
		8'd4: SSD_CATHODES = 8'b10011001; // 4
		8'd5: SSD_CATHODES = 8'b01001001; // 5
		8'd6: SSD_CATHODES = 8'b01000001; // 6
		8'd7: SSD_CATHODES = 8'b00011111; // 7
		8'd8: SSD_CATHODES = 8'b00000001; // 8
		8'd9: SSD_CATHODES = 8'b00001001; // 9
		endcase
end

   always @ (SSD) 
	  begin : HEX_TO_SSD
		case (SSD) // in this solution file the dot points are made to glow by making Dp = 0
		    //                                                                abcdefg,Dp
			
			4'b1010: SSD_CATHODES = 8'b00010000; // A
			4'b1011: SSD_CATHODES = 8'b11000000; // B
			4'b1100: SSD_CATHODES = 8'b01100010; // C
			4'b1101: SSD_CATHODES = 8'b10000100; // D
			4'b1110: SSD_CATHODES = 8'b01100000; // E
			4'b1111: SSD_CATHODES = 8'b01110000; // F    
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end	
	
endmodule