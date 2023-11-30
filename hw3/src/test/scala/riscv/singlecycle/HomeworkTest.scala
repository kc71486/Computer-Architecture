package riscv.singlecycle

import java.nio.ByteBuffer
import java.nio.ByteOrder

import chisel3._
import chiseltest._
import org.scalatest.flatspec.AnyFlatSpec
import riscv.core.CPU
import riscv.core.ProgramCounter
import riscv.Parameters
import riscv.TestAnnotations

class HomeWorkTest extends AnyFlatSpec with ChiselScalatestTester {
  behavior.of("Single Cycle CPU")
  it should "execute hamming code calculation in assembly" in {
    test(new TestTopModule("homework.asmbin")).withAnnotations(TestAnnotations.annos) { c =>
      for (i <- 1 to 50000) {
        c.clock.step()
        c.io.mem_debug_read_address.poke((i * 4).U) // Avoid timeout
      }
      c.io.mem_debug_read_address.poke(4.U) // #1
      c.clock.step()
      c.io.mem_debug_read_data.expect(24.U)
      c.io.mem_debug_read_address.poke(8.U) // #2
      c.clock.step()
      c.io.mem_debug_read_data.expect(60.U)
      c.io.mem_debug_read_address.poke(12.U) // #3
      c.clock.step()
      c.io.mem_debug_read_data.expect(0.U)
    }
  }
}

class HomeWorkCTest extends AnyFlatSpec with ChiselScalatestTester {
  behavior.of("Single Cycle CPU")
  it should "execute hamming code calculation in c" in {
    test(new TestTopModule("homeworkc.asmbin")).withAnnotations(TestAnnotations.annos) { c =>
      for (i <- 1 to 50000) {
        c.clock.step()
        c.io.mem_debug_read_address.poke((i * 4).U) // Avoid timeout
      }
      c.io.mem_debug_read_address.poke(4.U) // #1
      c.clock.step()
      c.io.mem_debug_read_data.expect(24.U)
      c.io.mem_debug_read_address.poke(8.U) // #2
      c.clock.step()
      c.io.mem_debug_read_data.expect(60.U)
      c.io.mem_debug_read_address.poke(12.U) // #3
      c.clock.step()
      c.io.mem_debug_read_data.expect(0.U)
    }
  }
}
