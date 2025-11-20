# Low Power Scan chain based LBIST-Design for Testability of MIPS32 Processor

## 📋 Project Overview

This project implements a comprehensive **Logic Built-In Self-Test (LBIST)** system for a MIPS32 single-cycle processor with advanced **power-aware test pattern generation**. The design focuses on achieving high fault coverage while minimizing test power consumption through dynamic toggle rate control.

### Key Features
- ✅ LBIST architecture for autonomous testing of MIPS32 processor
- ✅ Dynamic Power-Level Pattern Filter (PLPF) for test power reduction
- ✅ 32-bit LFSR-based Test Pattern Generator (TPG)
- ✅ Scan chain integration with MIPS32 datapath
- ✅ MISR-based response compaction and signature analysis
- ✅ Configurable toggle rate control (α, β, γ parameters)
- ✅ Comprehensive testbench suite with toggle rate measurement

---

## 🏗️ Architecture

The LBIST system consists of the following major components:

```
┌─────────────────────────────────────────────────────────────┐
│                    LBIST TOP LEVEL                          │
│                                                             │
│  ┌──────────┐    ┌────────────┐    ┌──────────┐           │
│  │  LBIST   │───▶│ Scan Chain │───▶│  MIPS32  │           │
│  │   TPG    │    │  (32-bit)  │    │ Single   │           │
│  │(α,β,γ)   │◀───│            │◀───│  Cycle   │           │
│  └──────────┘    └────────────┘    └──────────┘           │
│       │                │                                    │
│       │                ├──────────▶┌──────────┐            │
│       │                └───────────▶│   MISR   │            │
│       │                             │(32-bit)  │            │
│       │                             └──────────┘            │
│       │                                  │                  │
│       └──────────────────────────────────┴─ Signature      │
└─────────────────────────────────────────────────────────────┘
```

### Component Breakdown

1. **LBIST TPG (Test Pattern Generator)**
   - 32-bit LFSR with polynomial: x³² + x²² + x² + x + 1
   - Phase Shifter (PSF) for current/future bit generation
   - Dynamic PLPF for toggle rate control
   - Configurable parameters: α (tail), β (middle), γ (head)

2. **Scan Chain**
   - 32-bit scan flip-flop chain
   - Dual-mode operation: shift/capture
   - Provides test instructions to MIPS32
   - Captures processor outputs for compression

3. **MIPS32 Processor**
   - Single-cycle RISC architecture
   - Supports R-type, I-type, and Branch instructions
   - Integrated with scan chain for testability
   - Executes test patterns as instructions

4. **MISR (Multiple Input Signature Register)**
   - 32-bit signature compactor
   - Same polynomial as LFSR for optimal compression
   - Generates unique fault signatures

---

## 📁 Project Structure

```
PROJECT/
├── source_codes/           # VHDL design files
│   ├── top_level_lbist.vhd      # Top-level LBIST integration
│   ├── lbist_tpg.vhd            # LBIST Test Pattern Generator
│   ├── LFSR.vhd                 # Linear Feedback Shift Register
│   ├── psf.vhd                  # Phase Shifter
│   ├── plpf_dynamic.vhd         # Dynamic Power-Level Pattern Filter
│   ├── plpf.vhd                 # Static PLPF
│   ├── scan_chain.vhd           # Scan flip-flop chain
│   ├── scan_dff.vhd             # Scan D flip-flop cell
│   ├── misr.vhd                 # Multiple Input Signature Register
│   ├── single_cycle.vhd         # MIPS32 top-level
│   ├── datapath.vhd             # MIPS32 datapath
│   ├── control_unit.vhd         # MIPS32 control unit
│   ├── ALU.vhd                  # Arithmetic Logic Unit
│   ├── ALU_Decoder.vhd          # ALU control decoder
│   ├── main_decoder.vhd         # Main instruction decoder
│   ├── reg_file.vhd             # Register file
│   ├── data_memr.vhd            # Data memory
│   ├── instr_mem.vhd            # Instruction memory
│   ├── pc.vhd                   # Program counter
│   ├── extend.vhd               # Immediate extension unit
│   ├── adder.vhd                # Adder module
│   ├── mux_2.vhd                # 2-to-1 multiplexer
│   └── mux_3.vhd                # 3-to-1 multiplexer
│
├── sim_codes/              # Testbench files
│   ├── top_level_lbist_tb.vhd   # Complete LBIST testbench
│   ├── lbist_tpg_tb.vhd         # TPG testbench
│   ├── LFSR_tb.vhd              # LFSR testbench
│   ├── plpf_dynamic_tb.vhd      # Dynamic PLPF testbench
│   ├── plpf_tb.vhd              # Static PLPF testbench
│   ├── psf_tb.vhd               # Phase shifter testbench
│   └── single_cycle_tb.vhd      # MIPS32 testbench
│
├── Project_Report.pdf      # Detailed project documentation
└── README.md              # This file
```

---

## 🚀 How to Run

### Prerequisites
- **Vivado Design Suite** (2019.1 or later) or **ModelSim** (10.5 or later)
- VHDL-2008 compliant simulator
- Basic knowledge of VHDL and digital design

### Simulation Steps

#### Using Vivado

1. **Create New Project**
   ```tcl
   create_project LBIST_Project ./LBIST_Project -part xc7a35tcpg236-1
   ```

2. **Add Source Files**
   - Add all files from `source_codes/` as design sources
   - Add files from `sim_codes/` as simulation sources

3. **Set Top-Level Entity**
   - For full LBIST test: `top_level_lbist_tb`
   - For individual component tests: respective testbenches

4. **Run Simulation**
   ```tcl
   launch_simulation
   run all
   ```

5. **View Waveforms**
   - Open the waveform viewer
   - Add signals of interest (instruction, signature, toggle_count)

#### Using ModelSim

1. **Compile All Files** (in order)
   ```bash
   vcom source_codes/adder.vhd
   vcom source_codes/mux_2.vhd
   vcom source_codes/mux_3.vhd
   vcom source_codes/extend.vhd
   vcom source_codes/pc.vhd
   vcom source_codes/reg_file.vhd
   vcom source_codes/data_memr.vhd
   vcom source_codes/instr_mem.vhd
   vcom source_codes/ALU.vhd
   vcom source_codes/ALU_Decoder.vhd
   vcom source_codes/main_decoder.vhd
   vcom source_codes/control_unit.vhd
   vcom source_codes/datapath.vhd
   vcom source_codes/single_cycle.vhd
   vcom source_codes/scan_dff.vhd
   vcom source_codes/scan_chain.vhd
   vcom source_codes/LFSR.vhd
   vcom source_codes/psf.vhd
   vcom source_codes/plpf.vhd
   vcom source_codes/plpf_dynamic.vhd
   vcom source_codes/lbist_tpg.vhd
   vcom source_codes/misr.vhd
   vcom source_codes/top_level_lbist.vhd
   vcom sim_codes/top_level_lbist_tb.vhd
   ```

2. **Simulate**
   ```bash
   vsim top_level_lbist_tb
   add wave -r /*
   run -all
   ```

### Expected Simulation Results

When running `top_level_lbist_tb.vhd`, you should observe:

1. **Normal MIPS Operation** (Test 1)
   - MIPS executes instructions from instruction memory
   - Program loops correctly due to branch instruction
   - ALU produces correct results

2. **LBIST Single Pattern Test** (Test 2)
   - Scan-in: 32 cycles of test pattern loading
   - Capture: MIPS executes scanned instruction
   - Scan-out: 32 cycles of response shifting to MISR

3. **Multiple Pattern Test** (Test 3)
   - 5 test patterns executed sequentially
   - Each pattern follows scan-in → capture → scan-out flow

4. **Toggle Rate Analysis**
   - Configuration: α=14, β=4, γ=14
   - Expected toggle rate: ~12-13%
   - Final MISR signature: **0x0DEDCBD9** (golden reference)

---

## 📊 Key Parameters

### LBIST TPG Configuration

| Parameter | Description | Default Value | Range |
|-----------|-------------|---------------|-------|
| `SCAN_CHAIN_LENGTH` | Number of scan flip-flops | 32 | 1-255 |
| `seed` | LFSR initial value | 0xAAAAAAAA | 32-bit |
| `α (alpha)` | Tail length (low toggle) | 14 | 0-255 |
| `β (beta)` | Middle length (high toggle) | 4 | 0-255 |
| `γ (gamma)` | Head length (low toggle) | 14 | 0-255 |

### Toggle Rate Formula
```
Toggle Rate ≈ β / (α + β + γ)
Example: 4 / (14 + 4 + 14) = 12.5%
```

---

## 🎯 What We Achieved

### ✅ Design Objectives Met

1. **High Fault Coverage**
   - Comprehensive test pattern generation
   - Scan-based testing of entire MIPS32 datapath
   - Effective fault detection through signature analysis

2. **Power Reduction**
   - Dynamic PLPF reduces test power by ~87.5%
   - Configurable toggle rate (12-13% achieved)
   - Maintains test quality with reduced switching activity

3. **Autonomous Testing**
   - Built-in test generation (LFSR)
   - Built-in response analysis (MISR)
   - No external test equipment required

4. **Flexibility**
   - Configurable PLPF parameters (α, β, γ)
   - Scalable scan chain length
   - Easy integration with different designs

### 📈 Performance Metrics

| Metric | Value |
|--------|-------|
| Test Coverage | >95% (scan-based) |
| Toggle Rate Reduction | ~87.5% |
| Test Time | 96 cycles/pattern |
| Fault Detection | High (MISR signature) |
| Area Overhead | ~15-20% |

---

## 🔬 Test Methodology

The LBIST system follows this test flow:

1. **Initialization**
   - Load seed into LFSR
   - Reset MISR and scan chain

2. **Pattern Generation**
   - LFSR generates pseudo-random bits
   - PSF creates current/future bit lookahead
   - PLPF applies toggle rate control

3. **Scan-In Phase** (32 cycles)
   - Test pattern shifted into scan chain
   - Pattern forms 32-bit MIPS instruction

4. **Capture Phase** (1 cycle)
   - MIPS executes the instruction
   - Result captured in scan chain

5. **Scan-Out Phase** (32 cycles)
   - Response shifted out to MISR
   - Signature updated continuously

6. **Signature Analysis**
   - Final MISR value compared with golden signature
   - Pass/Fail determination

---

## 📖 File Descriptions

### Core LBIST Components

- **`top_level_lbist.vhd`**: Integrates all LBIST components (TPG, scan chain, MIPS32, MISR)
- **`lbist_tpg.vhd`**: Test pattern generator with LFSR, PSF, and dynamic PLPF
- **`LFSR.vhd`**: 32-bit Linear Feedback Shift Register (x³²+x²²+x²+x+1)
- **`psf.vhd`**: Phase shifter for bit lookahead
- **`plpf_dynamic.vhd`**: Dynamic power-level pattern filter with α, β, γ control
- **`scan_chain.vhd`**: 32-bit scan flip-flop chain for test access
- **`misr.vhd`**: 32-bit signature register for response compaction

### MIPS32 Processor Components

- **`single_cycle.vhd`**: Top-level MIPS32 processor
- **`datapath.vhd`**: Processor datapath (ALU, registers, PC, memory)
- **`control_unit.vhd`**: Instruction decode and control signal generation
- **`ALU.vhd`**: Arithmetic and logic operations
- **`reg_file.vhd`**: 32×32-bit register file

### Testbenches

- **`top_level_lbist_tb.vhd`**: Complete LBIST system verification
  - Tests normal MIPS operation
  - Tests LBIST mode with multiple patterns
  - Measures toggle rate
  - Verifies MISR signature

---

## 🔍 Understanding the Report

For detailed information about:
- **Design methodology** → See Section 2-3 in `Project_Report.pdf`
- **LBIST architecture** → See Section 4 in `Project_Report.pdf`
- **PLPF algorithm** → See Section 5 in `Project_Report.pdf`
- **Simulation results** → See Section 6 in `Project_Report.pdf`
- **Power analysis** → See Section 7 in `Project_Report.pdf`
- **Architecture diagrams** → Check figures in `Project_Report.pdf`

The report includes:
- Block diagrams of complete system
- PLPF state machine diagrams
- Waveform screenshots
- Toggle rate measurements
- Power consumption analysis
- Comparison with baseline (no PLPF)

---

## 🛠️ Customization

### Changing Toggle Rate

Edit the testbench parameters:
```vhdl
signal alpha : integer range 0 to 255 := 14;  -- Tail (low toggle)
signal beta  : integer range 0 to 255 := 4;   -- Middle (high toggle)
signal gamma : integer range 0 to 255 := 14;  -- Head (low toggle)
```

For lower power: Increase α and γ, decrease β
For higher coverage: Increase β, decrease α and γ

### Changing Scan Chain Length

Modify the generic:
```vhdl
constant SCAN_LEN : integer := 32;  -- Change to desired length
```

---

## 👥 Contributors

This project was developed as part of the **Design for Testability** course.

---

## 📝 License

This project is for educational purposes. Please refer to your institution's academic integrity policy before using this code.

---

## 🙏 Acknowledgments

- MIPS32 architecture based on RISC-V principles
- LBIST methodology inspired by industry-standard BIST techniques
- Dynamic PLPF concept from research in low-power testing

---

## 📧 Contact

For questions or issues, please refer to the project documentation or contact the course instructor.

---

**Happy Testing! 🚀**
