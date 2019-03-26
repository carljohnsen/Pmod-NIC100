# Pmod-NIC100
VHDL implementation of the SPI interface for Pmod NIC100 https://store.digilentinc.com/pmod-nic100-network-interface-controller/

The VHDL file consists of two state machines:

A controller process, which issues either read or write commands

A interface process, which communicates these read or write commands onto the pins of the Pmod NIC100

Note: in the current implementation, the controller process sends a predefined package.

The SPI interface of the Pmod NIC100 has an fmax at 14 MHz.

The status and debug signals should be ignored, as they will be removed in later iterations.