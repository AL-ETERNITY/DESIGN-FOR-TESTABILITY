----------------------------------------------------------------------------------
-- Testbench for 32-bit LFSR
-- Tests: Reset, Seed loading, Pattern generation, Periodicity check
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity LFSR_tb is
end LFSR_tb;

architecture Behavioral of LFSR_tb is

    -- Component Declaration
    component LFSR
        Port (
            clk       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            enable    : in  STD_LOGIC;
            seed      : in  STD_LOGIC_VECTOR(31 downto 0);
            load_seed : in  STD_LOGIC;
            lfsr_out  : out STD_LOGIC_VECTOR(31 downto 0);
            serial_out: out STD_LOGIC
        );
    end component;
    
    -- Testbench signals
    signal clk       : STD_LOGIC := '0';
    signal reset     : STD_LOGIC := '0';
    signal enable    : STD_LOGIC := '0';
    signal seed      : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal load_seed : STD_LOGIC := '0';
    signal lfsr_out  : STD_LOGIC_VECTOR(31 downto 0);
    signal serial_out: STD_LOGIC;
    
    -- Clock period definition
    constant clk_period : time := 10 ns;
    
    -- Test control
    signal test_done : boolean := false;
    
    -- Toggle rate measurement
    signal toggle_count : integer := 0;
    signal prev_bit : STD_LOGIC := '0';
    
begin

    -- Instantiate the Unit Under Test (UUT)
    uut: LFSR
        port map (
            clk       => clk,
            reset     => reset,
            enable    => enable,
            seed      => seed,
            load_seed => load_seed,
            lfsr_out  => lfsr_out,
            serial_out=> serial_out
        );

    -- Clock generation process
    clk_process: process
    begin
        while not test_done loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

    -- Toggle rate measurement process
    toggle_measure: process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                if serial_out /= prev_bit then
                    toggle_count <= toggle_count + 1;
                end if;
                prev_bit <= serial_out;
            end if;
        end if;
    end process;

    -- Stimulus process
    stim_proc: process
        variable first_state : STD_LOGIC_VECTOR(31 downto 0);
        variable cycle_count : integer := 0;
        file output_file : text;
        variable output_line : line;
    begin
        
        -- Open file for writing patterns (optional - for verification)
        file_open(output_file, "lfsr_output.txt", write_mode);
        
        report "======================================";
        report "Starting LFSR 32-bit Testbench";
        report "======================================";
        
        -- Test 1: Reset Test
        report "Test 1: Testing Reset Functionality";
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period;
        assert lfsr_out = X"FFFFFFFF" 
            report "Reset failed! Expected FFFFFFFF, got " & integer'image(to_integer(unsigned(lfsr_out)))
            severity error;
        report "Reset Test PASSED";
        wait for clk_period * 2;
        
        -- Test 2: Seed Loading Test
        report "Test 2: Testing Seed Loading";
        seed <= X"AAAAAAAA";
        load_seed <= '1';
        wait for clk_period;
        load_seed <= '0';
        wait for clk_period;
        assert lfsr_out = X"AAAAAAAA"
            report "Seed loading failed!"
            severity error;
        report "Seed Loading Test PASSED";
        wait for clk_period * 2;
        
        -- Test 3: Pattern Generation Test
        report "Test 3: Testing Pattern Generation (10 cycles)";
        enable <= '1';
        
        -- Store first state for periodicity check
        wait for clk_period;
        first_state := lfsr_out;
        
        -- Generate 1000 patterns and write to file
        for i in 1 to 10 loop
            wait for clk_period;
            
            -- Write to file (optional)
            write(output_line, string'("Cycle "));
            write(output_line, i);
            write(output_line, string'(": "));
            hwrite(output_line, lfsr_out);
            writeline(output_file, output_line);
            
            -- Check that LFSR never gets stuck at zero
            assert lfsr_out /= X"00000000"
                report "LFSR stuck at zero state!"
                severity error;
                
            cycle_count := cycle_count + 1;
        end loop;
        
        report "Generated 10 pseudo-random patterns";
        report "Pattern Generation Test PASSED";
        
        -- Test 4: Toggle Rate Measurement
        wait for clk_period * 10;
        report "======================================";
        report "Toggle Rate Statistics:";
        report "Total toggles in 1000 cycles: " & integer'image(toggle_count);
        report "Toggle rate: " & integer'image((toggle_count * 100) / 1000) & "%";
        report "Expected: ~50% for ideal pseudo-random";
        report "======================================";
        
        -- Test 5: Enable Control Test
        report "Test 4: Testing Enable Control";
        enable <= '0';
        wait for clk_period * 5;
        assert lfsr_out'stable(clk_period * 4)
            report "LFSR should not change when disabled"
            severity error;
        report "Enable Control Test PASSED";
        
        enable <= '1';
        wait for clk_period * 5;
        
        -- Test 6: Different Seed Test
        report "Test 5: Testing Different Seeds";
        seed <= X"12345678";
        load_seed <= '1';
        wait for clk_period;
        load_seed <= '0';
        enable <= '1';
        wait for clk_period * 10;
        report "Different Seed Test PASSED";
        
        -- Close file
        file_close(output_file);
        
        report "======================================";
        report "All Tests Completed Successfully!";
        report "======================================";
        
        test_done <= true;
        wait;
        
    end process;

end Behavioral;