#!/bin/bash

function runprogram() {
  if [ $1 -ne 0 ]
  then
    echo "make error, exit"
    return
  fi
  echo "output into out${2} ..."
  echo "program size:" > "out${2}"
  riscv-none-elf-size hammingdistance.elf >> "out${2}"
  echo "execution result:" >> "out${2}"
  rv32emu hammingdistance.elf >> "out${2}"
  echo "dump into dump${2} ..."
  riscv-none-elf-objdump -d hammingdistance.elf > "dump${2}"
}

function showhelp() {
  echo "uses as and ld and main.s"
  echo "options:"
  echo "  help: show help"
  echo "  clean clear all out and dump file"
  echo "  all: run all"
  echo "  Ox: run with Ox optimization in c form (x=optimizion level)"
  echo "  asm: run with O0 optimization in asm form"
  echo "  asm Ox: run with Ox optimization in asm form  (x=optimizion level)"
}

optims=( "-O0" "-O1" "-O2" "-O3" "-Os" "-Ofast" )
if [ $# -eq 0 ] || [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]
then
  showhelp
elif [ $1 == "clean" ]
then
  for i in "${optims[@]}"
  do
    if [ -f "out${i}" ] || [ -f "dump${i}" ]
    then
      echo "removing out${i} and dump${i} ..."
      rm "out${i}" "dump${i}"
    fi
    if [ -f "out-asm${i}" ] || [ -f "dump-asm${i}" ]
    then
      echo "removing out-asm${i} and dump-asm${i} ..."
      rm "out-asm${i}" "dump-asm${i}"
    fi
  done
elif [ $1 = "all" ]
then
  mv main.c mainc.c
  mv mains.s main.s
  for i in "${optims[@]}"
  do
    make ASTOOL=as LDTOOL=ld ASFLAGS= LDFLAGS="-T link.ld" OLVL=$i
    runprogram $? $i
    make clean
  done
  sed -i "s/HammingDistance_c/HammingDistance_s/g" mainc.c
  for i in "${optims[@]}"
  do
    make ASTOOL=as LDTOOL=ld ASFLAGS="" LDFLAGS="-T link.ld" OLVL=$i
    runprogram $? "-asm${i}"
    make clean
  done
  sed -i "s/HammingDistance_s/HammingDistance_c/g" mainc.c
  mv main.s mains.s
  mv mainc.c main.c
elif [ $1 == "asm" ]
then
  mv main.c mainc.c
  mv mains.s main.s
  sed -i "s/HammingDistance_c/HammingDistance_s/g" mainc.c
  if [ $# -eq 1 ]
  then
    make ASTOOL=as LDTOOL=ld ASFLAGS= LDFLAGS="-T link.ld" OLVL=-O0
    runprogram $? "-asm-O0"
    make clean
  else
    make ASTOOL=as LDTOOL=ld ASFLAGS= LDFLAGS="-T link.ld" OLVL="-${1}"
    runprogram $? "-asm-${1}"
    make clean
  fi
  sed -i "s/HammingDistance_s/HammingDistance_c/g" mainc.c
  mv main.s mains.s
  mv mainc.c main.c
elif [[ $1 == O* ]]
then
  mv main.c mainc.c
  mv mains.s main.s
  make ASTOOL=as LDTOOL=ld ASFLAGS= LDFLAGS="-T link.ld" OLVL=-O0
  runprogram $? "-O0"
  make clean
  mv main.s mains.s
  mv mainc.c main.c
else
  echo "unknown option"
  exit
fi
echo "finished"
