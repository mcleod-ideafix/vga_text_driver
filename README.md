# Simple VGA text driver

A 80x25 VGA text controller, modelled to behave as a RAM for the rest of the logic.
The driver is written in plain Verilog. Works well with Quartus, ISE and Vivado.

The module exposes a synchronous SRAM-like device, with 12 bit address bus, a separate input/output 8 bit data bus and an active high write enable signal.
Addresses 000 to 7CF are used to store the ASCII code of a single text cell, linear arrangement.
Addresses 800 to FCF are used to store the color attribute for each text cell, same arrangement.
Addresses 7D0 to 7FF and FD0 to FFF are not used.

The output from this module is a 3 bit RGB signal (1 bit per primary color), plus horizontal and vertical sync signals. Polarity and timings are according to industry standard VGA 640x480@60 Hz mode.

The TLD module interface is as follows:

```
module vga_text (
  input wire vclk,   // 25.125 MHz pixel clock (although 25.000 MHz works too and is easier to generate)

  // interface video RAM
    input wire [11:0] addr,  // 12 bit address
    input wire [7:0] din,    // 8 bit input data
    input wire we,           // synchronous write enable
    output wire [7:0] dout,  // 8 bit output data. Updated at every clock tick.

  // VGA output (1-bit)
    output reg red,          // RGB outputs. Should be adapted to drive a VGA monitor.
    output reg green,        // For a 3.3V output signal, just use a series resistor
    output reg blue,         // of 270 ohms on each R,G and B output
    output wire hsync,       // Horizontal sync, negative polarity
    output wire vsync        // Vertical sync, negative polarity
  );
```

Example designs for Spartan 6, Cyclone IV and Artix 7 are included. These designs are based upon the ZXUNO/ZXDOS/UnAmiga boards, which use more than 1 bit per primary color. Porting to entry level boards, such as Basys2 should be straightforward.
