#!/bin/bash

function runprogram() {
  if [ $1 -ne 0 ]
  then
    echo "make error, exit"
    exit
  fi
  echo "program size:" > "out${2}"
  riscv-none-elf-size hammingdistance.elf >> "out${2}"
  echo "execution result:" >> "out${2}"
  rv32emu hammingdistance.elf >> "out${2}"
  riscv-none-elf-objdump -d hammingdistance.elf >> "dump${2}"
  make clean
}

optims=( "-O0" "-O1" "-O2" "-O3" "-Os" "-Ofast" )
if [ $# -eq 0 ]
then
  make
  runprogram $? "-O0"
elif [ "$1" = "all" ]
then
  for i in "${optims[@]}"
  do
    make OLVL=$i
    runprogram $? $i
  done
elif [ "$1" = "asm" ]
then
  make OLVL=-O2
  runprogram $? "-asm"
else
  make OLVL=$1
  runprogram $? $1
fi
echo "finished"
