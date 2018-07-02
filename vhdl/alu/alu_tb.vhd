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
use work.common.all;

--  A testbench has no ports.
entity alu_tb is
end alu_tb;

architecture behav of alu_tb is
  signal s_op : T_ALU_OP;
  signal s_src_a : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_src_b : std_logic_vector(C_WORD_SIZE-1 downto 0);
  signal s_result : std_logic_vector(C_WORD_SIZE-1 downto 0);
begin
  --  Component instantiation.
  alu_0: entity work.alu
    port map (
      i_op => s_op,
      i_src_a => s_src_a,
      i_src_b => s_src_b,
      o_result => s_result
    );

  process
    --  The patterns to apply.
    type pattern_type is record
      -- Inputs
      op : T_ALU_OP;
      src_a : std_logic_vector(C_WORD_SIZE-1 downto 0);
      src_b : std_logic_vector(C_WORD_SIZE-1 downto 0);

      -- Expected outputs
      result : std_logic_vector(C_WORD_SIZE-1 downto 0);
    end record;
    type pattern_array is array (natural range <>) of pattern_type;
    constant patterns : pattern_array := (
        (C_ALU_CPUID,
          "00000000000000000000000000000000",
          "00000000000000000000000000000000",
          to_word(C_VEC_REG_ELEMENTS)),
        (C_ALU_CPUID,
          "00000000000000000000000000000000",
          "01000000000000000000000000000000",
          "00000000000000000000000000000000"),

        (C_ALU_LDHI,
          "11111111111111010110010101111001",
          "00000000000000000000000000000000",
          "10101100101011110010000000000000"),
        (C_ALU_LDHI,
          "00000000000000110110010101111001",
          "00001000000000001000000001000100",
          "01101100101011110010000000000000"),

        (C_ALU_LDHIO,
          "11111111111111010110010101111000",
          "00000000000000000000000000000000",
          "10101100101011110001111111111111"),
        (C_ALU_LDHIO,
          "00000000000000110110010101111001",
          "00001000000000001000000001000100",
          "01101100101011110011111111111111"),

        (C_ALU_OR,
          "10101010101010101000000000000000",
          "01010101010111111000000000000000",
          "11111111111111111000000000000000"),

        (C_ALU_NOR,
          "10101010101010101000000000000000",
          "01010101010111111000000000000000",
          "00000000000000000111111111111111"),

        (C_ALU_AND,
          "10101010101010101000000000000000",
          "01010101010111111000000000000000",
          "00000000000010101000000000000000"),

        (C_ALU_BIC,
          "10101010101010101000000000000000",
          "01010101010111111000000000000000",
          "10101010101000000000000000000000"),

        (C_ALU_XOR,
          "10101010101010101000000000000000",
          "01010101010111111000000000000000",
          "11111111111101010000000000000000"),

        (C_ALU_ADD,
          "11111111111111111111111111111111",
          "00000000000000000000000000000010",
          "00000000000000000000000000000001"),
        (C_ALU_ADD,
          "00000000000000000000000000000010",
          "11111111111111111111111111111111",
          "00000000000000000000000000000001"),

        (C_ALU_SUB,
          "11111111111111111111111111111111",
          "00000000000000000000000000000010",
          "00000000000000000000000000000011"),
        (C_ALU_SUB,
          "00000000000000000000000000000010",
          "11111111111111111111111111111111",
          "11111111111111111111111111111101"),

        (C_ALU_SEQ,
          "00000000000000000000000000000010",
          "00000000000000000000000000000010",
          "11111111111111111111111111111111"),
        (C_ALU_SEQ,
          "00000000000000000000000000000100",
          "00000000000000000000000000000010",
          "00000000000000000000000000000000"),

        (C_ALU_SNE,
          "00000000000000000000000000000010",
          "00000000000000000000000000000010",
          "00000000000000000000000000000000"),
        (C_ALU_SNE,
          "00000000000000000000000000000100",
          "00000000000000000000000000000010",
          "11111111111111111111111111111111"),

        (C_ALU_SLT,
          "00000000000000000000000000000010",
          "00000000000000000000000000000000",
          "11111111111111111111111111111111"),
        (C_ALU_SLT,
          "00000000000000000000000000000000",
          "00000000000000000000000000000000",
          "00000000000000000000000000000000"),
        (C_ALU_SLT,
          "00000000000000000000000000000000",
          "11111111111111111111111111111111",
          "11111111111111111111111111111111"),

        (C_ALU_SLTU,
          "00000000000000000000000000000010",
          "00000000000000000000000000000000",
          "11111111111111111111111111111111"),
        (C_ALU_SLTU,
          "00000000000000000000000000000000",
          "00000000000000000000000000000000",
          "00000000000000000000000000000000"),
        (C_ALU_SLTU,
          "11111111111111111111111111111111",
          "00000000000000000000000000000000",
          "11111111111111111111111111111111"),

        (C_ALU_SLE,
          "00000000000000000000000000000010",
          "00000000000000000000000000000000",
          "11111111111111111111111111111111"),
        (C_ALU_SLE,
          "00000000000000000000000000000000",
          "00000000000000000000000000000000",
          "11111111111111111111111111111111"),
        (C_ALU_SLE,
          "00000000000000000000000000000000",
          "11111111111111111111111111111111",
          "11111111111111111111111111111111"),

        (C_ALU_SLEU,
          "00000000000000000000000000000010",
          "00000000000000000000000000000000",
          "11111111111111111111111111111111"),
        (C_ALU_SLEU,
          "00000000000000000000000000000000",
          "00000000000000000000000000000000",
          "11111111111111111111111111111111"),
        (C_ALU_SLEU,
          "11111111111111111111111111111111",
          "00000000000000000000000000000000",
          "11111111111111111111111111111111"),

        (C_ALU_MIN,
          "00000001001000110100010101100111",
          "11111111111111111110111011111011",
          "11111111111111111110111011111011"),
        (C_ALU_MIN,
          "11111111111111111110111011111011",
          "00000001001000110100010101100111",
          "11111111111111111110111011111011"),

        (C_ALU_MAX,
          "00000001001000110100010101100111",
          "11111111111111111110111011111011",
          "00000001001000110100010101100111"),
        (C_ALU_MAX,
          "11111111111111111110111011111011",
          "00000001001000110100010101100111",
          "00000001001000110100010101100111"),

        (C_ALU_MINU,
          "00000001001000110100010101100111",
          "11111111111111111110111011111011",
          "00000001001000110100010101100111"),
        (C_ALU_MINU,
          "11111111111111111110111011111011",
          "00000001001000110100010101100111",
          "00000001001000110100010101100111"),

        (C_ALU_MAXU,
          "00000001001000110100010101100111",
          "11111111111111111110111011111011",
          "11111111111111111110111011111011"),
        (C_ALU_MAXU,
          "11111111111111111110111011111011",
          "00000001001000110100010101100111",
          "11111111111111111110111011111011"),

        (C_ALU_LSR,
          "11111111100000000000001000010101",
          "00000000000001000000000000001000",
          "00000000111111111000000000000010"),
        (C_ALU_ASR,
          "11111111100000000000001000010101",
          "00000000000001000000000000001000",
          "11111111111111111000000000000010"),
        (C_ALU_LSL,
          "11111111100000000000001000010101",
          "00000000000001000000000000001000",
          "10000000000000100001010100000000"),

        (C_ALU_SHUF,
          "11111111000011110011001101010101",
          "00000000000000000000000001010011",
          "01010101001100110000111111111111"),
        (C_ALU_SHUF,
          "11111111000011110011001101010101",
          "00000100000000000001100101110111",
          "00000000000000000000000011111111"),

        (C_ALU_CLZ,
          "00000001001000110100010101100111",
          "01010101101010101010101001010101",
          "00000000000000000000000000000111"),

        (C_ALU_REV,
          "00000001001000110100010101100111",
          "01010101101010101010101001010101",
          "11100110101000101100010010000000"),

        (C_ALU_PACKB,
          X"12345678",
          X"FFEEDDCC",
          X"3478EECC"),

        (C_ALU_PACKH,
          X"12345678",
          X"FFEEDDCC",
          X"5678DDCC")

      );
  begin
    -- Test all the patterns in the pattern array.
    for i in patterns'range loop
      --  Set the inputs.
      s_op <= patterns(i).op;
      s_src_a <= patterns(i).src_a;
      s_src_b <= patterns(i).src_b;

      --  Wait for the results.
      wait for 1 ns;

      --  Check the outputs.
      assert s_result = patterns(i).result
        report "Bad ALU result:" & lf &
               "  op=" & to_string(s_op) & lf &
               "  a=" & to_string(s_src_a) & lf &
               "  b=" & to_string(s_src_b) & lf &
               "  r=" & to_string(s_result) & lf &
               " (e=" & to_string(patterns(i).result) & ")"
            severity error;
    end loop;
    assert false report "End of test" severity note;
    --  Wait forever; this will finish the simulation.
    wait;
  end process;
end behav;
