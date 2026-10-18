#!/usr/bin/env python3
"""Build a QCDT v2 dt.img: mkqcdt.py out.img in.dtb [in2.dtb...]
Reads qcom,msm-id (pairs) and qcom,board-id from each dtb via fdtget."""
import struct, subprocess, sys
PAGE = 2048
out, dtbs = sys.argv[1], sys.argv[2:]
entries, blobs = [], []
for d in dtbs:
    get = lambda prop: [int(x, 0) for x in subprocess.check_output(['fdtget', '-t', 'x', d, '/', prop]).split()]
    get = (lambda d: lambda prop: [int(x, 16) for x in subprocess.check_output(['fdtget', '-t', 'x', d, '/', prop]).split()])(d)
    msm, board = get('qcom,msm-id'), get('qcom,board-id')
    blob = open(d, 'rb').read()
    for i in range(0, len(msm), 2):
        entries.append((msm[i], board[0], board[1], msm[i + 1], len(blobs)))
    blobs.append(blob)
hdr = 12 + 24 * len(entries) + 4
off = (hdr + PAGE - 1) // PAGE * PAGE
offs = []
for b in blobs:
    offs.append(off); off += (len(b) + PAGE - 1) // PAGE * PAGE
img = bytearray(struct.pack('<4sII', b'QCDT', 2, len(entries)))
for plat, var, sub, rev, bi in entries:
    sz = (len(blobs[bi]) + PAGE - 1) // PAGE * PAGE
    img += struct.pack('<6I', plat, var, sub, rev, offs[bi], sz)
img += b'\0' * 4
for o, b in zip(offs, blobs):
    img += b'\0' * (o - len(img)) + b
img += b'\0' * ((-len(img)) % PAGE)
open(out, 'wb').write(img)
print(f'{out}: {len(entries)} entries, {len(img)} bytes')
