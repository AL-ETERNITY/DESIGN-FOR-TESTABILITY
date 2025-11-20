----------------------------------------------------------------------------------
-- Testbench for PSF (Phase Shifter for Filter)
-- Tests decorrelation between current and future bits
-- Measures toggle rates and correlation coefficients
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use IEEE.MATH_REAL.ALL;

entity psf_tb is
end psf_tb;

architecture Behavioral of psf_tb is

    -- Component Declarations
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
    
    -- Clock period
    constant clk_period : time := 10 ns;
    signal test_done : boolean := false;
    
    -- Statistics signals
    signal toggle_current : integer := 0;
    signal toggle_future1 : integer := 0;
    signal toggle_future2 : integer := 0;
    
    signal prev_current : STD_LOGIC := '0';
    signal prev_future1 : STD_LOGIC := '0';
    signal prev_future2 : STD_LOGIC := '0';
    
    -- Correlation measurement
    signal same_as_current_f1 : integer := 0;  -- Future1 same as current
    signal same_as_current_f2 : integer := 0;  -- Future2 same as current
    signal same_f1_f2         : integer := 0;  -- Future1 same as Future2
    signal total_samples      : integer := 0;

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

    -- Toggle rate measurement
    toggle_measure: process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                -- Count toggles for current bit
                if current_bit /= prev_current then
                    toggle_current <= toggle_current + 1;
                end if;
                prev_current <= current_bit;
                
                -- Count toggles for future bit 1
                if future_bit1 /= prev_future1 then
                    toggle_future1 <= toggle_future1 + 1;
                end if;
                prev_future1 <= future_bit1;
                
                -- Count toggles for future bit 2
                if future_bit2 /= prev_future2 then
                    toggle_future2 <= toggle_future2 + 1;
                end if;
                prev_future2 <= future_bit2;
            end if;
        end if;
    end process;

    -- Correlation measurement
    correlation_measure: process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' then
                total_samples <= total_samples + 1;
                
                -- Check if future1 equals current
                if future_bit1 = current_bit then
                    same_as_current_f1 <= same_as_current_f1 + 1;
                end if;
                
                -- Check if future2 equals current
                if future_bit2 = current_bit then
                    same_as_current_f2 <= same_as_current_f2 + 1;
                end if;
                
                -- Check if future1 equals future2
                if future_bit1 = future_bit2 then
                    same_f1_f2 <= same_f1_f2 + 1;
                end if;
            end if;
        end if;
    end process;

    -- Stimulus process
    stim_proc: process
        variable correlation_f1 : real;
        variable correlation_f2 : real;
        variable correlation_f1f2 : real;
        file output_file : text;
        variable output_line : line;
    begin
        
        file_open(output_file, "psf_output.txt", write_mode);
        
        report "======================================";
        report "Starting PSF Testbench";
        report "======================================";
        
        -- Reset
        report "Initializing LFSR...";
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period;
        
        -- Load seed
        report "Loading seed: 0xAAAAAAAA";
        seed <= X"AAAAAAAA";
        load_seed <= '1';
        wait for clk_period;
        load_seed <= '0';
        wait for clk_period;
        
        -- Enable and run for 10000 cycles
        report "Generating 10 patterns...";
        enable <= '1';
        
        -- Write header to file
        write(output_line, string'("Cycle,Current_Bit,Future_Bit1,Future_Bit2"));
        writeline(output_file, output_line);
        
        for i in 1 to 10 loop
            wait for clk_period;
            
            -- Write to file
            write(output_line, i);
            write(output_line, string'(","));
            write(output_line, current_bit);
            write(output_line, string'(","));
            write(output_line, future_bit1);
            write(output_line, string'(","));
            write(output_line, future_bit2);
            writeline(output_file, output_line);
        end loop;
        
        enable <= '0';
        wait for clk_period * 5;
        
        -- Calculate correlation coefficients
        correlation_f1 := real(same_as_current_f1) / real(total_samples);
        correlation_f2 := real(same_as_current_f2) / real(total_samples);
        correlation_f1f2 := real(same_f1_f2) / real(total_samples);
        
        -- Report results
        report "======================================";
        report "PSF Performance Analysis (10 cycles)";
        report "======================================";
        report "";
        report "Toggle Rate Analysis:";
        report "  Current bit toggles: " & integer'image(toggle_current) & 
               " (" & integer'image((toggle_current * 100) / 10) & "%)";
        report "  Future bit 1 toggles: " & integer'image(toggle_future1) & 
               " (" & integer'image((toggle_future1 * 100) / 10) & "%)";
        report "  Future bit 2 toggles: " & integer'image(toggle_future2) & 
               " (" & integer'image((toggle_future2 * 100) / 10) & "%)";
        report "  Expected: ~50% for pseudo-random";
        report "";
        report "Decorrelation Analysis:";
        report "  Current vs Future1 similarity: " & 
               integer'image(integer(correlation_f1 * 100.0)) & "%";
        report "  Current vs Future2 similarity: " & 
               integer'image(integer(correlation_f2 * 100.0)) & "%";
        report "  Future1 vs Future2 similarity: " & 
               integer'image(integer(correlation_f1f2 * 100.0)) & "%";
        report "  Ideal: ~50% (perfectly decorrelated)";
        report "";
        
        if correlation_f1 > 0.45 and correlation_f1 < 0.55 then
            report "Current vs Future1: Good decorrelation!";
        else
            report "Current vs Future1: Poor decorrelation!";
        end if;
        
        if correlation_f2 > 0.45 and correlation_f2 < 0.55 then
            report "Current vs Future2: Good decorrelation!";
        else
            report "Current vs Future2: Poor decorrelation!";
        end if;
        
        if correlation_f1f2 > 0.45 and correlation_f1f2 < 0.55 then
            report "Future1 vs Future2: Good decorrelation!";
        else
            report "Future1 vs Future2: Poor decorrelation!";
        end if;
        
        report "======================================";
        report "PSF Test Completed!";
        report "Output written to: psf_output.txt";
        report "======================================";
        
        file_close(output_file);
        test_done <= true;
        wait;
        
    end process;

end Behavioral;