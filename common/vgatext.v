/*
 * This file is part of the FPGA simple VGA project
 * Copyright (c) 2019 Miguel Angel Rodriguez Jodar.
 * 
 * This program is free software: you can redistribute it and/or modify  
 * it under the terms of the GNU General Public License as published by  
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License 
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

`timescale 1ns / 1ns
`default_nettype none

module vga_text (
  input wire vclk,   // 25.125 MHz pixel clock (although 25.000 MHz works too and is easier to generate)
  // interface video RAM
	input wire [11:0] addr,
  input wire [7:0] din,
  input wire we,
  output wire [7:0] dout,
  // VGA output (1-bit)
  output reg red,
  output reg green,
  output reg blue,
  output wire hsync,
  output wire vsync
  );

  wire [10:0] hc,vc;  // horizontal and vertical counters
  // Sync generator instantiation
  videosyncs sincronismos (  // defaults to VGA 640x480@60Hz, 25 MHz
    .clk(vclk),
    .hs(hsync),
    .vs(vsync),
 	  .hc(hc),
	  .vc(vc),
    .display_enable()
  );

  reg [10:0] vaddr;  // memory address for the video controller
  wire [7:0] character,attr;  // current character and color read from memory
  wire [11:0] bmaddr = {character,vc[3:0]};  // bitmap memory address, formed from current character and current vertical scanline
  wire [7:0] bitmap;  // current bitmap scan for the shift register
  // Video and bitmap memory instantiation (dual port memory)
  vram memoria_video (
    .clk(vclk),
    // External (CPU, FSM...) interface
    .addr_sys(addr),
    .din_sys(din),
    .we_sys(we),
    .dout_sys(dout),
    // Internal interface for video generation
    .addr_video(vaddr),
    .char_video(character),
    .attr_video(attr),
    // Bitmap (character font) interface: characters are 8x16 pixels (i.e. 16 bytes per character)
    .bmaddr(bmaddr),
    .bitmap(bitmap)
  );

  // 80x25 text lines video mode. 2000 characters.
  // This mode uses 640x400 pixels. As we are generating a 640x480 screen,
  // text window starts at scanline 32, spanning to scanline 431.
  // Therefore, there is a black band above and below the text window. 32 pixels
  // for the upper band, and 48 pixels for the lower band. These must be
  // multiple of 16 to ease logic.

  reg [7:0] sr,attrout;  // shift register and attribute (color)
  wire pixel = sr[7];    // the current pixel is bit 7 of shift register
  always @(posedge vclk) begin
    if (hc[2:0] != 3'd7) // if we don't need to load the shift register, just shift it to the left.
      sr <= {sr[6:0], 1'b0};
    if (hc == 11'd0 && vc == 11'd480)  // if screen generation is over, reset the video memory address register
      vaddr <= 11'h000;
    else if (vc >= 11'd32 && vc < 11'd432 && hc >= 11'd0 && hc < 11'd640) begin  // if we are in the memory active area...
      if (hc[2:0] == 3'd7) begin  // ... and we are about to output a new character
        attrout <= attr;          // load its color from memory
        sr <= bitmap;             // and its bitmap definition for the current scan
        vaddr <= vaddr + 11'd1;   // and point to the next character
      end
    end
    else if (vc >= 11'd32 && vc < 11'd432 && hc == 11'd648) begin // if the current scanline is over...
      if (vc[3:0] != 4'd15)         // ... and we haven't finished outputting scans for the characters in this character row...
        vaddr <= vaddr - 11'd80;    // reset the video memory address to the beginning of the row
    end
  end    

  always @* begin
    if (vc >= 11'd32 && vc < 11'd432 && hc >= 11'd8 && hc < 11'd648) begin  // if we are in the video active area
      if (pixel == 1'b1)  // check pixel value
        {red, green, blue} = attrout[2:0];  // and output RGB according to its value: foreground color, or...
      else
        {red, green, blue} = attrout[6:4];  // ... background color
    end
    else
      {red, green, blue} = 3'b000;  // out of active video area, we shut down RGB
  end
endmodule

module vram (
  input wire clk,
  // External interface for VRAM. It is viewed as a 4KB memory area. Address range $0000 to $07CF points to character memory.
  // Address range $0800 to $0FCF points to color memory.
  input wire [11:0] addr_sys,
  input wire [7:0] din_sys,
  input wire we_sys,
  output wire [7:0] dout_sys,
  // VRAM interface for the video controller: here the same video RAM is viewed as two separate 2KB memory, allowing for simultaneous
  // character and color reading.
  input wire [10:0] addr_video,
  output reg [7:0] char_video,
  output reg [7:0] attr_video,
  // Bitmap RAM interface for the video controller. 256 characters, 16 bytes per character definition. 4KB memory.
  input wire [11:0] bmaddr,
  output reg [7:0] bitmap
  );

  // depending upon addr_sys[11], we either output character or color value on reading  
  reg [7:0] dout_char, dout_attr;
  assign dout_sys = (addr_sys[11] == 1'b0)? dout_char : dout_attr;
  
  (* ram_style = "block" *) reg [7:0] chram[0:2047];  // Although memory is 2048 bytes, only 2000 bytes are actually displayed.
  (* ram_style = "block" *) reg [7:0] colram[0:2047]; // Color format is: x R G B x R G B (background - foreground). x denotes a don't care bit.
  (* ram_style = "block" *) reg [7:0] bmram[0:4095];  // 256 characters, 16 bytes per character definition. 4KB memory.
  
  integer i;
  // Initial VRAM contents, just to show something on screen without generating any further logic.
  initial begin
    for (i=0;i<2048;i=i+1) begin
      chram[i]  = i[7:0];                       // Example: fill character memory with ASCII set, once and over again.
      colram[i] = {1'b0,i[5:3],1'b0,i[2:0]};    // Example: fill color memory with color bars just to show all available combinations
    end
    $readmemh ("../resources/ibm_vga_8x16.hex", bmram);  // Fill character bitmap memory from IBM VGA 8x16 character definition
  end

  always @(posedge clk) begin
    char_video <= chram[addr_video];  // Simultaneous reading of character and...
    attr_video <= colram[addr_video]; // color values, for the current video memory address
    bitmap <= bmram[bmaddr];          // read-only memory. No writes here.

    dout_char <= chram[addr_sys[10:0]];  // current character value for outside spplied address
    dout_attr <= colram[addr_sys[10:0]]; // current color value for outside spplied address

    if (we_sys == 1'b1) begin
      if (addr_sys[11] == 1'b0)
        chram[addr_sys[10:0]] <= din_sys;
      else
        colram[addr_sys[10:0]] <= din_sys;
    end
  end
endmodule
