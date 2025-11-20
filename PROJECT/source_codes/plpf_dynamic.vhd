----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 
-- Design Name: 
-- Module Name: plpf_dynamic - Behavioral
-- Project Name: LBIST Power Control for MIPS32
-- Target Devices: 
-- Tool Versions: 
-- Description: Dynamic PLPF with Basic Control Approach
--              Implements flexible scan-in power control
--              Pattern structure: [Head-Low] [Middle-High] [Tail-Low]
--              Based on research paper Section IV
-- 
-- Dependencies: None
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--   Dynamically switches between n=1, n=2, n=3 during scan-in
--   Uses scan_counter to determine which PLPF to activate
--   Target toggle rate achieved by varying α, β, γ parameters
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity plpf_dynamic is
    Generic (
        SCAN_CHAIN_LENGTH : integer := 32  -- Total scan chain length (L)
    );
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        enable      : in  STD_LOGIC;
        
        -- Inputs from PSF (current and future bits)
        current_bit : in  STD_LOGIC;        -- T_j
        future_bit1 : in  STD_LOGIC;        -- T_j+1
        future_bit2 : in  STD_LOGIC;        -- T_j+2
        
        -- Input from scan chain feedback (past bit)
        past_bit    : in  STD_LOGIC;        -- S_j-1
        
        -- Switch timing parameters (Basic Control)
        -- Pattern: [Tail-α bits] [Middle-β bits] [Head-γ bits]
        alpha       : in  integer range 0 to 255;  -- Tail length (low toggle)
        beta        : in  integer range 0 to 255;  -- Middle length (high toggle)
        gamma       : in  integer range 0 to 255;  -- Head length (low toggle)
        
        -- Control
        scan_counter : in integer range 0 to 255;  -- Current bit position in scan chain
        
        -- Output to scan chain
        plpf_out    : out STD_LOGIC
    );
end plpf_dynamic;

architecture Behavioral of plpf_dynamic is

    -- PLPF computational signals
    signal and_gate_n2 : STD_LOGIC;
    signal or_gate_n2  : STD_LOGIC;
    signal mux_out_n2  : STD_LOGIC;
    
    signal and_gate_n3 : STD_LOGIC;
    signal or_gate_n3  : STD_LOGIC;
    signal mux_out_n3  : STD_LOGIC;
    
    -- Active PLPF selection based on scan position
    signal active_plpf_mode : STD_LOGIC_VECTOR(1 downto 0);
    
    signal final_output : STD_LOGIC;

begin

    -- ========================================================================
    -- Dynamic PLPF Selection Logic (Basic Control Approach)
    -- ========================================================================
    -- Pattern structure: [Tail-α] [Middle-β] [Head-γ]
    -- Tail (0 to α-1):            Use n=3 (low toggle ~7%)
    -- Middle (α to α+β-1):        Use n=1 (high toggle ~50%)
    -- Head (α+β to α+β+γ-1):      Use n=3 (low toggle ~7%)
    
    selection_process: process(scan_counter, alpha, beta, gamma)
    begin
        if scan_counter < alpha then
            -- Tail part: Use PLPF n=3 (low toggle)
            active_plpf_mode <= "10";
            
        elsif scan_counter < (alpha + beta) then
            -- Middle part: Use bypass n=1 (high toggle)
            active_plpf_mode <= "00";
            
        else
            -- Head part: Use PLPF n=3 (low toggle)
            active_plpf_mode <= "10";
        end if;
    end process;
    
    
    -- ========================================================================
    -- PLPF Computation Logic
    -- ========================================================================
    
    -- PLPF n=2 computation (not used in Basic Control, but available)
    and_gate_n2 <= current_bit and future_bit1;
    or_gate_n2  <= current_bit or future_bit1;
    mux_out_n2  <= and_gate_n2 when past_bit = '0' else or_gate_n2;
    
    -- PLPF n=3 computation (used for head and tail)
    and_gate_n3 <= current_bit and future_bit1 and future_bit2;
    or_gate_n3  <= current_bit or future_bit1 or future_bit2;
    mux_out_n3  <= and_gate_n3 when past_bit = '0' else or_gate_n3;
    
    
    -- ========================================================================
    -- Output Selection based on active_plpf_mode
    -- ========================================================================
    
    output_selection: process(active_plpf_mode, current_bit, mux_out_n2, mux_out_n3)
    begin
        case active_plpf_mode is
            when "00" =>
                -- Bypass (n=1): Direct pass-through
                final_output <= current_bit;
                
            when "01" =>
                -- PLPF n=2: 16.67% toggle
                final_output <= mux_out_n2;
                
            when "10" =>
                -- PLPF n=3: 7.14% toggle
                final_output <= mux_out_n3;
                
            when others =>
                -- Default: bypass
                final_output <= current_bit;
        end case;
    end process;
    
    
    -- ========================================================================
    -- Output Assignment (Combinational)
    -- ========================================================================
    
    plpf_out <= final_output;

end Behavioral;


----------------------------------------------------------------------------------
-- Design Notes:
----------------------------------------------------------------------------------
-- 
-- 1. Basic Control Pattern Structure:
--    Position 0 to α-1:        PLPF n=3 (Tail, low toggle)
--    Position α to α+β-1:      Bypass n=1 (Middle, high toggle)
--    Position α+β to L-1:      PLPF n=3 (Head, low toggle)
--
-- 2. Switch Timing Calculation (from paper Formula 3):
--    Target WTM = (Σ_tail × 0.0714 + Σ_middle × 0.5 + Σ_head × 0.0714) / Σ_total
--    Where: α + β + γ = L (scan chain length)
--
-- 3. Example for 32-bit scan chain with target 15% toggle:
--    α = 10, β = 12, γ = 10
--    WTM ≈ 15%
--
-- 4. Minimum Segment Lengths (from paper constraint):
--    - For n=3: minimum 14 bits
--    - For n=2: minimum 6 bits
--    - For n=1: no minimum
--
-- 5. Usage in scan operation:
--    - scan_counter starts at 0 when scan-in begins
--    - Increments each clock cycle
--    - PLPF automatically switches based on counter value
--
----------------------------------------------------------------------------------