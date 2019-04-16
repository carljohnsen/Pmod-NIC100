from pynq import Overlay

ol = Overlay('design_1.bit')
ol.download()

print ('Loaded bitstream')

base_mac = [0xab] * 6

def pack(nums):
    return nums[0] | (nums[1] << 8) | (nums[2] << 16) | (nums[3] << 24)

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

# Function for unpacking list of strings into list of bytes
def pkg_to_bytes(data):
    byte_lists = [unpack_bytes(num) for num in data]
    byte_list = [y for x in byte_lists for y in x]
    return byte_list

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
    
    print('sending', len(ints), 'words of data')
    for i in range(len(ints)):
        buf.write(i << 2, ints[i])
        print('Wrote', hex(ints[i]), 'to', i << 2)

    nic.write(tx_len, len(pkg))
    nic.write(rx_tx, BITMASK_TX)

    while is_busy(): pass

# Function for receiving a packet
def read_packet():
    while is_busy(): pass

    nic.write(rx_tx, BITMASK_RX)

    while is_busy(): pass
    
    pkg_len = nic.read(rx_len)
    print("Read", pkg_len, "bytes")
    ints = [buf.read(i << 2) for i in range(pkg_len >> 2)]
    rest = pkg_len & 0b11
    if rest > 0:
        ints += [buf.read(pkg_len & 0xFFFFFFFC)]

    #pkg = [unpacked for val in ints for unpacked in unpack_bytes(val)]
    #return pkg[:pkg_len]
    return ints

# Function for replying to an ARP request
def reply_arp(dst_mac, dst_ip):
    hw_type = [0x00, 0x01]
    protocol = [0x08, 0x06]
    hw_size = [0x06]
    prot_size = [0x04]
    op = [0x00, 0x02]
    sender_mac = base_mac
    sender_ip = [192,168,2,99]
    target_mac = dst_mac
    target_ip = dst_ip

    eth_type = [0x08, 0x06]
    payload = hw_type + protocol + hw_size + prot_size + op + sender_mac + sender_ip + target_mac + target_ip

    return dst_mac + base_mac + eth_type + payload

# Function for decoding an ethernet package
def parse_eth(pkg):
    dst = pkg[:6]
    src = pkg[6:12]
    type = pkg[12:14]
    payload = pkg[14:]

    return dst, src, type, payload

# Function for decoding an ARP package
def parse_arp(pkg):
    hw_type = pkg[:2]
    protocol = pkg[2:4]
    hw_size = [pkg[4]]
    prot_size = [pkg[5]]
    opcode = pkg[6:8]
    sender_mac = pkg[8:14]
    sender_ip = pkg[14:18]
    target_mac = pkg[18:24]
    target_ip = pkg[24:28]

    return hw_type, protocol, hw_size, prot_size, opcode, sender_mac, sender_ip, target_mac, target_ip

def ping_arp_loop():
    while True:
        a = read_packet()
        a_bytes = pkg_to_bytes(a)
        a_dst, a_src, a_type, a_payload = parse_eth(a_bytes)
        if a_type == [0x08, 0x06]: # ARP
            a_hw_type, a_protocol, a_hw_size, a_prot_size, a_opcode, a_sender_mac, a_sender_ip, a_target_mac, a_target_ip = parse_arp(a_payload)
            if a_target_ip == [192,168,2,99]:
                arp_reply = reply_arp(a_src, a_sender_ip)
                send_packet(arp_reply)


