------------------------------------------------------------------------------------
---- Scan Chain for MIPS32 LBIST Integration
---- 
---- Operation Flow:
---- 1. SHIFT MODE (SE=1): 
----    - Serially shift 32 bits from LBIST TPG into scan FFs (32 cycles)
----    - Parallel output provides 32-bit instruction to MIPS32
---- 
---- 2. FUNCTIONAL MODE (SE=0):
----    - MIPS32 executes using scan chain instruction
----    - Pipeline processes the instruction
---- 
---- 3. CAPTURE MODE (SE=0, capture pulse):
----    - MIPS32 output captured into scan FFs
----    - Response stored for scan-out
---- 
---- 4. SCAN-OUT MODE (SE=1):
----    - Serially shift captured response out to MISR
----
------------------------------------------------------------------------------------
--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--entity scan_chain is
--    Generic (
--        CHAIN_LENGTH : integer := 32  -- 32-bit instruction width
--    );
--    Port (
--        clk         : in  STD_LOGIC;
--        reset       : in  STD_LOGIC;

--        -- Scan control signals
--        scan_enable : in  STD_LOGIC;  -- 1=scan shift, 0=capture/functional

--        -- Scan path (serial)
--        scan_in     : in  STD_LOGIC;  -- Serial input from LBIST TPG
--        scan_out    : out STD_LOGIC;  -- Serial output to MISR

--        -- MIPS32 interface (parallel)
--        mips_instruction : out STD_LOGIC_VECTOR(31 downto 0);  -- To MIPS32 (parallel)
--        mips_output      : in  STD_LOGIC_VECTOR(31 downto 0);  -- From MIPS32 (parallel)

--        -- PLPF feedback
--        first_ff_out : out STD_LOGIC  -- Feedback for PLPF past_bit
--    );
--end scan_chain;
--architecture Behavioral of scan_chain is
--    -- Scan flip-flop chain (32 bits)
--    signal scan_ff : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
--begin
--    -- ========================================================================
--    -- Scan Flip-Flop Chain with Shift and Capture
--    -- ========================================================================

--    scan_process: process(clk, reset)
--    begin
--        if reset = '1' then
--            scan_ff <= (others => '0');

--        elsif rising_edge(clk) then

--            if scan_enable = '1' then
--                -- SHIFT MODE: Serial shift operation
--                -- shift_left: new bit enters at LSB, shifts toward MSB
--                scan_ff <= scan_ff(30 downto 0) & scan_in;
--                -- scan_ff(31) ← scan_ff(30) ← ... ← scan_ff(0) ← scan_in

--            else
--                -- CAPTURE MODE: Parallel load from MIPS32 output
--                scan_ff <= mips_output;

--            end if;

--        end if;
--    end process;

--    -- ========================================================================
--    -- Output Assignments
--    -- ========================================================================

--    -- Serial output: MSB shifted out to MISR
--    scan_out <= scan_ff(31);

--    -- Parallel output: Complete 32-bit instruction to MIPS32
--    mips_instruction <= scan_ff;

--    -- PLPF feedback: First flip-flop for past_bit
--    first_ff_out <= scan_ff(0);
--end Behavioral;


----------------------------------------------------------------------------------
-- Scan Chain for MIPS32 LBIST Integration
-- 
-- Operation Flow:
-- 1. SHIFT MODE (SE=1): 
--    - Serially shift 32 bits from LBIST TPG into scan FFs (32 cycles)
--    - Parallel output provides 32-bit instruction to MIPS32
-- 
-- 2. FUNCTIONAL MODE (SE=0):
--    - MIPS32 executes using scan chain instruction
--    - Pipeline processes the instruction
-- 
-- 3. CAPTURE MODE (SE=0, capture pulse):
--    - MIPS32 output captured into scan FFs
--    - Response stored for scan-out
-- 
-- 4. SCAN-OUT MODE (SE=1):
--    - Serially shift captured response out to MISR
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity scan_chain is
    Generic (
        CHAIN_LENGTH : integer := 32  -- 32-bit instruction width
    );
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        
        -- Scan control signals
        scan_enable : in  STD_LOGIC;  -- 1=scan shift, 0=capture/functional
        
        -- Scan path (serial)
        scan_in     : in  STD_LOGIC;  -- Serial input from LBIST TPG
        scan_out    : out STD_LOGIC;  -- Serial output to MISR
        
        -- MIPS32 interface (parallel)
        mips_instruction : out STD_LOGIC_VECTOR(31 downto 0);  -- To MIPS32 (parallel)
        mips_output      : in  STD_LOGIC_VECTOR(31 downto 0);  -- From MIPS32 (parallel)
        
        -- PLPF feedback
        first_ff_out : out STD_LOGIC  -- Feedback for PLPF past_bit
    );
end scan_chain;

architecture Behavioral of scan_chain is

    -- Scan flip-flop chain (32 bits)
    signal scan_ff : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

begin

    -- ========================================================================
    -- Scan Flip-Flop Chain with Shift and Capture (structural form)
    -- ========================================================================

    -- Bit 0: serial input from scan_in, functional input from mips_output(0)
    bit0: entity work.scan_dff
        port map (
            clk   => clk,
            reset => reset,
            se    => scan_enable,
            di    => mips_output(0),
            si    => scan_in,
            q     => scan_ff(0)
        );

    -- Bits 1..30: chained scan flip-flops
    gen_bits: for i in 1 to 30 generate
        scan_i: entity work.scan_dff
            port map (
                clk   => clk,
                reset => reset,
                se    => scan_enable,
                di    => mips_output(i),
                si    => scan_ff(i-1),
                q     => scan_ff(i)
            );
    end generate;

    -- Bit 31: last flip-flop in the chain
    bit31: entity work.scan_dff
        port map (
            clk   => clk,
            reset => reset,
            se    => scan_enable,
            di    => mips_output(31),
            si    => scan_ff(30),
            q     => scan_ff(31)
        );

    
    -- ========================================================================
    -- Output Assignments
    -- ========================================================================
    
    -- Serial output: MSB shifted out to MISR
    scan_out <= scan_ff(31);
    
    -- Parallel output: Complete 32-bit instruction to MIPS32
    mips_instruction <= scan_ff;
    
    -- PLPF feedback: First flip-flop for past_bit
    first_ff_out <= scan_ff(0);

end Behavioral;
