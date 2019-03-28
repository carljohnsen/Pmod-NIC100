from pynq import Overlay

ol = Overlay('pmod_nic100.bit')
ol.download()

print ('Loaded bitstream')

# Load the two AXI devices into variables
buf = ol.axi_bram_ctrl_0
nic = ol.Pmod_NIC100_AXI_0

# Some offsets for the AXI nic
busy   = 0
rx_tx  = 4
rx_len = 8
tx_len = 12

# Constants
BITMASK_RX = 0b01
BITMASK_TX = 0b10

# Function used for waiting
def wait():
    pass

# Function for packing bytes into an integer
def pack_bytes(data):
    tmp = 0
    for i in range(len(data)):
        tmp |= (data[i] & 0xFF) << (i*8)
    return tmp

# Function for unpacking an int into a list of 4 bytes
def unpack_bytes(data):
    return [(data >> (i*8)) & 0xFF for i in range(4)]

# Function for checking if the device is busy
def is_busy():
    return nic.read(busy) == 1

# Function for sending a packet
def send_packet(pkg):
    while is_busy(): pass
    
    ints = [pack_bytes(pkg[i<<2:(i+1)<<2]) for i in range(len(pkg) >> 2)]
    rest = len(pkg) & 0b11
    if rest > 0:
        ints += [pack_bytes(pkg[-rest:])]

    for i in range(len(ints)):
        bram.write(i << 2, ints[i])

    nic.write(tx_len, len(pkg))
    nic.write(rx_tx, BITMASK_TX)

    while is_busy(): pass

# Function for receiving a packet
def read_packet():
    while is_busy(): pass

    nic.write(rx_tx, BITMASK_RX)

    while is_busy(): pass
    
    pkg_len = nic.read(rx_len)
    ints = [bram.read(i << 2) for i in range(pkg_len >> 2)]
    rest = pkg_len & 0b11
    if rest > 0:
        ints += [bram.read(pkg_len & 0xFFFFFFFC)]

    pkg = [unpacked for val in ints for unpacked in unpack_bytes(val)]
    return pkg[:pkg_len]

