// mycpu is freely redistributable under the MIT License. See the file
// "LICENSE" for information on usage and redistribution of this file.

package riscv

import chisel3._
import peripheral.RAMBundle

// CPUBundle serves as the communication interface for data exchange between
// the CPU and peripheral devices, such as memory.
class CPUBundle extends Bundle {
  val instruction_address = Output(UInt(Parameters.AddrWidth))
  val instruction         = Input(UInt(Parameters.DataWidth))
  val memory_bundle       = Flipped(new RAMBundle)
  val vram_bundle         = Flipped(new RAMBundle)
  val kernel_bundle       = Flipped(new RAMBundle)
  val instruction_valid   = Input(Bool())
  val deviceSelect        = Output(UInt(Parameters.SlaveDeviceCountBits.W))
  val debug_read_address  = Input(UInt(Parameters.PhysicalRegisterAddrWidth))
  val debug_read_data     = Output(UInt(Parameters.DataWidth))
  
  val ecall_en            = Output(Bool())
  val ecall_a7            = Output(UInt(Parameters.DataWidth))
  val ecall_a0            = Output(UInt(Parameters.DataWidth))
  val ecall_a1            = Output(UInt(Parameters.DataWidth))
  val ecall_a2            = Output(UInt(Parameters.DataWidth))
  val ecall_a3            = Output(UInt(Parameters.DataWidth))
  val ecall_a4            = Output(UInt(Parameters.DataWidth))
  val ecall_a5            = Output(UInt(Parameters.DataWidth))
}
