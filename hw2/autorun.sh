#!/bin/bash
make
if [ $? -ne 0 ]
then
  exit
fi
echo "program size:"
riscv-none-elf-size hammingdistance.elf
echo "execution result:"
rv32emu hammingdistance.elf