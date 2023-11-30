// mycpu is freely redistributable under the MIT License. See the file
// "LICENSE" for information on usage and redistribution of this file.

package riscv.core

import chisel3._
import riscv.Parameters

object Registers extends Enumeration {
  type Register = Value
  val zero, ra, sp, gp, tp, t0, t1, t2, fp, s1, a0, a1, a2, a3, a4, a5, a6, a7, s2, s3, s4, s5, s6, s7, s8, s9, s10,
      s11, t3, t4, t5, t6 = Value
}

class RegisterFile extends Module {
  val io = IO(new Bundle {
    val write_enable  = Input(Bool())
    val write_address = Input(UInt(Parameters.PhysicalRegisterAddrWidth))
    val write_data    = Input(UInt(Parameters.DataWidth))

    val read_address1 = Input(UInt(Parameters.PhysicalRegisterAddrWidth))
    val read_address2 = Input(UInt(Parameters.PhysicalRegisterAddrWidth))
    val read_data1    = Output(UInt(Parameters.DataWidth))
    val read_data2    = Output(UInt(Parameters.DataWidth))

    val debug_read_address = Input(UInt(Parameters.PhysicalRegisterAddrWidth))
    val debug_read_data    = Output(UInt(Parameters.DataWidth))
    
    val ecall_a7      = Output(UInt(Parameters.DataWidth))
    val ecall_a0      = Output(UInt(Parameters.DataWidth))
    val ecall_a1      = Output(UInt(Parameters.DataWidth))
    val ecall_a2      = Output(UInt(Parameters.DataWidth))
    val ecall_a3      = Output(UInt(Parameters.DataWidth))
    val ecall_a4      = Output(UInt(Parameters.DataWidth))
    val ecall_a5      = Output(UInt(Parameters.DataWidth))
  })
  val registers = RegInit(VecInit(Seq.fill(Parameters.PhysicalRegisters)(0.U(Parameters.DataWidth))))

  when(!reset.asBool) {
    when(io.write_enable && io.write_address =/= 0.U) {
      registers(io.write_address) := io.write_data
    }
  }

  io.read_data1 := Mux(
    io.read_address1 === 0.U,
    0.U,
    registers(io.read_address1)
  )

  io.read_data2 := Mux(
    io.read_address2 === 0.U,
    0.U,
    registers(io.read_address2)
  )

  io.debug_read_data := Mux(
    io.debug_read_address === 0.U,
    0.U,
    registers(io.debug_read_address)
  )
  
  io.ecall_a7 := registers(17.U);
  io.ecall_a0 := registers(10.U);
  io.ecall_a1 := registers(11.U);
  io.ecall_a2 := registers(12.U);
  io.ecall_a3 := registers(13.U);
  io.ecall_a4 := registers(14.U);
  io.ecall_a5 := registers(15.U);
}
