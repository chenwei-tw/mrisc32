library ieee;
use ieee.std_logic_1164.all;

entity alu is
  port (i_op : in std_logic_vector(8 downto 0);        -- Operation
        i_src_a : in std_logic_vector(31 downto 0);    -- Source operand A
        i_src_b : in std_logic_vector(31 downto 0);    -- Source operand B
        i_src_c : in std_logic_vector(31 downto 0);    -- Source operand C
        o_result : out std_logic_vector(31 downto 0)   -- ALU result
    );
end;
 
architecture rtl of alu is
  -- Supported ALU operations.
  constant OP_CPUID  : std_logic_vector(8 downto 0) := "000000000";

  constant OP_LDHI   : std_logic_vector(8 downto 0) := "000000001";
  constant OP_LDHIO  : std_logic_vector(8 downto 0) := "000000010";

  constant OP_OR     : std_logic_vector(8 downto 0) := "000010000";
  constant OP_NOR    : std_logic_vector(8 downto 0) := "000010001";
  constant OP_AND    : std_logic_vector(8 downto 0) := "000010010";
  constant OP_BIC    : std_logic_vector(8 downto 0) := "000010011";
  constant OP_XOR    : std_logic_vector(8 downto 0) := "000010100";
  constant OP_ADD    : std_logic_vector(8 downto 0) := "000010101";
  constant OP_SUB    : std_logic_vector(8 downto 0) := "000010110";
  constant OP_SLT    : std_logic_vector(8 downto 0) := "000010111";
  constant OP_SLTU   : std_logic_vector(8 downto 0) := "000011000";
  constant OP_CEQ    : std_logic_vector(8 downto 0) := "000011001";
  constant OP_CLT    : std_logic_vector(8 downto 0) := "000011010";
  constant OP_CLTU   : std_logic_vector(8 downto 0) := "000011011";
  constant OP_CLE    : std_logic_vector(8 downto 0) := "000011100";
  constant OP_CLEU   : std_logic_vector(8 downto 0) := "000011101";
  constant OP_LSR    : std_logic_vector(8 downto 0) := "000011110";
  constant OP_ASR    : std_logic_vector(8 downto 0) := "000011111";
  constant OP_LSL    : std_logic_vector(8 downto 0) := "000100000";
  constant OP_SHUF   : std_logic_vector(8 downto 0) := "000100001";

  -- TODO(m): Move to a MUL/DIV entity.
  constant OP_MUL    : std_logic_vector(8 downto 0) := "000110000";
  constant OP_MULHI  : std_logic_vector(8 downto 0) := "000110010";
  constant OP_MULHIU : std_logic_vector(8 downto 0) := "000110011";
  constant OP_DIV    : std_logic_vector(8 downto 0) := "000110100";
  constant OP_DIVU   : std_logic_vector(8 downto 0) := "000110101";
  constant OP_REM    : std_logic_vector(8 downto 0) := "000110110";
  constant OP_REMU   : std_logic_vector(8 downto 0) := "000110111";

  -- TODO(m): Move to an FPU entity.
  constant OP_ITOF   : std_logic_vector(8 downto 0) := "000111000";
  constant OP_FTOI   : std_logic_vector(8 downto 0) := "000111001";
  constant OP_FADD   : std_logic_vector(8 downto 0) := "000111010";
  constant OP_FSUB   : std_logic_vector(8 downto 0) := "000111011";
  constant OP_FMUL   : std_logic_vector(8 downto 0) := "000111100";
  constant OP_FDIV   : std_logic_vector(8 downto 0) := "000111101";

  constant OP_SEL    : std_logic_vector(8 downto 0) := "001000000";
  constant OP_CLZ    : std_logic_vector(8 downto 0) := "001000001";
  constant OP_REV    : std_logic_vector(8 downto 0) := "001000010";
  constant OP_EXTB   : std_logic_vector(8 downto 0) := "001000011";
  constant OP_EXTH   : std_logic_vector(8 downto 0) := "001000100";

  -- We use an adder.
  component adder
    generic(WIDTH : positive);
    port(
        i_c_in   : in  std_logic;
        i_src_a  : in  std_logic_vector(WIDTH-1 downto 0);
        i_src_b  : in  std_logic_vector(WIDTH-1 downto 0);
        o_result : out std_logic_vector(WIDTH-1 downto 0);
        o_c_out  : out std_logic
      );
  end component;

  -- We use a comparator.
  component comparator
    generic(WIDTH : positive);
    port(
        i_src : in  std_logic_vector(WIDTH-1 downto 0);
        o_eq  : out std_logic;
        o_lt  : out std_logic;
        o_le  : out std_logic
      );
  end component;

  -- Intermediate (concurrent) operation results.
  signal s_or_res : std_logic_vector(31 downto 0);
  signal s_nor_res : std_logic_vector(31 downto 0);
  signal s_and_res : std_logic_vector(31 downto 0);
  signal s_bic_res : std_logic_vector(31 downto 0);
  signal s_xor_res : std_logic_vector(31 downto 0);
  signal s_sel_res : std_logic_vector(31 downto 0);
  signal s_slt_res : std_logic_vector(31 downto 0);
  signal s_cmp_res : std_logic_vector(31 downto 0);
  -- ...

  -- Signals for the adder.
  signal s_adder_xor_mask : std_logic_vector(31 downto 0);
  signal s_adder_a : std_logic_vector(31 downto 0);
  signal s_adder_b : std_logic_vector(31 downto 0);
  signal s_adder_carry_in : std_logic;
  signal s_adder_result : std_logic_vector(31 downto 0);
  signal s_adder_carry_out : std_logic;

  -- Signals for the comparator.
  signal s_comparator_src : std_logic_vector(31 downto 0);
  signal s_comparator_eq  : std_logic;
  signal s_comparator_lt  : std_logic;
  signal s_comparator_le  : std_logic;
  signal s_cmp_bit : std_logic;

begin

  ------------------------------------------------------------------------------------------------
  -- Bitwise operations
  ------------------------------------------------------------------------------------------------

  -- OP_OR
  s_or_res <= i_src_a or i_src_b;

  -- OP_NOR
  s_nor_res <= not s_or_res;

  -- OP_AND
  s_and_res <= i_src_a and i_src_b;

  -- OP_BIC
  s_bic_res <= i_src_a and (not i_src_b);

  -- OP_XOR
  s_xor_res <= i_src_a xor i_src_b;

  -- OP_SEL
  s_sel_res <= (i_src_a and i_src_c) or (i_src_b and (not i_src_c));


  ------------------------------------------------------------------------------------------------
  -- Arithmetic operations
  ------------------------------------------------------------------------------------------------

  -- TODO(m): Handle unsigned compares (SLTU, CLTU, CLEU).

  AluAdder: entity work.adder
    generic map (
      WIDTH => 32
    )
    port map (
      i_c_in => s_adder_carry_in,
      i_src_a => s_adder_a,
      i_src_b => s_adder_b,
      o_result => s_adder_result,
      o_c_out => s_adder_carry_out
    );

  AluComparator: entity work.comparator
    generic map (
      WIDTH => 32
    )
    port map (
      i_src => s_comparator_src,
      o_eq => s_comparator_eq,
      o_lt => s_comparator_lt,
      o_le => s_comparator_le
    );

  -- Set up inputs to the adder.
  NegAdderAMux: with i_op select
    s_adder_carry_in <= '1' when OP_SUB | OP_SLT | OP_SLTU | OP_CEQ | OP_CLT | OP_CLTU | OP_CLE | OP_CLEU,
                        '0' when others;
  s_adder_xor_mask <= (others => s_adder_carry_in);
  s_adder_a <= i_src_a xor s_adder_xor_mask;
  s_adder_b <= i_src_b;

  -- Set up inputs to the comparator.
  s_comparator_src <= s_adder_result;

  -- Set operations.
  s_slt_res(31 downto 1) <= "0000000000000000000000000000000";
  s_slt_res(0) <= s_comparator_lt;

  -- Compare operations.
  CmpMux: with i_op select
    s_cmp_bit <= s_comparator_eq when OP_CEQ,
                 s_comparator_lt when OP_CLT | OP_CLTU,
                 s_comparator_le when OP_CLE | OP_CLEU,
                 '0' when others;
  s_cmp_res <= (others => s_cmp_bit);


  ------------------------------------------------------------------------------------------------
  -- Select the output.
  ------------------------------------------------------------------------------------------------

  AluMux: with i_op select
    o_result <= s_or_res when OP_OR,
                s_nor_res when OP_NOR,
                s_and_res when OP_AND,
                s_bic_res when OP_BIC,
                s_xor_res when OP_XOR,
                s_sel_res when OP_SEL,
                s_adder_result when OP_ADD | OP_SUB,
                s_slt_res when OP_SLT | OP_SLTU,
                s_cmp_res when OP_CEQ | OP_CLT | OP_CLTU | OP_CLE | OP_CLEU,
                -- ...
                "00000000000000000000000000000000" when others;

end rtl;

