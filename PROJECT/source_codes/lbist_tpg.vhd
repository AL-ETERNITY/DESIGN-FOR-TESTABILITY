----------------------------------------------------------------------------------
-- LBIST TPG with Dynamic PLPF Integration
-- Supports flexible toggle rate control using α, β, γ parameters
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lbist_tpg is
    Generic (
        SCAN_CHAIN_LENGTH : integer := 32  -- Scan chain length
    );
    Port (
        -- System signals
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        enable      : in  STD_LOGIC;
        
        -- LFSR configuration
        seed        : in  STD_LOGIC_VECTOR(31 downto 0);
        load_seed   : in  STD_LOGIC;
        
        -- Dynamic PLPF power control parameters
        alpha       : in  integer range 0 to 255;  -- Tail length (low toggle)
        beta        : in  integer range 0 to 255;  -- Middle length (high toggle)
        gamma       : in  integer range 0 to 255;  -- Head length (low toggle)
        
        -- Scan chain interface
        scan_in     : out STD_LOGIC;                    -- Output to scan chain
        scan_chain_feedback : in STD_LOGIC;             -- Feedback from first scan FF
        
        -- Monitoring/debug outputs (optional)
        lfsr_state  : out STD_LOGIC_VECTOR(31 downto 0);
        current_bit : out STD_LOGIC;
        scan_counter_out : out integer range 0 to 255;  -- Current scan position
        toggle_reduced : out STD_LOGIC  -- Indicates PLPF is active
    );
end lbist_tpg;

architecture Behavioral of lbist_tpg is

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
    
    -- Internal signals
    signal lfsr_internal   : STD_LOGIC_VECTOR(31 downto 0);
    signal serial_internal : STD_LOGIC;
    
    signal current_internal : STD_LOGIC;
    signal future1_internal : STD_LOGIC;
    signal future2_internal : STD_LOGIC;
    
    signal plpf_out_internal : STD_LOGIC;
    
    -- Scan counter for dynamic PLPF control
    signal scan_counter : integer range 0 to 255 := 0;

begin

    -- ========================================================================
    -- LFSR: Pseudo-random pattern generation
    -- ========================================================================
    lfsr_inst: LFSR
        port map (
            clk       => clk,
            reset     => reset,
            enable    => enable,
            seed      => seed,
            load_seed => load_seed,
            lfsr_out  => lfsr_internal,
            serial_out=> serial_internal
        );
    
    -- ========================================================================
    -- PSF: Phase shifter to generate current and future bits
    -- ========================================================================
    psf_inst: psf
        port map (
            lfsr_state  => lfsr_internal,
            current_bit => current_internal,
            future_bit1 => future1_internal,
            future_bit2 => future2_internal
        );
    
    -- ========================================================================
    -- Dynamic PLPF: Power control filter with flexible toggle rate
    -- ========================================================================
    plpf_inst: plpf_dynamic
        generic map (
            SCAN_CHAIN_LENGTH => SCAN_CHAIN_LENGTH
        )
        port map (
            clk          => clk,
            reset        => reset,
            enable       => enable,
            current_bit  => current_internal,
            future_bit1  => future1_internal,
            future_bit2  => future2_internal,
            past_bit     => scan_chain_feedback,
            alpha        => alpha,
            beta         => beta,
            gamma        => gamma,
            scan_counter => scan_counter,
            plpf_out     => plpf_out_internal
        );
    
    -- ========================================================================
    -- Scan Counter Management
    -- Tracks current position in scan chain (0 to SCAN_CHAIN_LENGTH-1)
    -- Resets after each complete pattern
    -- ========================================================================
    scan_counter_process: process(clk, reset)
    begin
        if reset = '1' then
            scan_counter <= 0;
        elsif rising_edge(clk) then
            if enable = '1' then
                if scan_counter = SCAN_CHAIN_LENGTH - 1 then
                    scan_counter <= 0;  -- Reset for next pattern
                else
                    scan_counter <= scan_counter + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- ========================================================================
    -- Output assignments
    -- ========================================================================
    scan_in <= plpf_out_internal;
    
    -- Debug/monitoring outputs
    lfsr_state <= lfsr_internal;
    current_bit <= current_internal;
    scan_counter_out <= scan_counter;
    toggle_reduced <= '1' when (alpha > 0 or gamma > 0) else '0';

end Behavioral;