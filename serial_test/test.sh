#!/usr/bin/env bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 <device name>"
    exit
fi

# 31250 baud (for MIDI)
# no parity bit, one stop bit
gcc set_baud.c -o set_baud
./set_baud /dev/ttyUSB1 31250
#stty -a -F /dev/ttyUSB1
printf "%b" '\x90\x69\x50' > $1
sleep 2
printf "%b" '\x89\x69\x50' > $1
