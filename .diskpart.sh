#!/bin/sh

# Example:
#   cat <<EOF | ./.diskpart.sh
#   select vdisk file="some-v-file.vhdx"
#   attach vdisk
#   EOF

diskpart |                          # Windows's DiskPart.exe
    tail -n +8 |                    # Remove diskpart's banner (the first 7 lines).
    egrep -v '(^DISKPART>|^\s*$)'   # Remove lines starting with `DISKPART>` or blank lines.
