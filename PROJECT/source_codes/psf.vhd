----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 
-- Design Name: 
-- Module Name: psf - Behavioral
-- Project Name: LBIST Power Control for MIPS32
-- Target Devices: 
-- Tool Versions: 
-- Description: Phase Shifter for Filter (PSF)
--              Generates decorrelated bit streams from LFSR for PLPF
--              Creates "future bits" by XOR combinations of LFSR taps
-- 
-- Dependencies: lfsr_32bit.vhd
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--   For single scan chain: Only needs current bit + 2 future bits for PLPF
--   XOR tap positions chosen to maximize decorrelation
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity psf is
    Port (
        -- Input from LFSR (all 32 bits)
        lfsr_state : in  STD_LOGIC_VECTOR(31 downto 0);
        
        -- Output bits for PLPF
        current_bit : out STD_LOGIC;        -- T_j (for PLPF current bit)
        future_bit1 : out STD_LOGIC;        -- T_j+1 (for PLPF future bit 1)
        future_bit2 : out STD_LOGIC         -- T_j+2 (for PLPF future bit 2)
    );
end psf;

architecture Behavioral of psf is

    -- Internal signals for XOR combinations
    signal fb1_xor : STD_LOGIC;
    signal fb2_xor : STD_LOGIC;

begin

--    -- Current bit: Direct tap from LFSR MSB
--    -- This is the main bit that would go to scan chain without PLPF
--    current_bit <= lfsr_state(31);
    
--    -- Future bit 1 (T_j+1): XOR combination for phase shift
--    -- Uses taps at positions 30, 22, 2, 1 for good decorrelation
--    -- These positions are chosen based on the LFSR primitive polynomial
--    fb1_xor <= lfsr_state(30) xor lfsr_state(22) xor lfsr_state(2) xor lfsr_state(1);
--    future_bit1 <= fb1_xor;
    
--    -- Future bit 2 (T_j+2): Different XOR combination for more phase shift
--    -- Uses taps at positions 29, 21, 15, 0 for maximum decorrelation
--    fb2_xor <= lfsr_state(29) xor lfsr_state(21) xor lfsr_state(15) xor lfsr_state(0);
--    future_bit2 <= fb2_xor;
    
--    -- Note: The XOR tap selections are based on:
--    -- 1. LFSR primitive polynomial (x^32 + x^22 + x^2 + x + 1)
--    -- 2. Maximum distance between taps for decorrelation
--    -- 3. Avoiding adjacent taps to reduce correlation

        current_bit <= lfsr_state(31);
        future_bit1 <= lfsr_state(30);  -- Simple direct tap
        future_bit2 <= lfsr_state(29); 

end Behavioral;