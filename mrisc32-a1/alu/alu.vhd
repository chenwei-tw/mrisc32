----------------------------------------------------------------------------------------------------
-- Copyright (c) 2018 Marcus Geelnard
--
-- This software is provided 'as-is', without any express or implied warranty. In no event will the
-- authors be held liable for any damages arising from the use of this software.
--
-- Permission is granted to anyone to use this software for any purpose, including commercial
-- applications, and to alter it and redistribute it freely, subject to the following restrictions:
--
--  1. The origin of this software must not be misrepresented; you must not claim that you wrote
--     the original software. If you use this software in a product, an acknowledgment in the
--     product documentation would be appreciated but is not required.
--
--  2. Altered source versions must be plainly marked as such, and must not be misrepresented as
--     being the original software.
--
--  3. This notice may not be removed or altered from any source distribution.
----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;

entity alu is
  port(
      i_op : in T_ALU_OP;                                      -- Operation
      i_src_a : in std_logic_vector(C_WORD_SIZE-1 downto 0);   -- Source operand A
      i_src_b : in std_logic_vector(C_WORD_SIZE-1 downto 0);   -- Source operand B
      o_result : out std_logic_vector(C_WORD_SIZE-1 downto 0)  -- ALU result
    );
end;

architecture rtl of alu is
  -- Intermediate (concurrent) operation results.
  signal s_cpuid_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_or_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_nor_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_and_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_bic_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_xor_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_set_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_min_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_max_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_minu_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_maxu_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_shuf_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_rev_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_pack_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_ldhi_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_clz_res : std_logic_vector(C_WORD_SIZE-1 downto 0);

  -- Signals for the adder.
  signal s_add_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_sub_res : std_logic_vector(C_WORD_SIZE-1 downto 0);

  -- Signals for the comparator.
  signal s_compare_eq : std_logic;
  signal s_compare_ne : std_logic;
  signal s_compare_lt : std_logic;
  signal s_compare_le : std_logic;
  signal s_compare_ltu : std_logic;
  signal s_compare_leu : std_logic;
  signal s_set_bit : std_logic;

  -- Signals for packb/packh.
  signal s_packb_res : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_packh_res : std_logic_vector(C_WORD_SIZE-1 downto 0);

  -- Signals for the shifter.
  signal s_shift_is_right : std_logic;
  signal s_shift_is_arithmetic : std_logic;
  signal s_shifter_res : std_logic_vector(C_WORD_SIZE-1 downto 0);

begin
  ------------------------------------------------------------------------------------------------
  -- CPUID
  ------------------------------------------------------------------------------------------------

  process(i_src_a, i_src_b)
  begin
    if (i_src_a = to_word(0)) and (i_src_b = to_word(0)) then
      -- 00000000:00000000 => Max vector length
      s_cpuid_res <= to_word(C_VEC_REG_ELEMENTS);
    elsif (i_src_a = to_word(0)) and (i_src_b = to_word(1)) then
      -- 00000000:00000001 => log2(Max vector length)
      s_cpuid_res <= to_word(C_LOG2_VEC_REG_ELEMENTS);
    elsif (i_src_a = to_word(1)) and (i_src_b = to_word(0)) then
      -- 00000001:00000000 => CPU features
      s_cpuid_res(0) <= to_std_logic(C_CPU_HAS_VEC);
      s_cpuid_res(1) <= to_std_logic(C_CPU_HAS_PO);
      s_cpuid_res(2) <= to_std_logic(C_CPU_HAS_MUL);
      s_cpuid_res(3) <= to_std_logic(C_CPU_HAS_DIV);
      s_cpuid_res(4) <= to_std_logic(C_CPU_HAS_FP);
      s_cpuid_res(C_WORD_SIZE-1 downto 5) <= (others => '0');
    else
      -- All unsupported commands return zero.
      s_cpuid_res <= (others => '0');
    end if;
  end process;


  ------------------------------------------------------------------------------------------------
  -- Bitwise operations
  ------------------------------------------------------------------------------------------------

  -- C_ALU_OR
  s_or_res <= i_src_a or i_src_b;

  -- C_ALU_NOR
  s_nor_res <= not s_or_res;

  -- C_ALU_AND
  s_and_res <= i_src_a and i_src_b;

  -- C_ALU_BIC
  s_bic_res <= i_src_a and (not i_src_b);

  -- C_ALU_XOR
  s_xor_res <= i_src_a xor i_src_b;


  ------------------------------------------------------------------------------------------------
  -- Bit, byte and word shuffling
  ------------------------------------------------------------------------------------------------

  -- C_ALU_SHUF
  AluSHUF32: entity work.shuf32
    port map (
      i_src_a => i_src_a,
      i_src_b => i_src_b,
      o_result => s_shuf_res
    );

  -- C_ALU_REV
  RevGen: for k in 0 to C_WORD_SIZE-1 generate
    s_rev_res(k) <= i_src_a(C_WORD_SIZE-1-k);
  end generate;

  -- C_ALU_PACKB, C_ALU_PACKH
  s_packb_res <= i_src_a(23 downto 16) & i_src_a(7 downto 0) & i_src_b(23 downto 16) & i_src_b(7 downto 0);
  s_packh_res <= i_src_a(15 downto 0) & i_src_b(15 downto 0);
  s_pack_res <= s_packb_res when i_op(0) = '1' else s_packh_res;

  -- C_ALU_LDHI, C_ALU_LDHIO
  s_ldhi_res(C_WORD_SIZE-1 downto C_WORD_SIZE-19) <= i_src_a(18 downto 0);
  s_ldhi_res(C_WORD_SIZE-20 downto 0) <= (others => i_op(1));  -- C_ALU_LDHI="000001", C_ALU_LDHIO="000010"

  -- C_ALU_CLZ
  AluCLZ32: entity work.clz32
    port map (
      i_src => i_src_a,
      o_cnt => s_clz_res(5 downto 0)
    );
  s_clz_res(31 downto 6) <= (others => '0');


  ------------------------------------------------------------------------------------------------
  -- Arithmetic operations
  ------------------------------------------------------------------------------------------------

  -- Add/sub.
  s_add_res <= std_logic_vector(unsigned(i_src_b) + unsigned(i_src_a));
  s_sub_res <= std_logic_vector(unsigned(i_src_b) - unsigned(i_src_a));

  -- Camparison results.
  s_compare_eq <= '1' when i_src_a = i_src_b else '0';
  s_compare_ne <= not s_compare_eq;
  s_compare_lt <= '1' when signed(i_src_b) < signed(i_src_a) else '0';
  s_compare_le <= s_compare_eq or s_compare_lt;
  s_compare_ltu <= '1' when unsigned(i_src_b) < unsigned(i_src_a) else '0';
  s_compare_leu <= s_compare_eq or s_compare_ltu;

  -- Min/Max operations.
  s_min_res <= i_src_a when s_compare_lt = '0' else i_src_b;
  s_max_res <= i_src_a when s_compare_lt = '1' else i_src_b;
  s_minu_res <= i_src_a when s_compare_ltu = '0' else i_src_b;
  s_maxu_res <= i_src_a when s_compare_ltu = '1' else i_src_b;

  -- Compare and set operations.
  CmpMux: with i_op select
    s_set_bit <=
      s_compare_eq when C_ALU_SEQ,
      s_compare_ne when C_ALU_SNE,
      s_compare_lt when C_ALU_SLT,
      s_compare_ltu when C_ALU_SLTU,
      s_compare_le when C_ALU_SLE,
      s_compare_leu when C_ALU_SLEU,
      '-' when others;
  s_set_res <= (others => s_set_bit);


  ------------------------------------------------------------------------------------------------
  -- Shift operations
  ------------------------------------------------------------------------------------------------

  s_shift_is_right <= i_op(0);           -- '1' for C_ALU_LSR and C_ALU_ASR, '0' for C_ALU_LSL
  s_shift_is_arithmetic <= not i_op(1);  -- '1' for C_ALU_ASR, '0' for C_ALU_LSR and C_ALU_LSL

  AluShifter: entity work.shift32
    port map (
      i_right => s_shift_is_right,
      i_arithmetic => s_shift_is_arithmetic,
      i_src => i_src_a,
      i_shift => i_src_b(4 downto 0),
      o_result => s_shifter_res
    );


  ------------------------------------------------------------------------------------------------
  -- Select the output.
  ------------------------------------------------------------------------------------------------

  AluMux: with i_op select
    o_result <=
        s_cpuid_res when C_ALU_CPUID,
        s_or_res when C_ALU_OR,
        s_nor_res when C_ALU_NOR,
        s_and_res when C_ALU_AND,
        s_bic_res when C_ALU_BIC,
        s_xor_res when C_ALU_XOR,
        s_add_res when C_ALU_ADD,
        s_sub_res when C_ALU_SUB,
        s_set_res when C_ALU_SEQ | C_ALU_SNE | C_ALU_SLT | C_ALU_SLTU | C_ALU_SLE | C_ALU_SLEU,
        s_min_res when C_ALU_MIN,
        s_max_res when C_ALU_MAX,
        s_minu_res when C_ALU_MINU,
        s_maxu_res when C_ALU_MAXU,
        s_shifter_res when C_ALU_LSR | C_ALU_ASR | C_ALU_LSL,
        s_shuf_res when C_ALU_SHUF,
        s_clz_res when C_ALU_CLZ,
        s_rev_res when C_ALU_REV,
        s_pack_res when C_ALU_PACKB | C_ALU_PACKH,
        s_ldhi_res when C_ALU_LDHI | C_ALU_LDHIO,
        (others => '-') when others;

end rtl;

