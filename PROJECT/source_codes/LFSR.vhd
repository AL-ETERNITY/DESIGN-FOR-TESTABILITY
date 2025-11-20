----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 
-- Design Name: 
-- Module Name: lfsr_32bit - Behavioral
-- Project Name: LBIST Power Control for MIPS32
-- Target Devices: 
-- Tool Versions: 
-- Description: 32-bit Linear Feedback Shift Register (LFSR)
--              Primitive Polynomial: x^32 + x^22 + x^2 + x + 1
--              Used for pseudo-random test pattern generation in LBIST
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LFSR is
    Port (
        clk       : in  STD_LOGIC;                      -- Clock input
        reset     : in  STD_LOGIC;                      -- Asynchronous reset (active high)
        enable    : in  STD_LOGIC;                      -- Enable signal for LFSR operation
        seed      : in  STD_LOGIC_VECTOR(31 downto 0); -- Initial seed value
        load_seed : in  STD_LOGIC;                      -- Load seed control signal
        lfsr_out  : out STD_LOGIC_VECTOR(31 downto 0); -- Parallel output (all 32 bits)
        serial_out: out STD_LOGIC                       -- Serial output (MSB)
    );
end LFSR;

architecture Behavioral of LFSR is
    
    -- Internal LFSR register
    signal lfsr_reg : STD_LOGIC_VECTOR(31 downto 0) := (others => '1');
    
    -- Feedback bit calculation
    signal feedback : STD_LOGIC;
    
begin
    
    -- Feedback calculation for polynomial x^32 + x^22 + x^2 + x + 1
    -- This means: feedback = lfsr_reg(31) XOR lfsr_reg(21) XOR lfsr_reg(1) XOR lfsr_reg(0)
    -- Note: x^32 corresponds to the next state, so we XOR positions 31, 21, 1, 0
    feedback <= lfsr_reg(31) xor lfsr_reg(21) xor lfsr_reg(1) xor lfsr_reg(0);
    
    -- LFSR process
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset to all ones (non-zero state required for maximal length sequence)
            lfsr_reg <= (others => '1');
            
        elsif rising_edge(clk) then
            
            if load_seed = '1' then
                -- Load the seed value
                lfsr_reg <= seed;
                
            elsif enable = '1' then
                -- Shift operation with feedback
                -- Shift left and insert feedback at LSB
                lfsr_reg <= lfsr_reg(30 downto 0) & feedback;
                
            end if;
            
        end if;
    end process;
    
    -- Output assignments
    lfsr_out   <= lfsr_reg;      -- Parallel output (for debugging/monitoring)
    serial_out <= lfsr_reg(31);  -- Serial output (PRIMARY - used for single scan chain)
    
end Behavioral;
