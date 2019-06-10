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

module videosyncs (
  input wire clk,        // Clock must be as close as possible to nominal pixel clock according to ModeLine used
  output reg hs,         // Horizontal sync output, right to the monitor
  output reg vs,         // Vertical sync output, right to the monitor
 	output wire [10:0] hc, // Pixel (horizontal) counter. Note that this counter is shifted 8 pixels, so active display begins at HC=8
  output wire [10:0] vc, // Scan (vertical) counter.
  output reg display_enable // Display enable signal.
  );
	
  // https://www.mythtv.org/wiki/Modeline_Database#VESA_ModePool
  // ModeLine "800x600" 40.00 800 840 968 1056 600 601 605 628 +HSync +VSync
  // ModeLine "640x480" 25.18 640 656 752 800 480 490 492 525 -HSync -VSync
  //                      ^
  //                      +---- Pixel clock frequency in MHz
  parameter HACTIVE     = 640;
  parameter HFRONTPORCH = 656;
  parameter HSYNCPULSE  = 752;
	parameter HTOTAL      = 800;
  parameter VACTIVE     = 480;
  parameter VFRONTPORCH = 490;
  parameter VSYNCPULSE  = 492;
  parameter VTOTAL      = 525;
  parameter HSYNCPOL    = 1'b0;  // 0 = Negative polarity, 1 = positive polarity
  parameter VSYNCPOL    = 1'b0;  // 0 = Negative polarity, 1 = positive polarity

  reg [10:0] hcont = 0;
  reg [10:0] vcont = 0;
	
  assign hc = hcont;
  assign vc = vcont;

  // Horizontal and vertical counters management.
  always @(posedge clk) begin
      if (hcont == HTOTAL-1) begin
         hcont <= 11'd0;
         if (vcont == VTOTAL-1) begin
            vcont <= 11'd0;
         end
         else begin
            vcont <= vcont + 11'd1;
         end
      end
      else begin
         hcont <= hcont + 11'd1;
      end
  end
   
  // Sync and active display enable generation, according to values in ModeLine.
  always @* begin
    if (hcont>=8 && hcont<HACTIVE+8 && vcont>=0 && vcont<VACTIVE)
      display_enable = 1'b1;
    else
      display_enable = 1'b0;

    if (hcont>=HFRONTPORCH+8 && hcont<HSYNCPULSE+8)
      hs = HSYNCPOL;
    else
      hs = ~HSYNCPOL;

    if (vcont>=VFRONTPORCH && vcont<VSYNCPULSE)
      vs = VSYNCPOL;
    else
      vs = ~VSYNCPOL;
  end
endmodule   

`default_nettype wire
