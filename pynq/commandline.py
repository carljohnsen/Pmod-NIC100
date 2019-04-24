from pynq import Overlay
import sys
import socket

ol = Overlay('design_1.bit')
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
ARP_REQUEST = [0, 1]
ETH_TYPE_ARP = [0x08, 0x06]
ETH_TYPE_IP = [0x08, 0x00]
ICMP_PING_REPLY = [0x00]
ICMP_PING_REQUEST = [0x08]
IP_BASE = [192,168,2,99]
IP_PROT_ICMP = [0x01]
MAC_BASE = [0xab] * 6
MAC_BROADCAST = [0xff] * 6

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
    
    #print('sending', len(ints), 'words of data')
    for i in range(len(ints)):
        buf.write(i << 2, ints[i])
        #print('Wrote', format(ints[i], '08x'), 'to', i << 2)

    nic.write(tx_len, len(pkg))
    nic.write(rx_tx, BITMASK_TX)

    while is_busy(): pass

# Function for receiving a packet
def read_packet():
    while is_busy(): pass

    nic.write(rx_tx, BITMASK_RX)

    while is_busy(): pass
    
    pkg_len = nic.read(rx_len)
    #print("Read", pkg_len, "bytes")
    ints = [buf.read(i << 2) for i in range(pkg_len >> 2)]
    rest = pkg_len & 0b11
    if rest > 0:
        ints += [buf.read(pkg_len & 0xFFFFFFFC)]

    #pkg = [unpacked for val in ints for unpacked in unpack_bytes(val)]
    #return pkg[:pkg_len]
    return ints

def checksum(source_string):
    countTo = (int(len(source_string) / 2)) * 2
    my_sum = 0
    count = 0
    loByte = 0
    hiByte = 0
    while count < countTo:
        if (sys.byteorder == "little"):
            loByte = source_string[count]
            hiByte = source_string[count + 1]
        else:
            loByte = source_string[count + 1]
            hiByte = source_string[count]
        try:     # For Python3
            my_sum = my_sum + (hiByte * 256 + loByte)
        except:  # For Python2
            my_sum = my_sum + (ord(hiByte) * 256 + ord(loByte))
        count += 2
    if countTo < len(source_string):  # Check for odd length
        loByte = source_string[len(source_string) - 1]
        try:      # For Python3
            my_sum += loByte
        except:   # For Python2
            my_sum += ord(loByte)
    my_sum &= 0xffffffff 
    my_sum = (my_sum >> 16) + (my_sum & 0xffff)  
    my_sum += (my_sum >> 16)                     
    answer = ~my_sum & 0xffff                    
    answer = socket.htons(answer)
    return [(answer >> 8) & 0xFF, answer & 0xFF]

# Function for replying to an ARP request
def reply_arp(dst_mac, dst_ip):
    hw_type = [0x00, 0x01]
    protocol = [0x08, 0x00]
    hw_size = [0x06]
    prot_size = [0x04]
    op = [0x00, 0x02]
    sender_mac = MAC_BASE
    sender_ip = [192,168,2,99]
    target_mac = dst_mac
    target_ip = dst_ip

    eth_type = [0x08, 0x06]
    payload = hw_type + protocol + hw_size + prot_size + op + sender_mac + sender_ip + target_mac + target_ip

    return dst_mac + MAC_BASE + eth_type + payload

def make_eth_header(dst, eth_type):
    return dst + MAC_BASE + eth_type

def make_icmp_header(icmp_type, code, ident, seq, timestamp, data):
    chksum = checksum(icmp_type + code + [0,0] + ident + seq + timestamp + data)
    return icmp_type + code + chksum + ident + seq + timestamp

def make_ip_header(ident, dst, payload):
    version_headerlen = [0x45]
    diff_services = [0x00]
    tot_len = len(payload) + ((version_headerlen[0] & 0xF) << 2)
    total_len = [(tot_len >> 8) & 0xFF, tot_len & 0xFF]
    flags = [0x40, 00]
    ttl = [64]
    prot = IP_PROT_ICMP
    header_chksum = checksum(version_headerlen + diff_services + total_len + ident + flags + ttl + prot + [0,0] + IP_BASE + dst)
    
    header = version_headerlen + diff_services + total_len + ident + flags + ttl + prot + header_chksum + IP_BASE + dst
    return header

# Function for making a reply package for an ping request
def reply_ping(dst_mac, dst_ip, icmp_ident, icmp_seq, ip_ident, timestamp, data):
    icmp = make_icmp_header(ICMP_PING_REPLY, ICMP_PING_REPLY, icmp_ident, icmp_seq, timestamp, data)
    ip = make_ip_header(ip_ident, dst_ip, icmp + data)
    eth = make_eth_header(dst_mac, ETH_TYPE_IP)
    return eth + ip + icmp + data


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
    hw_size = pkg[4:5]
    prot_size = pkg[5:6]
    opcode = pkg[6:8]
    sender_mac = pkg[8:14]
    sender_ip = pkg[14:18]
    target_mac = pkg[18:24]
    target_ip = pkg[24:28]

    return hw_type, protocol, hw_size, prot_size, opcode, sender_mac, sender_ip, target_mac, target_ip

def parse_icmp(pkg):
    icmp_type = pkg[0:1]
    code = pkg[1:2]
    chksum = pkg[2:4]
    ident = pkg[4:6] # Big endian
    seq = pkg[6:8] # Big endian
    timestamp = pkg[8:16]
    payload = pkg[16:]

    return icmp_type, code, chksum, ident, seq, timestamp, payload

# Function for decoding IP header
def parse_ip(pkg):
    version = [(pkg[0] & 0xF0) >> 4]
    header_len = [(pkg[0] & 0x0F)]
    dif_service = pkg[1:2]
    total_len = pkg[2:4]
    ident = pkg[4:6]
    flags = pkg[6:8]
    ttl = pkg[8:9]
    prot = pkg[9:10]
    header_chksum = pkg[10:12]
    src = pkg[12:16]
    dst = pkg[16:20]
    payload = pkg[20:]

    return version, header_len, dif_service, total_len, ident, flags, ttl, prot, header_chksum, src, dst, payload

def ping_arp_loop():
    while True:
        eth = read_packet()
        eth_bytes = pkg_to_bytes(eth)
        eth_dst, eth_src, eth_type, eth_payload = parse_eth(eth_bytes)
        if eth_dst == MAC_BROADCAST:
            if eth_type == ETH_TYPE_ARP: # ARP
                _, _, _, _, a_opcode, _, a_sender_ip, _, a_target_ip = parse_arp(eth_payload)
                if a_opcode == ARP_REQUEST and a_target_ip == IP_BASE:
                    arp_reply = reply_arp(eth_src, a_sender_ip)
                    send_packet(arp_reply)
        elif eth_dst == MAC_BASE:
            if eth_type == ETH_TYPE_IP:
                _, _, _, _, ip_ident, _, _, ip_prot, _, ip_src, ip_dst, ip_payload = parse_ip(eth_payload)
                if ip_dst == IP_BASE and ip_prot == IP_PROT_ICMP:
                    icmp_type, _, _, icmp_ident, seq, timestamp, icmp_payload = parse_icmp(ip_payload)
                    if icmp_type == ICMP_PING_REQUEST:
                        ping_reply = reply_ping(eth_src, ip_src, icmp_ident, seq, ip_ident, timestamp, icmp_payload)
                        send_packet(ping_reply)



