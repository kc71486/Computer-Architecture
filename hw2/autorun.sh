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

function showhelp() {
  echo "extra options:"
  echo "  help: show help"
  echo "  all: run all"
  echo "  Ox: run with Ox optimizationin c form"
  echo "  asm: run with O0 optimizationin asm form"
  echo "  asmO2: run with O2 optimizationin asm form"
}


optims=( "-O0" "-O1" "-O2" "-O3" "-Os" "-Ofast" )
if [ $# -eq 0 ]
then
  make
  runprogram $? "-O0"
elif [ "$1" = "help" ]
then
  showhelp
elif [ "$1" = "-h" ]
then
  showhelp
elif [ "$1" = "--help" ]
then
  showhelp
elif [ "$1" = "all" ]
then
  for i in "${optims[@]}"
  do
    make OLVL=$i
    runprogram $? $i
  done
elif [ "$1" = "asm" ]
then
  make OLVL=-O0
  runprogram $? "-asm-O0"
elif [ "$1" = "asmO2" ]
then
  make OLVL=-O0
  runprogram $? "-asm-O2"
else
  make OLVL="-${1}"
  runprogram $? "-${1}"
fi
echo "finished"
