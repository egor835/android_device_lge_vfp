#!/usr/bin/env python3
"""Parse a 3.4+ structured printk ring buffer dump (struct log records) into text."""
import struct, sys
b = open(sys.argv[1], 'rb').read()
i = 0
recs = []
while i + 16 <= len(b):
    ts, ln, tl, dl, fl = struct.unpack_from('<QHHHB', b, i)
    if ln == 0:
        i = (i + 4) & ~3 if i % 4 else i + 4; continue
    if ln < 16 or i + ln > len(b) or tl > ln:
        i += 4; continue
    txt = b[i + 16:i + 16 + tl].decode('utf-8', 'replace')
    recs.append((ts, txt)); i += ln
recs.sort()
for ts, t in recs:
    print(f'[{ts/1e9:12.6f}] {t}')
