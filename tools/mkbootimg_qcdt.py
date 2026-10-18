#!/usr/bin/env python3
"""Minimal CAF-style mkbootimg (header v0 with QCDT dt_size field)."""
import argparse, hashlib, struct
p = argparse.ArgumentParser()
p.add_argument('--kernel', required=True); p.add_argument('--ramdisk', required=True)
p.add_argument('--dt'); p.add_argument('--cmdline', default='')
p.add_argument('--base', type=lambda x: int(x, 0), default=0)
p.add_argument('--kernel_offset', type=lambda x: int(x, 0), default=0x8000)
p.add_argument('--ramdisk_offset', type=lambda x: int(x, 0), default=0x1000000)
p.add_argument('--tags_offset', type=lambda x: int(x, 0), default=0x100)
p.add_argument('--second_offset', type=lambda x: int(x, 0), default=0xf00000)
p.add_argument('--pagesize', type=int, default=2048); p.add_argument('-o', required=True)
a = p.parse_args()
k, r = open(a.kernel, 'rb').read(), open(a.ramdisk, 'rb').read()
d = open(a.dt, 'rb').read() if a.dt else b''
sha = hashlib.sha1()
for blob in (k, r, b''):
    sha.update(blob); sha.update(struct.pack('<I', len(blob)))
if d:
    sha.update(d); sha.update(struct.pack('<I', len(d)))
cmd = a.cmdline.encode()
assert len(cmd) < 512
hdr = struct.pack('<8s10I16s512s32s', b'ANDROID!', len(k), a.base + a.kernel_offset, len(r),
                  a.base + a.ramdisk_offset, 0, a.base + a.second_offset, a.base + a.tags_offset,
                  a.pagesize, len(d), 0, b'', cmd, sha.digest())
pad = lambda b: b + b'\0' * ((-len(b)) % a.pagesize)
open(a.o, 'wb').write(pad(hdr) + pad(k) + pad(r) + (pad(d) if d else b''))
