----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 
-- Design Name: 
-- Module Name: plpf - Behavioral
-- Project Name: LBIST Power Control for MIPS32
-- Target Devices: 
-- Tool Versions: 
-- Description: Pseudo Low-Pass Filter (PLPF)
--              Reduces toggle rate of scan-in patterns for power control
--              Supports n=2 (16.67% toggle) and n=3 (7.14% toggle)
--              Based on optimized design from research paper
-- 
-- Dependencies: psf.vhd
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--   Implements optimized PLPF structure with AND/OR gates + MUX
--   Toggle rate formula: T_n = 1/(2^(n+1) - 2)
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity plpf is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        enable      : in  STD_LOGIC;
        
        -- Inputs from PSF (current and future bits)
        current_bit : in  STD_LOGIC;        -- T_j
        future_bit1 : in  STD_LOGIC;        -- T_j+1
        future_bit2 : in  STD_LOGIC;        -- T_j+2 (used only for n=3)
        
        -- Input from scan chain feedback (past bits)
        past_bit    : in  STD_LOGIC;        -- S_j-1 (feedback from first scan FF)
        
        -- Control signal to select PLPF configuration
        plpf_select : in  STD_LOGIC_VECTOR(1 downto 0);
        -- 00: n=1 (bypass, 50% toggle rate)
        -- 01: n=2 (16.67% toggle rate)
        -- 10: n=3 (7.14% toggle rate)
        -- 11: reserved
        
        -- Output to scan chain
        plpf_out    : out STD_LOGIC
    );
end plpf;

architecture Behavioral of plpf is

    -- Internal signals for PLPF computations
    signal and_gate_n2 : STD_LOGIC;  -- AND gate for n=2
    signal or_gate_n2  : STD_LOGIC;  -- OR gate for n=2
    signal mux_out_n2  : STD_LOGIC;  -- MUX output for n=2
    
    signal and_gate_n3 : STD_LOGIC;  -- AND gate for n=3
    signal or_gate_n3  : STD_LOGIC;  -- OR gate for n=3
    signal mux_out_n3  : STD_LOGIC;  -- MUX output for n=3
    
    signal final_output : STD_LOGIC; -- Final multiplexed output

begin

    -- ========================================================================
    -- PLPF for n=2 (3 inputs: current + 1 future + 1 past)
    -- Expected toggle rate: 16.67%
    -- ========================================================================
    
    -- AND gate: current_bit AND future_bit1
    and_gate_n2 <= current_bit and future_bit1;
    
    -- OR gate: current_bit OR future_bit1
    or_gate_n2 <= current_bit or future_bit1;
    
    -- MUX controlled by past_bit
    -- If past_bit = 0, select OR output
    -- If past_bit = 1, select AND output
    mux_out_n2 <= or_gate_n2 when past_bit = '1' else and_gate_n2;
    
    
    -- ========================================================================
    -- PLPF for n=3 (5 inputs: current + 2 future + 1 past)
    -- Expected toggle rate: 7.14%
    -- Note: Optimized design uses only past_bit (S_j-1), not S_j-2
    -- ========================================================================
    
    -- AND gate: current_bit AND future_bit1 AND future_bit2
    and_gate_n3 <= current_bit and future_bit1 and future_bit2;
    
    -- OR gate: current_bit OR future_bit1 OR future_bit2
    or_gate_n3 <= current_bit or future_bit1 or future_bit2;
    
    -- MUX controlled by past_bit
    -- If past_bit = 0, select OR output
    -- If past_bit = 1, select AND output
    mux_out_n3 <= or_gate_n3 when past_bit = '1' else and_gate_n3;
    
    
    -- ========================================================================
    -- Final Output Selection based on plpf_select
    -- ========================================================================
    
    process(plpf_select, current_bit, mux_out_n2, mux_out_n3)
    begin
        case plpf_select is
            when "00" =>
                -- Bypass mode (n=1): Direct pass-through, 50% toggle rate
                final_output <= current_bit;
                
            when "01" =>
                -- PLPF n=2: 16.67% toggle rate
                final_output <= mux_out_n2;
                
            when "10" =>
                -- PLPF n=3: 7.14% toggle rate
                final_output <= mux_out_n3;
                
            when others =>
                -- Default: bypass mode
                final_output <= current_bit;
        end case;
    end process;
    
    plpf_out <= final_output;    

end Behavioral;


----------------------------------------------------------------------------------
-- Design Notes:
----------------------------------------------------------------------------------
-- 
-- 1. Toggle Rate Calculation:
--    For PLPF with n inputs: Toggle_Rate = 1 / (2^(n+1) - 2)
--    - n=1: 1/(4-2)  = 1/2  = 50.00%
--    - n=2: 1/(8-2)  = 1/6  = 16.67%
--    - n=3: 1/(16-2) = 1/14 = 7.14%
--
-- 2. PLPF Operation:
--    The output only toggles when:
--    - past_bit is different from current_bit
--    - AND all future bits are same as current_bit
--    This creates a "filtering" effect that suppresses rapid transitions
--
-- 3. Optimized Structure (from paper):
--    Original PLPF used majority function (exponential gates)
--    Optimized PLPF uses AND/OR gates + MUX (linear gates)
--    Same functionality, much smaller area
--
-- 4. Moving Average Concept:
--    PLPF calculates moving average over (2n-1) bits:
--    - n=2: Average over 3 bits (past_1, current, future_1)
--    - n=3: Average over 5 bits (past_1, current, future_1, future_2)
--    Only outputs when average indicates stable state
--
----------------------------------------------------------------------------------