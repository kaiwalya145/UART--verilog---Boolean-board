UART Transmitter and Receiver on Boolean Board

A UART (Universal Asynchronous Receiver/Transmitter) designed in Verilog HDL, simulated and implemented in Xilinx Vivado, and tested on the Boolean FPGA board (Spartan-7). Built as the mini project for VLSI Design Lab (Experiment 11).

<img width="958" height="669" alt="1bfa8a56e075cdc92c0b03204c6c5618" src="https://github.com/user-attachments/assets/26d93ad3-b396-42bc-8c0a-9101f19b1269" />

Features
UART transmitter and receiver in synthesizable Verilog
Frame format: 8 data bits, no parity, 1 stop bit (8N1)
Configurable baud rate via a clock-divider baud generator (default: [9600] baud)
Behavioral testbench with waveform verification
Tested on hardware over the board's on-board USB-UART (PROG UART) port, so no external USB-UART adapter is needed
Specs
Parameter	Value
Board	Boolean (Xilinx Spartan-7)
Tool	Vivado [version, e.g. 2023.1]
Language	Verilog HDL
System clock	100 MHz
Baud rate	[9600]
Frame	8N1

How It Works

Baud generator: divides the 100 MHz clock to produce a tick at the baud rate (or 16x oversampling for the receiver). Divider = 100_000_000 / baud_rate.

Transmitter: FSM with states IDLE → START → DATA → STOP. Loads an 8-bit byte, sends the start bit (0), 8 data bits LSB first, then the stop bit (1).

Receiver: FSM that detects the falling edge of the start bit, samples each bit at its midpoint, shifts in 8 bits LSB first, checks the stop bit, then asserts a done/valid flag with the received byte.

Simulation
Open Vivado and create a project (or run the Tcl script below).
Add src/*.v as design sources and sim/tb_uart.v as the simulation source.
Set tb_uart as the top simulation module and run Behavioral Simulation.
Check that the transmitted byte appears correctly on the receiver output.


Build and Program on Boolean Board
Add constraints/boolean.xdc as the constraint file.
Run Synthesis → Implementation → Generate Bitstream.
Connect the board with a USB cable to the PROG UART port and power it on.
Open Hardware Manager → Auto Connect → Program Device.
Open a serial terminal (PuTTY / Tera Term) on the board's COM port at [9600] baud, 8N1.
[Describe the demo here, e.g. "Type a character in the terminal; the board echoes it back and shows it on the LEDs."]


# From Vivado Tcl console, inside the repo folder
source create_project.tcl

Generate this script in Vivado with File → Project → Write Tcl.

What I Learned
FSM-based design for serial protocols
Clock division and baud rate timing
Mid-bit sampling in the receiver
Vivado flow: simulation, synthesis, implementation, bitstream, hardware debug
Author

Kaiwalya (@kaiwalya145) Third Year E&TC, MMCOE Pune
