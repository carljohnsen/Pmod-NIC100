from pynq import Overlay

ol = Overlay('pmod_nic100.bit')
ol.download()

print ('Loaded bitstream')

# Load the two AXI devices into variables
buf = ol.axi_bram_ctrl_0
nic = ol.Pmod_NIC100_AXI_0

# Some offsets for the AXI nic
busy   = 0
rx     = 4
rx_len = 8
tx     = 12
tx_len = 16

def send_packet(packet):
    for i in range(len(packet)):
        buf.write(i << 2, packet[i])
    while nic.read(busy) == 1:
        42 # Do nothing!
    nic.write(tx_len, len(packet))
    nic.write(tx, 1)
    while nic.read(busy) == 1:
        42 # Do nothing!

def read_packet():
    while nic.read(busy) == 1:
        42 # Do nothing!
    nic.write(rx, 1)
    while nic.read(busy) == 1:
        42 # Do nothing!
    size = nic.read(rx_len)
    packet = [buf.read(i << 2) for i in range(size)]
    return packet

