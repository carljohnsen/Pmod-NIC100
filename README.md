# !!! Implementation currently does not follow this description !!!
# Pmod-NIC100
VHDL implementation of the SPI interface for Pmod NIC100 https://store.digilentinc.com/pmod-nic100-network-interface-controller/

# Quickstart
After a reset, wait for ```busy``` to go low

## Using the simple interface
To send a packet 
1. Fill the Block RAM with the packet 
2. Set ```tx_len```
3. Set ```tx```
4. Wait for ```busy``` to go high
5. Unset ```tx```
6. Wait for ```busy``` to go low

To receive a packet
1. Set ```rx```
2. Wait for ```busy``` to go high
3. Unset ```rx```
4. Wait for ```busy``` to go low
5. Read the packet from Block RAM

## Using the AXI interface
Same as when using the simple interface. However, ```rx``` and ```tx``` should not be unset, as the hardware will take care of that. The following signals are mapped to the following registers:
|Register|Signal       |
|--------|-------------|
|    0   |  ```busy``` |
|    1   |   ```rx```  |
|    2   |   ```tx```  |
|    3   | ```tx_len```|

# Notes
The VHDL file consists of two state machines:

A controller process, which issues either read or write commands

A interface process, which communicates these read or write commands onto the pins of the Pmod NIC100

Note: in the current implementation, the controller process sends a predefined package.

The SPI interface of the Pmod NIC100 has an fmax at 14 MHz.

The status and debug signals should be ignored, as they will be removed in later iterations.

# Interface definition
The current implementation uses a Block RAM as buffer, along with a few signals:
1. ```busy``` output indicating that the controller is busy. This is pulled high during initialization, and when either sending or receiving a packet.
2. ```rx``` input indicating that the controller should receive a package, when pulled high. ```busy``` should be low, otherwise this signal is ignored.
3. ```tx``` input indicating that the controller should transmit a package, when pulled high. ```busy``` should be low, otherwise this signal is ignored.
4. ```tx_len``` input indicating the size of the packet (required by the Pmod NIC100).

The second port of the Block RAM are also exposed:
- ```ena``` input ```std_logic``` for enabling the Block RAM
- ```addr``` input ```std_logic_vector(10 downto 0)``` for addressing the Block RAM. 11 bits were chosen, since a package can at most be 1500 bytes.
- ```wrena``` input ```std_logic``` for enabling writing to the Block RAM.
- ```wrdata``` input ```std_logic_vector(7 downto 0)``` for the data to be written to Block RAM.
- ```rddata``` output ```std_logic_vector(7 downto 0)``` for the data read from Block RAM.

# AXI interface