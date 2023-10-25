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
  echo "  Ox: run with Ox optimization in c form"
  echo "  asm: run with O0 optimization in asm form"
  echo "  asmO2: run with O2 optimization in asm form"
}


optims=( "-O0" "-O1" "-O2" "-O3" "-Os" "-Ofast" )
if [ $# -eq 0 ]
then
  make
  runprogram $? "-O0"
elif [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
  showhelp
elif [ "$1" = "all" ]
then
  for i in "${optims[@]}"
  do
    make OLVL=$i
    runprogram $? $i
  done
  sed -i "s/HammingDistance_c/HammingDistance_s/g" main.c
  make OLVL=-O0
  runprogram $? "-asm-O0"
  make OLVL=-O2
  runprogram $? "-asm-O2"
  sed -i "s/HammingDistance_s/HammingDistance_c/g" main.c
elif [ "$1" = "asm" ]
then
  sed -i "s/HammingDistance_c/HammingDistance_s/g" main.c
  make OLVL=-O0
  runprogram $? "-asm-O0"
  sed -i "s/HammingDistance_s/HammingDistance_c/g" main.c
elif [ "$1" = "asmO2" ]
then
  sed -i "s/HammingDistance_c/HammingDistance_s/g" main.c
  make OLVL=-O2
  runprogram $? "-asm-O2"
  sed -i "s/HammingDistance_s/HammingDistance_c/g" main.c
else
  make OLVL="-${1}"
  runprogram $? "-${1}"
fi
echo "finished"
