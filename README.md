# ASIC-DFT-and-ATPG-Using-Cadence-Modus
Implemented scan-based DFT by inserting scan flip-flops (SFFs), creating scan chains, and integrating test control signals using Cadence Genus and Modus tools. Worked on JTAG (IEEE 1149.1) test architecture and module integration to support boundary-scan testing, along with improving controllability and observability for effective fault testing

# 8-Bit Up/Down Counter — DFT Scan Insertion & ATPG

## Overview

This project implements an **8-bit synchronous up/down counter** using Verilog HDL and demonstrates the ASIC Design-for-Testability (DFT) flow using Cadence Genus and Cadence Modus.

The design supports asynchronous active-low reset and selectable up/down counting. The workflow includes RTL simulation, logic synthesis, scan-chain insertion, DFT verification, fault-model construction, and Automatic Test Pattern Generation (ATPG).

## Design Specifications

| Parameter | Description |
|---|---|
| Design | 8-Bit Up/Down Counter |
| HDL | Verilog |
| Counter Width | 8 bits |
| Clock Edge | Positive edge |
| Reset | Asynchronous, active-low |
| Control Signal | `m` |
| `m = 1` | Increment counter |
| `m = 0` | Decrement counter |
| Synthesis Tool | Cadence Genus 21.14 |
| ATPG Tool | Cadence Modus |
| Standard-Cell Library | GSCLib045 SVT |
| Timing Corner | Slow, 1.0 V |
| DFT Technique | Multiplexed Scan |
| Test Mode | FULLSCAN |

## RTL Design

The counter is implemented in `counter.v`.

```verilog
`timescale 1ns / 1ns

module counter(clk, m, rst, count);

input clk, m, rst;
output reg [7:0] count;

always @(posedge clk or negedge rst)
begin
    if (!rst)
        count = 0;
    else if (m)
        count = count + 1;
    else
        count = count - 1;
end

endmodule
```

### Functionality

- **Reset:** When `rst = 0`, the counter resets asynchronously to zero.
- **Up-counting:** When `m = 1`, the counter increments on each rising clock edge.
- **Down-counting:** When `m = 0`, the counter decrements on each rising clock edge.
- **Overflow and underflow:** The 8-bit counter wraps around modulo 256.

## Testbench

The testbench is implemented in `counter_test.v`.

### Testbench Features

- Generates a clock with a 10 ns period.
- Applies an active-low reset and releases it after 5 ns.
- Changes the counting direction control to `m = 0` at 160 ns.
- Monitors `clk`, `rst`, `m`, and `count` using `$monitor`.
- Terminates simulation at 320 ns.

> **Note:** Initialize `m` explicitly at the beginning of the testbench to prevent unknown values during the initial simulation interval.

## ASIC Design and DFT Flow

The project follows the flow below:

```text
RTL Design (Verilog)
        |
        v
Functional Simulation
        |
        v
Library and SDC Setup
        |
        v
RTL Elaboration
        |
        v
Logic Synthesis (Genus)
        |
        v
DFT Rule Checking
        |
        v
Scan Chain Definition and Insertion
        |
        v
Scan Connectivity Verification
        |
        v
Scan-Inserted Gate-Level Netlist
        |
        v
Modus Test Model Construction
        |
        v
Fault Model Construction
        |
        v
ATPG Pattern Generation
        |
        v
Verilog Test Vector Generation
        |
        v
Fault Coverage Analysis
```

## 1. RTL Synthesis Using Cadence Genus

Cadence Genus is used to elaborate and synthesize the RTL design into a gate-level netlist.

### Main Steps

1. Load the standard-cell timing library.
2. Read and elaborate the Verilog RTL.
3. Apply timing constraints using the SDC file.
4. Configure the DFT scan style.
5. Perform generic synthesis, technology mapping, and optimization.
6. Check DFT rules and configure the scan chain.
7. Insert scan connectivity and perform incremental optimization.
8. Generate the scan-enabled netlist and supporting reports.

### Key Commands

```tcl
read_libs slow_vdd1v0_basicCells.lib

read_hdl counter.v
elaborate
read_sdc ./constraints_top.sdc

set_db dft_scan_style muxed_scan
set_db dft_prefix dft_

define_shift_enable -name SE -active high -create_port SE

check_dft_rules

syn_generic
syn_map
syn_opt

define_scan_chain -name top_chain \
    -sdi scan_in \
    -sdo scan_out \
    -create_ports

connect_scan_chains -auto_create_chains
syn_opt -incr

report_scan_chains
```

The complete synthesis script also configures optimization effort, performs additional DFT checks, and exports the output files.

## 2. Scan Chain Insertion

Scan insertion improves controllability and observability of internal sequential elements during manufacturing test.

### Scan Configuration

| Parameter | Value |
|---|---|
| Scan Style | Multiplexed Scan |
| Scan Enable | `SE` |
| Scan Enable Polarity | Active-high |
| Scan Input | `scan_in` |
| Scan Output | `scan_out` |
| Scan Chain | `top_chain` |

The scan chain is defined and connected in Genus. Scan connectivity and DFT rule reports are then reviewed before generating the scan-enabled netlist.

## 3. Automatic Test Pattern Generation Using Cadence Modus

Cadence Modus is used to generate test patterns for the scan-inserted design.

### ATPG Workflow

1. **Build Logic Model:** Load the scan-enabled gate-level netlist and standard-cell Verilog models.
2. **Build Test Mode:** Configure the `FULLSCAN` test mode using the pin-assignment file.
3. **Report Test Structures:** Review scan-chain and test-structure information.
4. **Verify Test Structures:** Validate the configured scan architecture.
5. **Build Fault Model:** Construct the supported fault model.
6. **Generate ATPG Patterns:** Execute the `counter_atpg` experiment.
7. **Analyze Switching Activity:** Generate scan and capture toggle information.
8. **Write Test Vectors:** Export parallel-format Verilog test patterns.
9. **Commit Tests:** Save the completed ATPG experiment.


## 4. Fault Model

The Modus script uses:

```tcl
build_faultmodel -includedynamic no
```

This configures fault-model construction with dynamic faults excluded. The actual fault types, supported fault population, and ATPG coverage depend on the design, library, and Modus configuration.

## Generated Outputs

| Output File | Description |
|---|---|
| `counter_netlist_dft.v` | Scan-inserted gate-level Verilog netlist |
| `counter_sdc_dft.sdc` | SDC constraints for the DFT design |
| `counter_scanDEF.scandef` | Scan-chain connectivity information |
| `dft_delays.sdf` | Timing-delay annotation file |
| Scan-chain reports | Scan connectivity and DFT verification results |
| Verilog test vectors | ATPG patterns for simulation and test use |
| Toggle reports | Scan and capture switching activity information |
| Modus logs | Test-model, fault-model, and ATPG execution results |

## Suggested Project Structure

```text
counter-dft-atpg/
├── rtl/
│   └── counter.v
├── testbench/
│   └── counter_test.v
├── constraints/
│   └── constraints_top.sdc
├── genus/
│   └── genus_dft.tcl
├── modus/
│   ├── counter_atpg.tcl
│   └── counter.FULLSCAN.pinassign
├── lib/
│   ├── slow_vdd1v0_basicCells.lib
│   └── slow_vdd1v0_basiccells.v
├── outputs/
│   ├── counter_netlist_dft.v
│   ├── counter_sdc_dft.sdc
│   ├── counter_scanDEF.scandef
│   └── dft_delays.sdf
└── README.md
```

*The directory structure is illustrative and should be adjusted to match the actual repository.*

## Validation Checklist

- [ ] Verify up-counting and down-counting in RTL simulation.
- [ ] Verify asynchronous reset operation.
- [ ] Confirm timing constraints and library configuration.
- [ ] Complete synthesis and review the gate-level netlist.
- [ ] Resolve relevant DFT rule violations.
- [ ] Verify scan-chain connectivity.
- [ ] Verify the `FULLSCAN` test structures in Modus.
- [ ] Build the fault model successfully.
- [ ] Generate ATPG patterns.
- [ ] Review detected, undetected, and untestable faults.
- [ ] Record actual fault coverage from the Modus reports.
- [ ] Validate generated test vectors through simulation, if required.

## Key Learning Outcomes

- Verilog RTL design and functional verification.
- ASIC logic synthesis using Cadence Genus.
- Design-for-Testability (DFT) rule checking.
- Multiplexed scan-chain insertion.
- Scan architecture verification.
- Fault-model construction and ATPG pattern generation.
- Test-vector generation and switching-activity analysis.

## Conclusion

This project demonstrates an ASIC DFT workflow for an 8-bit up/down counter, integrating RTL design, synthesis, scan-chain insertion, and ATPG using Cadence Genus and Modus. It provides practical experience in preparing a digital design for structural test and evaluating its testability.

### Tools and Technologies

`Verilog HDL` · `Cadence Genus` · `Cadence Modus` · `ASIC Design` · `DFT` · `Scan Insertion` · `ATPG` · `SDC` · `Standard-Cell Libraries`
