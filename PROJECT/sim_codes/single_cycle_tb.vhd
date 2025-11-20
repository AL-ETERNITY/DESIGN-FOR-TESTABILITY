library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity single_cycle_tb is
end single_cycle_tb;

architecture test of single_cycle_tb is
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal scan_enable : std_logic := '1';
    signal scan_instruction : std_logic_vector(31 downto 0) := (others => '0');
    signal instr : std_logic_vector(31 downto 0);
    signal mips_output : std_logic_vector(31 downto 0);
    signal test_done : boolean := false;
    
    begin
        inst_single_cycle : entity work.single_cycle(rtl)
            port map(
                clk => clk,
                reset => reset,
                scan_enable => scan_enable,
                scan_instruction => scan_instruction,
                instr => instr,
                mips_output => mips_output
            );
        
        clk <= not clk after 10 ns when not test_done else '0';
        
        process begin
            reset <= '1';
            scan_enable <= '1';
            wait for 20 ns;
            reset <= '0';
            wait for 20 ns;
            
            for i in 1 to 20 loop
              wait for 20 ns;
            end loop;
            
            test_done <= true;
            wait;
        end process;
    end test;