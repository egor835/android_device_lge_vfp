#!/usr/bin/env python3
"""Minimal Sahara memory-debug client (32-bit CMD9/CMD10) for msm8x26 crash mode.

usage: sahara_memdump.py table                 - print the debug region table
       sahara_memdump.py read ADDR LEN OUT     - dump physical memory range to OUT
"""
import struct, sys
import usb.core, usb.util

IDS = [(0x1004, 0x61a1), (0x05c6, 0x9006), (0x05c6, 0x9008)]


def open_dev():
    for vid, pid in IDS:
        d = usb.core.find(idVendor=vid, idProduct=pid)
        if d:
            break
    else:
        sys.exit('no sahara device')
    try:
        if d.is_kernel_driver_active(0):
            d.detach_kernel_driver(0)
    except Exception:
        pass
    intf = d.get_active_configuration()[(0, 0)]
    ep_in = usb.util.find_descriptor(intf, custom_match=lambda e: usb.util.endpoint_direction(e.bEndpointAddress) == usb.util.ENDPOINT_IN)
    ep_out = usb.util.find_descriptor(intf, custom_match=lambda e: usb.util.endpoint_direction(e.bEndpointAddress) == usb.util.ENDPOINT_OUT)
    return d, ep_in, ep_out


def handshake(ep_in, ep_out):
    """Answer HELLO if the device sends one; return (table_addr, table_len) if CMD9 seen."""
    table = None
    for _ in range(4):
        try:
            pkt = bytes(ep_in.read(4096, timeout=1500))
        except usb.core.USBTimeoutError:
            break
        if len(pkt) < 8:
            continue
        cmd, ln = struct.unpack_from('<II', pkt)
        if cmd == 1:  # HELLO
            mode = struct.unpack_from('<I', pkt, 0x14)[0]
            resp = struct.pack('<IIIIII', 2, 0x30, 2, 1, 0, mode) + b'\0' * 24
            ep_out.write(resp)
        elif cmd == 9:
            table = struct.unpack_from('<II', pkt, 8)
            break
    return table


def mem_read(ep_in, ep_out, addr, length):
    out = bytearray()
    while length:
        n = min(length, 0x1000)
        ep_out.write(struct.pack('<IIII', 0xa, 0x10, addr, n))
        got = bytearray()
        while len(got) < n:
            got += ep_in.read(max(n - len(got), 512), timeout=5000)
        out += got[:n]
        try:  # swallow a trailing zero-length packet, if any
            ep_in.read(512, timeout=50)
        except usb.core.USBTimeoutError:
            pass
        addr += n
        length -= n
    return bytes(out)


def main():
    d, ep_in, ep_out = open_dev()
    table = handshake(ep_in, ep_out)
    if sys.argv[1] == 'table':
        if not table:
            sys.exit('no CMD9 received (device already past hello?) - pass table addr manually')
        addr, ln = table
        raw = mem_read(ep_in, ep_out, addr, ln)
        for i in range(0, ln, 52):
            pref, base, size, desc, fn = struct.unpack_from('<III20s20s', raw, i)
            print(f'{base:#010x} {size:#010x} {desc.split(b"\0")[0].decode()} {fn.split(b"\0")[0].decode()}')
    elif sys.argv[1] == 'read':
        addr, ln, outp = int(sys.argv[2], 0), int(sys.argv[3], 0), sys.argv[4]
        open(outp, 'wb').write(mem_read(ep_in, ep_out, addr, ln))
        print(f'wrote {ln:#x} bytes from {addr:#x} to {outp}')


if __name__ == '__main__':
    main()
