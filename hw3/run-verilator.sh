#!/bin/bash

arguments="-memory 0x8000 -instruction src/main/resources/homework.asmbin -time 50000 -signature 0x00000000 0x00000300 mem.txt -halt 0xfffc -vcd dump.vcd"

if [ $# -eq 1 ]; then
    if [ $1 == "hello" ]; then
        arguments="-memory 0x8000 -instruction src/main/resources/hello.asmbin -time 100000 -signature 0x20000000 0x20000300 mem.txt -halt 0xfffc -vcd dump.vcd"
    elif [ $1 == "homework" ]; then
        arguments="-memory 0x8000 -instruction src/main/resources/homework.asmbin -time 50000 -signature 0x20000000 0x20000300 mem.txt -halt 0xfffc -vcd dump.vcd"
    fi
fi

if [ ! -f verilog/verilator/obj_dir/VTop ]; then
    echo "Failed to generate Verilog"
    exit 1
fi

verilog/verilator/obj_dir/VTop $arguments
