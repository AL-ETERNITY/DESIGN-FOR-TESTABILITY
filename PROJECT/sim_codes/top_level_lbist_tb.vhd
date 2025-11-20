library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level_lbist_tb is
end top_level_lbist_tb;

architecture Behavioral of top_level_lbist_tb is

    -- Helper: convert std_logic_vector to hex string (MSB first)
    function slv_to_hex(slv : STD_LOGIC_VECTOR) return string is
        variable len       : integer := slv'length;
        variable nibbles   : integer := len / 4;
        variable res       : string(1 to nibbles);
        variable hi, lo    : integer;
        variable nib_val   : integer;
        variable nib_unsigned : unsigned(3 downto 0);
    begin
        -- assume slv'length is multiple of 4
        for k in 0 to nibbles - 1 loop
            -- select next nibble from MSB side
            if slv'left > slv'right then
                hi := slv'left - k*4;
                lo := hi - 3;
            else
                hi := slv'left + k*4;
                lo := hi + 3;
            end if;
            nib_unsigned := unsigned(slv(hi downto lo));
            nib_val := to_integer(nib_unsigned);
            if nib_val < 10 then
                -- '0' = 48
                res(k+1) := character'val(48 + nib_val);
            else
                -- 'A' = 65, nib_val 10 -> 'A' : 65 = 55 + 10
                res(k+1) := character'val(55 + nib_val);
            end if;
        end loop;
        return res;
    end function slv_to_hex;

    constant SCAN_LEN   : integer := 32;
    constant clk_period : time    := 10 ns;
    constant GOLDEN_SIG : STD_LOGIC_VECTOR(31 downto 0) := x"0DEDCBD9";
    
    signal clk         : STD_LOGIC := '0';
    signal reset       : STD_LOGIC := '0';
    signal test_enable : STD_LOGIC := '0';
    signal seed        : STD_LOGIC_VECTOR(31 downto 0) := X"AAAAAAAA";
    signal load_seed   : STD_LOGIC := '0';
    signal alpha       : integer range 0 to 255 := 14;
    signal beta        : integer range 0 to 255 := 4;
    signal gamma       : integer range 0 to 255 := 14;
    signal scan_enable : STD_LOGIC := '0';
    signal scan_out    : STD_LOGIC;
    signal debug_instruction : STD_LOGIC_VECTOR(31 downto 0);
    signal debug_mips_output : STD_LOGIC_VECTOR(31 downto 0);
    signal debug_mips_instr  : STD_LOGIC_VECTOR(31 downto 0);
    signal debug_scan_in     : STD_LOGIC;  -- TPG output for toggle measurement
    signal debug_signature   : STD_LOGIC_VECTOR(31 downto 0);
    
    signal toggle_count : integer := 0;
    signal prev_bit     : STD_LOGIC := '0';
    signal cycle_count  : integer := 0;
    signal count_reset  : STD_LOGIC := '0';
    
    signal sim_done : boolean := false;

begin

    dut: entity work.top_level_lbist(Behavioral)
        generic map (
            SCAN_CHAIN_LENGTH => SCAN_LEN
        )
        port map (
            clk         => clk,
            reset       => reset,
            test_enable => test_enable,
            seed        => seed,
            load_seed   => load_seed,
            alpha       => alpha,
            beta        => beta,
            gamma       => gamma,
            scan_enable => scan_enable,
            scan_out    => scan_out,
            debug_instruction => debug_instruction,
            debug_mips_output => debug_mips_output,
            debug_mips_instr  => debug_mips_instr,
            debug_scan_in     => debug_scan_in,
            debug_signature   => debug_signature
        );

    clk <= not clk after clk_period/2 when not sim_done else '0';

    -- ========================================================================
    -- CORRECTED Toggle Rate Measurement
    -- Measures transitions in scan_in (TPG output), not scan_out
    -- ========================================================================
    toggle_measure: process(clk)
    begin
        if rising_edge(clk) then
            if count_reset = '1' then
                toggle_count <= 0;
                prev_bit <= '0';
                cycle_count <= 0;
            elsif test_enable = '1' and scan_enable = '1' then
                -- Compare current scan_in with previous scan_in
                if debug_scan_in /= prev_bit then
                    toggle_count <= toggle_count + 1;
                end if;
                -- Update prev_bit to current scan_in value
                prev_bit <= debug_scan_in;
                cycle_count <= cycle_count + 1;
            end if;
        end if;
    end process;

    stim_proc: process
        variable instr_hex : string(1 to 8);
        variable output_hex : string(1 to 8);
    begin
        
        report "========================================";
        report "Starting LBIST Integration Test";
        report "========================================";
        report "";
        
        -- ====================================================================
        -- INITIALIZATION
        -- ====================================================================
        report "--- INITIALIZATION ---";
        reset <= '1';
        test_enable <= '0';
        scan_enable <= '1';
        
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period;
        report "Reset complete";
        report "";
        
        -- ====================================================================
        -- TEST 1: NORMAL MIPS OPERATION (test_enable = 0)
        -- ====================================================================
        report "========================================";
        report "TEST 1: NORMAL MIPS OPERATION";
        report "========================================";
        report "Configuration: test_enable=0, scan_enable=1 (from instr_mem)";
        report "MIPS executes instructions from instruction memory";
        
        report "";
        
        test_enable <= '0';
        scan_enable <= '1';
        
        -- Wait for pipeline to stabilize
        wait for clk_period * 3;
        
        -- Execute instructions and observe results
        -- The MIPS will naturally cycle through the instruction memory
        -- We'll observe for enough cycles to see the program execution
        
        for i in 0 to 50 loop
            wait for clk_period;
            
            -- Report instruction and output every cycle
            if i < 8 then
                -- First 8 cycles show the actual instructions being executed
                report "Cycle " & integer'image(i) & ": " &
                       "Instruction = 0x" & slv_to_hex(debug_instruction) & 
                       " | MIPS Output = 0x" & slv_to_hex(debug_mips_output);
            elsif i = 8 then
                report "... (continuing execution, branch detected) ...";
            elsif i > 45 then
                -- Show last few cycles
                report "Cycle " & integer'image(i) & ": " &
                       "Instruction = 0x" & slv_to_hex(debug_instruction) & 
                       " | MIPS Output = 0x" & slv_to_hex(debug_mips_output);
            end if;
        end loop;
        
        report "";
        report "Normal MIPS operation test complete";
        report "Expected behavior:";
        report "  - Instructions executed from instruction memory";
        report "  - Program loops back to start due to BEQ instruction";
        report "  - ALU operations produce correct results";
        report "";
        
        -- ====================================================================
        -- TEST 2: LBIST TEST MODE - SINGLE PATTERN
        -- ====================================================================
        report "========================================";
        report "TEST 2: LBIST TEST MODE - SINGLE PATTERN";
        report "========================================";
        
        -- Load seed first
        load_seed <= '1';
        wait for clk_period;
        load_seed <= '0';
        wait for clk_period;
        report "LFSR seed loaded: 0x" & slv_to_hex(seed);
        report "";
        
        test_enable <= '1';
        scan_enable <= '1';
        
        count_reset <= '1';
        wait for clk_period;
        count_reset <= '0';
        
        report "  Phase 1: Scan-in (32 cycles)";
        report "  Shifting test pattern from TPG into scan chain...";
        for i in 1 to 32 loop
            wait for clk_period;
            if i = 1 or i = 8 or i = 16 or i = 24 or i = 32 then
                report "    Cycle " & integer'image(i) & ": scan_in = " & 
                       std_logic'image(debug_scan_in);
            end if;
        end loop;
        
        wait for clk_period;
        report "  Instruction loaded in scan chain: 0x" & slv_to_hex(debug_instruction);
        report "";
        
        report "  Phase 2: Capture (scan_enable=0 for one clock)";
        report "  MIPS executes the scanned instruction and ALU result is captured...";
        scan_enable <= '0';
        wait for clk_period;
        report "  Executed MIPS Instr at capture: 0x" & slv_to_hex(debug_mips_instr);
        report "  Captured MIPS Output (ALU Result): 0x" & slv_to_hex(debug_mips_output);
        report "";
        
        report "  Phase 3: Scan-out (32 cycles)";
        report "  Shifting captured response out...";
        scan_enable <= '1';
        
        for i in 1 to 32 loop
            wait for clk_period;
            if i = 1 or i = 8 or i = 16 or i = 24 or i = 32 then
                report "    Cycle " & integer'image(i) & ": scan_out = " & 
                       std_logic'image(scan_out);
            end if;
        end loop;
        report "";
        
        -- ====================================================================
        -- TEST 3: MULTIPLE PATTERNS WITH TOGGLE MEASUREMENT
        -- ====================================================================
        report "========================================";
        report "TEST 3: MULTIPLE LBIST PATTERNS";
        report "========================================";
        
        count_reset <= '1';
        wait for clk_period;
        count_reset <= '0';
        
        for pattern in 1 to 5 loop
            report "--- Pattern " & integer'image(pattern) & " ---";
            
            -- Scan-in
            scan_enable <= '1';
            for i in 1 to 32 loop
                wait for clk_period;
            end loop;
            
            wait for clk_period;
            report "  Instruction: 0x" & slv_to_hex(debug_instruction);
            
            -- Capture for one clock with scan_enable=0
            scan_enable <= '0';
            wait for clk_period;
            report "  Executed MIPS Instr at capture: 0x" & slv_to_hex(debug_mips_instr);
            report "  ALU Result (captured): 0x" & slv_to_hex(debug_mips_output);
            
            -- Scan-out
            scan_enable <= '1';
            
            for i in 1 to 32 loop
                wait for clk_period;
            end loop;
            report "";
        end loop;
        
        wait for clk_period * 2;
        
        -- ====================================================================
        -- TOGGLE RATE ANALYSIS (CORRECTED)
        -- ====================================================================
        report "========================================";
        report "TOGGLE RATE ANALYSIS (PLPF)";
        report "========================================";
        report "Configuration: α=" & integer'image(alpha) & 
               ", β=" & integer'image(beta) & 
               ", γ=" & integer'image(gamma);
        report "Measurement: TPG scan_in transitions";
        report "Total cycles measured: " & integer'image(cycle_count);
        report "Total toggles detected: " & integer'image(toggle_count);
        if cycle_count > 1 then
            -- Note: cycle_count-1 because first cycle has no previous bit to compare
            report "Toggle rate: " & integer'image((toggle_count * 100) / (cycle_count - 1)) & "%";
            report "Expected: ~12-13% for α=14, β=4, γ=14";
            report "";
            report "Final MISR Signature (scan_out compressed): 0x" & slv_to_hex(debug_signature);
            assert debug_signature = GOLDEN_SIG
                report "LBIST signature mismatch! Expected 0x0DEDCBD9, got 0x" & slv_to_hex(debug_signature)
                severity error;
            report "";
            report "Interpretation:";
            report "  - Toggle rate measures scan_in bit transitions";
            report "  - PLPF reduces toggles to control switching power";
            report "  - Lower toggle rate = lower power consumption";
        end if;
        report "";
        
        report "========================================";
        report "ALL TESTS COMPLETE";
        report "========================================";
        
        sim_done <= true;
        wait;
        
    end process;

end Behavioral;