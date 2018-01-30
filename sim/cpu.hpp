//--------------------------------------------------------------------------------------------------
// Copyright (c) 2018 Marcus Geelnard
//
// This software is provided 'as-is', without any express or implied warranty. In no event will the
// authors be held liable for any damages arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose, including commercial
// applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not claim that you wrote
//     the original software. If you use this software in a product, an acknowledgment in the
//     product documentation would be appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be misrepresented as
//     being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//--------------------------------------------------------------------------------------------------

#ifndef SIM_CPU_HPP_
#define SIM_CPU_HPP_

#include "cache.hpp"
#include "ram.hpp"

#include <array>
#include <cstdint>

/// @brief A CPU core instance.
class cpu_t {
public:
  virtual ~cpu_t();

  /// @brief Reset the CPU state.
  void reset();

  /// @brief Start running code at a given memory address.
  /// @param addr Start of the program.
  /// @param sp Stack pointer.
  /// @returns The program return code (the argument to exit()).
  virtual uint32_t run(const uint32_t addr, const uint32_t sp) = 0;

  /// @brief Dump CPU stats from the last run.
  void dump_stats();

protected:
  // This constructor is called from derived classes.
  cpu_t(ram_t& ram);

  // Register configuration.
  static const uint32_t NUM_REGS = 32u;
  static const uint32_t NUM_VECTOR_ENTRIES = 32u;
  static const uint32_t NUM_VECTOR_REGS = 32u;

  // Named registers.
  static const uint32_t REG_Z = 0u;
  static const uint32_t REG_VC = 28u;
  static const uint32_t REG_LR = 29u;
  static const uint32_t REG_SP = 30u;
  static const uint32_t REG_PC = 31u;

  // ALU operations.
  static const uint32_t ALU_OP_NONE = 0x00u;
  static const uint32_t ALU_OP_OR = 0x01u;
  static const uint32_t ALU_OP_NOR = 0x02u;
  static const uint32_t ALU_OP_AND = 0x03u;
  static const uint32_t ALU_OP_XOR = 0x04u;
  static const uint32_t ALU_OP_ADD = 0x05u;
  static const uint32_t ALU_OP_SUB = 0x06u;
  static const uint32_t ALU_OP_SLT = 0x07u;
  static const uint32_t ALU_OP_SLTU = 0x08u;
  static const uint32_t ALU_OP_ASL = 0x09u;
  static const uint32_t ALU_OP_LSL = 0x0au;
  static const uint32_t ALU_OP_ASR = 0x0bu;
  static const uint32_t ALU_OP_LSR = 0x0cu;
  static const uint32_t ALU_OP_SHUF = 0x0du;
  static const uint32_t ALU_OP_CLZ = 0x50u;
  static const uint32_t ALU_OP_REV = 0x51u;
  static const uint32_t ALU_OP_EXTB = 0x52u;
  static const uint32_t ALU_OP_EXTH = 0x53u;
  static const uint32_t ALU_OP_LDHI = 0x10u;  // arg2 << 13
  static const uint32_t ALU_OP_LDHIO = 0x11u;  // (arg2 << 13) | 0x1fff

  // Mul/Div operations.
  static const uint32_t MD_OP_NONE = 0x00u;
  static const uint32_t MD_OP_MUL = 0x30u;
  static const uint32_t MD_OP_MULHI = 0x32u;
  static const uint32_t MD_OP_MULHIU = 0x33u;
  static const uint32_t MD_OP_DIV = 0x34u;
  static const uint32_t MD_OP_DIVU = 0x35u;
  static const uint32_t MD_OP_REM = 0x36u;
  static const uint32_t MD_OP_REMU = 0x37u;

  // FPU operations.
  static const uint32_t FPU_OP_NONE = 0x00u;
  static const uint32_t FPU_OP_ITOF = 0x38u;
  static const uint32_t FPU_OP_FTOI = 0x39u;
  static const uint32_t FPU_OP_ADD = 0x3au;
  static const uint32_t FPU_OP_SUB = 0x3bu;
  static const uint32_t FPU_OP_MUL = 0x3cu;
  static const uint32_t FPU_OP_DIV = 0x3du;

  // Memory operations.
  static const uint32_t MEM_OP_NONE = 0x00u;
  static const uint32_t MEM_OP_LOAD8 = 0x10u;
  static const uint32_t MEM_OP_LOADU8 = 0x11u;
  static const uint32_t MEM_OP_LOAD16 = 0x12u;
  static const uint32_t MEM_OP_LOADU16 = 0x13u;
  static const uint32_t MEM_OP_LOAD32 = 0x14u;
  static const uint32_t MEM_OP_STORE8 = 0x18u;
  static const uint32_t MEM_OP_STORE16 = 0x19u;
  static const uint32_t MEM_OP_STORE32 = 0x1au;

  // One vector register.
  using vreg_t = std::array<uint32_t, NUM_VECTOR_ENTRIES>;

  /// @brief Call a simulator routine.
  /// @param routine_no The routine to call (0, 1, ...).
  void call_sim_routine(const uint32_t routine_no);

  // Memory interface.
  ram_t& m_ram;
  cache_t<32, 256> m_icache;
  cache_t<32, 256> m_dcache;

  // Scalar registers.
  std::array<uint32_t, NUM_REGS> m_regs;

  // Vector registers.
  std::array<vreg_t, NUM_VECTOR_REGS> m_vregs;

  // Run state.
  bool m_terminate;
  uint32_t m_exit_code;

  // Run stats.
  uint32_t m_fetched_instr_count;
  uint32_t m_vector_loop_count;
  uint32_t m_total_cycle_count;
};

#endif  // SIM_CPU_HPP_
