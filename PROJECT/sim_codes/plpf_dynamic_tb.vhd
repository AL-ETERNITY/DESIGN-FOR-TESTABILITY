----------------------------------------------------------------------------------
-- Testbench for Dynamic PLPF with Basic Control
-- Tests flexible toggle rate control with α, β, γ parameters
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity plpf_dynamic_tb is
end plpf_dynamic_tb;

architecture Behavioral of plpf_dynamic_tb is

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
    
    component plpf_dynamic
        Generic (
            SCAN_CHAIN_LENGTH : integer := 32
        );
        Port (
            clk          : in  STD_LOGIC;
            reset        : in  STD_LOGIC;
            enable       : in  STD_LOGIC;
            current_bit  : in  STD_LOGIC;
            future_bit1  : in  STD_LOGIC;
            future_bit2  : in  STD_LOGIC;
            past_bit     : in  STD_LOGIC;
            alpha        : in  integer range 0 to 255;
            beta         : in  integer range 0 to 255;
            gamma        : in  integer range 0 to 255;
            scan_counter : in  integer range 0 to 255;
            plpf_out     : out STD_LOGIC
        );
    end component;
    
    -- Testbench signals
    constant SCAN_LEN : integer := 32;
    
    signal clk         : STD_LOGIC := '0';
    signal reset       : STD_LOGIC := '0';
    signal enable      : STD_LOGIC := '0';
    signal seed        : STD_LOGIC_VECTOR(31 downto 0) := X"AAAAAAAA";
    signal load_seed   : STD_LOGIC := '0';
    signal lfsr_out    : STD_LOGIC_VECTOR(31 downto 0);
    signal serial_out  : STD_LOGIC;
    
    signal current_bit : STD_LOGIC;
    signal future_bit1 : STD_LOGIC;
    signal future_bit2 : STD_LOGIC;
    
    signal past_bit    : STD_LOGIC := '0';
    signal plpf_out    : STD_LOGIC;
    
    -- Dynamic control parameters
    signal alpha        : integer range 0 to 255 := 10;
    signal beta         : integer range 0 to 255 := 12;
    signal gamma        : integer range 0 to 255 := 10;
    signal scan_counter : integer range 0 to 255 := 0;
    
    -- Clock and control
    constant clk_period : time := 10 ns;
    signal sim_done     : boolean := false;
    
    -- Measurements
    signal toggle_count : integer := 0;
    signal prev_bit     : STD_LOGIC := '0';
    signal pattern_count : integer := 0;
    signal count_reset  : STD_LOGIC := '0';  -- Control signal for resetting counter

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
    
    -- Instantiate Dynamic PLPF
    plpf_inst: plpf_dynamic
        generic map (
            SCAN_CHAIN_LENGTH => SCAN_LEN
        )
        port map (
            clk          => clk,
            reset        => reset,
            enable       => enable,
            current_bit  => current_bit,
            future_bit1  => future_bit1,
            future_bit2  => future_bit2,
            past_bit     => past_bit,
            alpha        => alpha,
            beta         => beta,
            gamma        => gamma,
            scan_counter => scan_counter,
            plpf_out     => plpf_out
        );

    -- Clock generation
    clk_process: process
    begin
        while not sim_done loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

    -- Scan counter management
    counter_process: process(clk, reset)
    begin
        if reset = '1' then
            scan_counter <= 0;
        elsif rising_edge(clk) then
            if enable = '1' then
                if scan_counter = SCAN_LEN - 1 then
                    scan_counter <= 0;  -- Reset for next pattern
                else
                    scan_counter <= scan_counter + 1;
                end if;
            end if;
        end if;
    end process;

    -- Simulate scan chain feedback
    feedback_process: process(clk, reset)
    begin
        if reset = '1' then
            past_bit <= '0';
        elsif rising_edge(clk) then
            if enable = '1' then
                past_bit <= plpf_out;
            end if;
        end if;
    end process;

    -- Toggle counting
    toggle_process: process(clk)
    begin
        if rising_edge(clk) then
            if count_reset = '1' then
                toggle_count <= 0;
                prev_bit <= '0';
            elsif enable = '1' then
                if plpf_out /= prev_bit then
                    toggle_count <= toggle_count + 1;
                end if;
                prev_bit <= plpf_out;
            end if;
        end if;
    end process;

    -- Pattern counter
    pattern_counter: process(clk)
    begin
        if rising_edge(clk) then
            if enable = '1' and scan_counter = 0 then
                pattern_count <= pattern_count + 1;
            end if;
        end if;
    end process;

    -- Stimulus
    stim_proc: process
        variable toggle_rate : real;
        variable total_bits  : integer;
    begin
        
        report "========================================";
        report "Dynamic PLPF Testbench";
        report "========================================";
        
        -- Reset
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period;
        
        -- Load seed
        load_seed <= '1';
        wait for clk_period;
        load_seed <= '0';
        wait for clk_period;
        
        -- Test Configuration 1: Target ~15% toggle
        report "";
        report "Test 1: α=10, β=12, γ=10 (Target ~15%)";
        alpha <= 10;
        beta  <= 12;
        gamma <= 10;
        
        count_reset <= '1';
        wait for clk_period;
        count_reset <= '0';
        
        enable <= '1';
        wait for clk_period * (SCAN_LEN * 100);  -- 100 patterns
        enable <= '0';
        
        total_bits := SCAN_LEN * 100;
        toggle_rate := real(toggle_count) / real(total_bits) * 100.0;
        
        report "Configuration: α=" & integer'image(alpha) & 
               ", β=" & integer'image(beta) & 
               ", γ=" & integer'image(gamma);
        report "Total bits: " & integer'image(total_bits);
        report "Toggles: " & integer'image(toggle_count);
        report "Toggle rate: " & integer'image(integer(toggle_rate)) & "%";
        report "Expected: ~15%";
        
        wait for clk_period * 10;
        
        -- Test Configuration 2: Target ~25% toggle
        report "";
        report "Test 2: α=14, β=4, γ=14 (Target ~7%)";
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        load_seed <= '1';
        wait for clk_period;
        load_seed <= '0';
        
        alpha <= 14;
        beta  <= 4;
        gamma <= 14;
        
        count_reset <= '1';
        wait for clk_period;
        count_reset <= '0';
        
        enable <= '1';
        wait for clk_period * (SCAN_LEN * 100);
        enable <= '0';
        
        toggle_rate := real(toggle_count) / real(total_bits) * 100.0;
        
        report "Configuration: α=" & integer'image(alpha) & 
               ", β=" & integer'image(beta) & 
               ", γ=" & integer'image(gamma);
        report "Total bits: " & integer'image(total_bits);
        report "Toggles: " & integer'image(toggle_count);
        report "Toggle rate: " & integer'image(integer(toggle_rate)) & "%";
        report "Expected: ~12.5%";
        
        report "========================================";
        report "Dynamic PLPF Tests Complete!";
        report "========================================";
        
        sim_done <= true;
        wait;
        
    end process;

end Behavioral;