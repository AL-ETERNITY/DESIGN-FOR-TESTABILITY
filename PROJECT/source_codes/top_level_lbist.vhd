library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level_lbist is
    Generic (
        SCAN_CHAIN_LENGTH : integer := 32
    );
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        test_enable : in  STD_LOGIC;
        seed        : in  STD_LOGIC_VECTOR(31 downto 0);
        load_seed   : in  STD_LOGIC;
        alpha       : in  integer range 0 to 255;
        beta        : in  integer range 0 to 255;
        gamma       : in  integer range 0 to 255;
        scan_enable : in  STD_LOGIC;
        scan_out    : out STD_LOGIC;
        debug_instruction : out STD_LOGIC_VECTOR(31 downto 0);
        debug_mips_output : out STD_LOGIC_VECTOR(31 downto 0);
        debug_mips_instr  : out STD_LOGIC_VECTOR(31 downto 0);
        debug_scan_in     : out STD_LOGIC;
        debug_signature   : out STD_LOGIC_VECTOR(31 downto 0)
    );
end top_level_lbist;

architecture Behavioral of top_level_lbist is

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
    
    component scan_chain
        Generic (
            CHAIN_LENGTH : integer := 32
        );
        Port (
            clk              : in  STD_LOGIC;
            reset            : in  STD_LOGIC;
            scan_enable      : in  STD_LOGIC;
            scan_in          : in  STD_LOGIC;
            scan_out         : out STD_LOGIC;
            mips_instruction : out STD_LOGIC_VECTOR(31 downto 0);
            mips_output      : in  STD_LOGIC_VECTOR(31 downto 0);
            first_ff_out     : out STD_LOGIC
        );
    end component;
    
    component single_cycle
        Port (
            clk              : in  STD_LOGIC;
            reset            : in  STD_LOGIC;
            scan_enable      : in  STD_LOGIC;
            scan_instruction : in  STD_LOGIC_VECTOR(31 downto 0);
            instr            : buffer STD_LOGIC_VECTOR(31 downto 0);
            mips_output      : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;
    
    component misr
        Port (
            clk       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            enable    : in  STD_LOGIC;
            data_in   : in  STD_LOGIC;
            signature : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component;

    signal tpg_scan_in       : STD_LOGIC;
    signal scan_chain_out    : STD_LOGIC;
    signal first_ff_feedback : STD_LOGIC;
    signal scan_instruction  : STD_LOGIC_VECTOR(31 downto 0);
    signal mips_result       : STD_LOGIC_VECTOR(31 downto 0);
    signal current_instr     : STD_LOGIC_VECTOR(31 downto 0);
    signal misr_signature    : STD_LOGIC_VECTOR(31 downto 0);

begin

    lbist_tpg_inst: lbist_tpg
        generic map (
            SCAN_CHAIN_LENGTH => SCAN_CHAIN_LENGTH
        )
        port map (
            clk                 => clk,
            reset               => reset,
            enable              => test_enable,
            seed                => seed,
            load_seed           => load_seed,
            alpha               => alpha,
            beta                => beta,
            gamma               => gamma,
            scan_in             => tpg_scan_in,
            scan_chain_feedback => first_ff_feedback,
            lfsr_state          => open,
            current_bit         => open,
            scan_counter_out    => open,
            toggle_reduced      => open
        );
    
    scan_chain_inst: scan_chain
        generic map (
            CHAIN_LENGTH => SCAN_CHAIN_LENGTH
        )
        port map (
            clk              => clk,
            reset            => reset,
            scan_enable      => scan_enable,
            scan_in          => tpg_scan_in,
            scan_out         => scan_chain_out,
            mips_instruction => scan_instruction,
            mips_output      => mips_result,
            first_ff_out     => first_ff_feedback
        );

    mips_processor: single_cycle
        port map (
            clk              => clk,
            reset            => reset,
            scan_enable      => scan_enable,
            scan_instruction => scan_instruction,
            instr            => current_instr,
            mips_output      => mips_result
        );

    misr_inst: misr
        port map (
            clk       => clk,
            reset     => reset,
            enable    => test_enable and scan_enable,
            data_in   => scan_chain_out,
            signature => misr_signature
        );
    
    scan_out <= scan_chain_out;
    debug_instruction <= scan_instruction;
    debug_mips_output <= mips_result;
    debug_mips_instr  <= current_instr;
    debug_scan_in <= tpg_scan_in;
    debug_signature <= misr_signature;

end Behavioral;