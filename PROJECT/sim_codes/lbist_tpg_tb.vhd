----------------------------------------------------------------------------------
-- Simple Testbench for LBIST TPG with Dynamic PLPF
-- Tests one configuration at a time
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lbist_tpg_tb is
end lbist_tpg_tb;

architecture Behavioral of lbist_tpg_tb is

    -- Component Declaration
    component lbist_tpg
        Generic (
            SCAN_CHAIN_LENGTH : integer := 32
        );
        Port (
            clk                 : in  STD_LOGIC;
            reset               : in  STD_LOGIC;
            enable              : in  STD_LOGIC;
            seed                : in  STD_LOGIC_VECTOR(31 downto 0);
            load_seed           : in  STD_LOGIC;
            alpha               : in  integer range 0 to 255;
            beta                : in  integer range 0 to 255;
            gamma               : in  integer range 0 to 255;
            scan_in             : out STD_LOGIC;
            scan_chain_feedback : in  STD_LOGIC;
            lfsr_state          : out STD_LOGIC_VECTOR(31 downto 0);
            current_bit         : out STD_LOGIC;
            scan_counter_out    : out integer range 0 to 255;
            toggle_reduced      : out STD_LOGIC
        );
    end component;
    
    -- Constants
    constant SCAN_LEN : integer := 32;
    
    -- Testbench signals
    signal clk                 : STD_LOGIC := '0';
    signal reset               : STD_LOGIC := '0';
    signal enable              : STD_LOGIC := '0';
    signal seed                : STD_LOGIC_VECTOR(31 downto 0) := X"AAAAAAAA";
    signal load_seed           : STD_LOGIC := '0';
    signal alpha               : integer range 0 to 255 := 14;
    signal beta                : integer range 0 to 255 := 4;
    signal gamma               : integer range 0 to 255 := 14;
    signal scan_in             : STD_LOGIC;
    signal scan_chain_feedback : STD_LOGIC := '0';
    signal lfsr_state          : STD_LOGIC_VECTOR(31 downto 0);
    signal current_bit         : STD_LOGIC;
    signal scan_counter_out    : integer range 0 to 255;
    signal toggle_reduced      : STD_LOGIC;
    
    -- Simulate scan chain first flip-flop
    signal scan_chain_ff0 : STD_LOGIC := '0';
    
    -- Clock period
    constant clk_period : time := 10 ns;
    
    -- Toggle measurement
    signal toggle_count : integer := 0;
    signal prev_bit     : STD_LOGIC := '0';
    signal cycle_count  : integer := 0;
    signal count_reset  : STD_LOGIC := '0';
    
    -- Simulation control
    signal sim_done : boolean := false;

begin

    -- Instantiate DUT
    dut: lbist_tpg
        generic map (
            SCAN_CHAIN_LENGTH => SCAN_LEN
        )
        port map (
            clk                 => clk,
            reset               => reset,
            enable              => enable,
            seed                => seed,
            load_seed           => load_seed,
            alpha               => alpha,
            beta                => beta,
            gamma               => gamma,
            scan_in             => scan_in,
            scan_chain_feedback => scan_chain_feedback,
            lfsr_state          => lfsr_state,
            current_bit         => current_bit,
            scan_counter_out    => scan_counter_out,
            toggle_reduced      => toggle_reduced
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

    -- Simulate scan chain first flip-flop (provides feedback)
    scan_chain_ff_process: process(clk, reset)
    begin
        if reset = '1' then
            scan_chain_ff0 <= '0';
        elsif rising_edge(clk) then
            if enable = '1' then
                scan_chain_ff0 <= scan_in;
            end if;
        end if;
    end process;
    
    -- Connect feedback
    scan_chain_feedback <= scan_chain_ff0;

    -- Toggle counting
    count_process: process(clk)
    begin
        if rising_edge(clk) then
            if count_reset = '1' then
                toggle_count <= 0;
                prev_bit <= '0';
                cycle_count <= 0;
            elsif enable = '1' then
                if scan_in /= prev_bit then
                    toggle_count <= toggle_count + 1;
                end if;
                prev_bit <= scan_in;
                cycle_count <= cycle_count + 1;
            end if;
        end if;
    end process;

    -- Stimulus
    stim_process: process
        variable toggle_rate : real;
    begin
        
        report "========================================";
        report "LBIST TPG with Dynamic PLPF Test";
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
        
        -- Set configuration
        -- Change these values to test different toggle rates:
        alpha <= 14;  -- Tail length
        beta  <= 4;   -- Middle length  
        gamma <= 14;  -- Head length
        -- Expected: ~12-13% toggle rate
        
        report "Configuration: α=" & integer'image(alpha) & 
               ", β=" & integer'image(beta) & 
               ", γ=" & integer'image(gamma);
        
        -- Reset counter
        count_reset <= '1';
        wait for clk_period;
        count_reset <= '0';
        
        -- Enable and run
        enable <= '1';
        wait for clk_period * 100;  -- Warm-up
        
        count_reset <= '1';
        wait for clk_period;
        count_reset <= '0';
        
        wait for clk_period * 1000;  -- Measure for 1000 cycles
        enable <= '0';
        
        -- Calculate toggle rate
        wait for clk_period * 2;
        toggle_rate := real(toggle_count) / real(cycle_count) * 100.0;
        
        -- Report results
        report "========================================";
        report "Test Complete";
        report "========================================";
        report "Total cycles: " & integer'image(cycle_count);
        report "Total toggles: " & integer'image(toggle_count);
        report "Toggle rate: " & integer'image(integer(toggle_rate)) & "%";
        report "========================================";
        
        sim_done <= true;
        wait;
        
    end process;

end Behavioral;