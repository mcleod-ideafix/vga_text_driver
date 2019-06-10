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

module tld_vga_text_zxdos (
  input wire clk50mhz,
  // VGA
  output wire [2:0] ro,
  output wire [2:0] go,
  output wire [2:0] bo,
  output wire hsync,
  output wire vsync
  );

  wire sysclk;
  genreloj relojsistema (
    .CLK_IN1(clk50mhz),
    .CLK_OUT1(sysclk)
    );

  wire r,g,b;
  assign ro = {r,r,r};
  assign go = {g,g,g};
  assign bo = {b,b,b};  
  vga_text sistema (
    .vclk(sysclk),
    // interface video RAM
    .addr(12'h0000),
    .din(8'h00),
    .we(1'b0),
    .dout(),
    // VGA output
    .red(r),
    .green(g),
    .blue(b),
    .hsync(hsync),
    .vsync(vsync)
  );
endmodule

`default_nettype wire
