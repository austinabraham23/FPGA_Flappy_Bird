module flappybirdbg_palette (
	input logic [2:0] index,
	output logic [3:0] red, green, blue
);

localparam [0:7][11:0] palette = {
	{4'h7, 4'hC, 4'hC},
	{4'hE, 4'hD, 4'h9},
	{4'h8, 4'hD, 4'h8},
	{4'hE, 4'hF, 4'hD},
	{4'h3, 4'h6, 4'h0},
	{4'h7, 4'hB, 4'h3},
	{4'hB, 4'hD, 4'hC},
	{4'hD, 4'hA, 4'h4}
};

assign {red, green, blue} = palette[index];

endmodule


module flappy_bird_background_sprite (
	input logic vga_clk,
	input logic [9:0] DrawX, DrawY,
	input logic blank,
	
	output logic [3:0] red, green, blue
);

logic [18:0] rom_address;
logic [2:0] rom_q;

logic [3:0] palette_red, palette_green, palette_blue;

logic negedge_vga_clk;

// read from ROM on negedge, set pixel on posedge
assign negedge_vga_clk = ~vga_clk;

// address into the rom = (x*xDim)/640 + ((y*yDim)/480) * xDim
// this will stretch out the sprite across the entire screen
assign rom_address = ((DrawX * 640) / 640) + (((DrawY * 480) / 480) * 640);

always_ff @ (posedge vga_clk) begin
	red <= 4'h0;
	green <= 4'h0;
	blue <= 4'h0;

	if (blank) begin
		red <= palette_red;
		green <= palette_green;
		blue <= palette_blue;
	end
end

flappy_bird_background_rom FLAPPYBIRD_BACKGROUND_ROM (
	.clka   (negedge_vga_clk),
	.addra (rom_address),
	.douta       (rom_q)
);

flappybirdbg_palette FLAPPYBIRD_BACKGROUND_PALETTE (
	.index (rom_q),
	.red   (palette_red),
	.green (palette_green),
	.blue  (palette_blue)
);

endmodule
