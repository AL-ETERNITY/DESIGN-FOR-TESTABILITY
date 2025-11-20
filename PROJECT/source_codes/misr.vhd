library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity misr is
    port(
        clk       : in  STD_LOGIC;
        reset     : in  STD_LOGIC;
        enable    : in  STD_LOGIC;
        data_in   : in  STD_LOGIC;
        signature : out STD_LOGIC_VECTOR(31 downto 0)
    );
end misr;

architecture rtl of misr is

    -- Internal MISR register
    signal q : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

    -- Feedback bit using polynomial x^32 + x^22 + x^2 + x + 1
    -- Same taps as LFSR: bits 31, 21, 1, 0, with data_in XORed in.
    signal feedback : STD_LOGIC;

begin

    feedback <= q(31) xor q(21) xor q(1) xor q(0) xor data_in;

    process(clk, reset)
    begin
        if reset = '1' then
            q <= (others => '0');
        elsif rising_edge(clk) then
            if enable = '1' then
                -- Shift left and insert feedback into bit 0
                q <= q(30 downto 0) & feedback;
            end if;
        end if;
    end process;

    signature <= q;

end rtl;
