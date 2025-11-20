----------------------------------------------------------------------------------
-- Testbench for PLPF (Pseudo Low-Pass Filter)
-- Tests toggle rate reduction for n=1, n=2, n=3 configurations
-- Verifies against theoretical toggle rates
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use IEEE.MATH_REAL.ALL;

entity plpf_tb is
end plpf_tb;

architecture Behavioral of plpf_tb is

    -- Component declarations
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
    
    component psf
        Port (
            lfsr_state  : in  STD_LOGIC_VECTOR(31 downto 0);
            current_bit : out STD_LOGIC;
            future_bit1 : out STD_LOGIC;
            future_bit2 : out STD_LOGIC
        );
    end component;
    
    component plpf
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            enable      : in  STD_LOGIC;
            current_bit : in  STD_LOGIC;
            future_bit1 : in  STD_LOGIC;
            future_bit2 : in  STD_LOGIC;
            past_bit    : in  STD_LOGIC;
            plpf_select : in  STD_LOGIC_VECTOR(1 downto 0);
            plpf_out    : out STD_LOGIC
        );
    end component;
    
    -- Testbench signals
    signal clk       : STD_LOGIC := '0';
    signal reset     : STD_LOGIC := '0';
    signal enable    : STD_LOGIC := '0';
    signal seed      : STD_LOGIC_VECTOR(31 downto 0) := X"AAAAAAAA";
    signal load_seed : STD_LOGIC := '0';
    signal lfsr_out  : STD_LOGIC_VECTOR(31 downto 0);
    signal serial_out: STD_LOGIC;
    
    signal current_bit : STD_LOGIC;
    signal future_bit1 : STD_LOGIC;
    signal future_bit2 : STD_LOGIC;
    
    signal past_bit    : STD_LOGIC := '0';
    signal plpf_select : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal plpf_out    : STD_LOGIC;
    
    -- Clock period
    constant clk_period : time := 10 ns;
    signal test_done : boolean := false;
    
    -- Toggle measurement for different modes
    type toggle_array is array (0 to 2) of integer;
    signal toggle_count : toggle_array := (others => 0);
    signal prev_output  : STD_LOGIC := '0';
    signal cycle_count  : integer := 0;

begin

    -- Instantiate LFSR
    lfsr_inst: LFSR
        port map (
            clk       => clk,
            reset     => reset,
            enable    => enable,
            seed      => seed,
            load_seed => load_seed,
            lfsr_out  => lfsr_out,
            serial_out=> serial_out
        );
    
    -- Instantiate PSF
    psf_inst: psf
        port map (
            lfsr_state  => lfsr_out,
            current_bit => current_bit,
            future_bit1 => future_bit1,
            future_bit2 => future_bit2
        );
    
    -- Instantiate PLPF
    plpf_inst: plpf
        port map (
            clk         => clk,
            reset       => reset,
            enable      => enable,
            current_bit => current_bit,
            future_bit1 => future_bit1,
            future_bit2 => future_bit2,
            past_bit    => past_bit,
            plpf_select => plpf_select,
            plpf_out    => plpf_out
        );

    -- Clock generation
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

    -- Update past_bit from plpf_out (simulating scan chain feedback)
    feedback_process: process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                past_bit <= plpf_out;
            end if;
        end if;
    end process;

    -- Stimulus and measurement process
    stim_proc: process
        variable mode : integer;
        variable toggle_rate : real;
        file output_file : text;
        variable output_line : line;
    begin
        
        file_open(output_file, "plpf_results.txt", write_mode);
        
        report "======================================";
        report "Starting PLPF Testbench";
        report "======================================";
        
        -- Initialize LFSR
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period;
        
        seed <= X"AAAAAAAA";
        load_seed <= '1';
        wait for clk_period;
        load_seed <= '0';
        wait for clk_period;
        
        enable <= '1';
        wait for clk_period * 2;  -- Warm-up cycles
        
        -- ================================================================
        -- Test Mode 0: Bypass (n=1, expected ~50% toggle rate)
        -- ================================================================
        report "";
        report "Testing Mode 0: Bypass (n=1)";
        report "Expected toggle rate: ~50%";
        
        plpf_select <= "00";
        toggle_count(0) <= 0;
        cycle_count <= 0;
        prev_output <= plpf_out;
        
        -- Write header
        write(output_line, string'("Mode 0 (Bypass - 50%)"));
        writeline(output_file, output_line);
        
        for i in 1 to 20 loop
            wait for clk_period;
            
            -- Count toggles
            if plpf_out /= prev_output then
                toggle_count(0) <= toggle_count(0) + 1;
            end if;
            prev_output <= plpf_out;
            cycle_count <= cycle_count + 1;
        end loop;
        
        toggle_rate := real(toggle_count(0)) / real(cycle_count);
        write(output_line, string'("Toggles: "));
        write(output_line, toggle_count(0));
        write(output_line, string'(" / "));
        write(output_line, cycle_count);
        write(output_line, string'(" = "));
        write(output_line, toggle_rate * 100.0);
        write(output_line, string'("%"));
        writeline(output_file, output_line);
        
        report "Mode 0 Results:";
        report "  Toggles: " & integer'image(toggle_count(0)) & 
               " / " & integer'image(cycle_count);
        report "  Toggle rate: " & integer'image(integer(toggle_rate * 100.0)) & "%";
        report "  Expected: ~50%";
        
        wait for clk_period * 2;
        
        -- ================================================================
        -- Test Mode 1: PLPF n=2 (expected ~16.67% toggle rate)
        -- ================================================================
        report "";
        report "Testing Mode 1: PLPF n=2";
        report "Expected toggle rate: ~16.67%";
        
        -- Reinitialize
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        seed <= X"AAAAAAAA";
        load_seed <= '1';
        wait for clk_period;
        load_seed <= '0';
        enable <= '1';
        wait for clk_period * 2;
        
        plpf_select <= "01";
        toggle_count(1) <= 0;
        cycle_count <= 0;
        prev_output <= plpf_out;
        
        write(output_line, string'(""));
        writeline(output_file, output_line);
        write(output_line, string'("Mode 1 (PLPF n=2 - 16.67%)"));
        writeline(output_file, output_line);
        
        for i in 1 to 20 loop
            wait for clk_period;
            
            if plpf_out /= prev_output then
                toggle_count(1) <= toggle_count(1) + 1;
            end if;
            prev_output <= plpf_out;
            cycle_count <= cycle_count + 1;
        end loop;
        
        toggle_rate := real(toggle_count(1)) / real(cycle_count);
        write(output_line, string'("Toggles: "));
        write(output_line, toggle_count(1));
        write(output_line, string'(" / "));
        write(output_line, cycle_count);
        write(output_line, string'(" = "));
        write(output_line, toggle_rate * 100.0);
        write(output_line, string'("%"));
        writeline(output_file, output_line);
        
        report "Mode 1 Results:";
        report "  Toggles: " & integer'image(toggle_count(1)) & 
               " / " & integer'image(cycle_count);
        report "  Toggle rate: " & integer'image(integer(toggle_rate * 100.0)) & "%";
        report "  Expected: ~16.67%";
        
        wait for clk_period * 2;
        
        -- ================================================================
        -- Test Mode 2: PLPF n=3 (expected ~7.14% toggle rate)
        -- ================================================================
        report "";
        report "Testing Mode 2: PLPF n=3";
        report "Expected toggle rate: ~7.14%";
        
        -- Reinitialize
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        seed <= X"AAAAAAAA";
        load_seed <= '1';
        wait for clk_period;
        load_seed <= '0';
        enable <= '1';
        wait for clk_period * 2;
        
        plpf_select <= "10";
        toggle_count(2) <= 0;
        cycle_count <= 0;
        prev_output <= plpf_out;
        
        write(output_line, string'(""));
        writeline(output_file, output_line);
        write(output_line, string'("Mode 2 (PLPF n=3 - 7.14%)"));
        writeline(output_file, output_line);
        
        for i in 1 to 20 loop
            wait for clk_period;
            
            if plpf_out /= prev_output then
                toggle_count(2) <= toggle_count(2) + 1;
            end if;
            prev_output <= plpf_out;
            cycle_count <= cycle_count + 1;
        end loop;
        
        toggle_rate := real(toggle_count(2)) / real(cycle_count);
        write(output_line, string'("Toggles: "));
        write(output_line, toggle_count(2));
        write(output_line, string'(" / "));
        write(output_line, cycle_count);
        write(output_line, string'(" = "));
        write(output_line, toggle_rate * 100.0);
        write(output_line, string'("%"));
        writeline(output_file, output_line);
        
        report "Mode 2 Results:";
        report "  Toggles: " & integer'image(toggle_count(2)) & 
               " / " & integer'image(cycle_count);
        report "  Toggle rate: " & integer'image(integer(toggle_rate * 100.0)) & "%";
        report "  Expected: ~7.14%";
        
        -- ================================================================
        -- Summary
        -- ================================================================
        report "";
        report "======================================";
        report "PLPF Test Summary";
        report "======================================";
        report "Mode 0 (Bypass):   " & integer'image(integer((real(toggle_count(0)) / 20.0) * 100.0)) & "% (expected ~50%)";
        report "Mode 1 (n=2):      " & integer'image(integer((real(toggle_count(1)) / 20.0) * 100.0)) & "% (expected ~16.67%)";
        report "Mode 2 (n=3):      " & integer'image(integer((real(toggle_count(2)) / 20.0) * 100.0)) & "% (expected ~7.14%)";
        report "======================================";
        
        file_close(output_file);
        test_done <= true;
        wait;
        
    end process;

end Behavioral;