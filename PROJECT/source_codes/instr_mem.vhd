library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instr_mem is
    port(
        addr_instr : in std_logic_vector(31 downto 0);
        rd_instr : buffer std_logic_vector(31 downto 0)
    );
end instr_mem;

architecture rtl of instr_mem is
    type romtype is array (63 downto 0) of std_logic_vector(31 downto 0);
    -- Default: simple R-type ADD instruction (no NOPs in unused locations)
    signal mem: romtype := (others => x"002081B3");
    
    begin
        mem(0) <= x"00100093";  -- addi x1, x0, 1
        mem(1) <= x"00200113";  -- addi x2, x0, 2
        mem(2) <= x"002081B3";  -- add x3, x1, x2
        mem(3) <= x"003081B3";  -- add x3, x1, x3 (further add)
        mem(4) <= x"004081B3";  -- add x3, x1, x4
        mem(5) <= x"005081B3";  -- add x3, x1, x5
        mem(6) <= x"006081B3";  -- add x3, x1, x6
        mem(7) <= x"007081B3";  -- add x3, x1, x7
        
        process(addr_instr) is
            variable idx : integer;
        begin
            -- Word address = PC / 4
            idx := to_integer(unsigned(addr_instr(31 downto 2)));
            if idx >= 0 and idx <= 63 then
                rd_instr <= mem(idx);
            else
                -- Out-of-range PC: return a safe NOP (ADDI x0,x0,0)
                rd_instr <= x"00000013";
            end if;
        end process;
    end rtl;