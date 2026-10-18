#!/bin/bash
# Pull kernel printk buffer from a crashed phone in Sahara memory-debug mode
OUT=${1:-dmesg_last.txt}
SM=${SYSTEM_MAP:-out/target/product/vfp/obj/KERNEL_OBJ/System.map}
A=$(grep ' __log_buf$' $SM | cut -d' ' -f1)
P=$(printf '0x%x' $((0x$A - 0xc0000000)))
python3 -I $(dirname "$0")/sahara_memdump.py read $P 0x20000 ${OUT%.txt}.bin >/dev/null && python3 $(dirname "$0")/parse_logbuf.py ${OUT%.txt}.bin > $OUT && echo "$OUT: $(wc -l < $OUT) lines"
