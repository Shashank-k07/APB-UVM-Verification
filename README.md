# 🔧 UVM-Based Verification of an APB Slave Device

## 📖 Project Overview

This repository implements a **UVM (Universal Verification Methodology)** testbench to verify a **SystemVerilog RTL model of an APB (Advanced Peripheral Bus) slave device**. The project demonstrates a complete, minimal, class-based UVM environment — transaction, sequence, sequencer, driver, monitor, scoreboard, and functional coverage — built around a single-file compilation flow (`run.sv`) and simulated using **QuestaSim** with the **UVM 1.1c** library.

The Design Under Test (**DUT**) is a byte-addressable APB slave with a 1 KB internal memory that supports word-aligned read/write transactions with byte-strobe control and slave-error signaling for misaligned accesses.

---

## 🎯 Project Objectives

- Build a reusable, class-based UVM testbench for an APB slave.
- Model APB transactions using a UVM sequence item (`apb_trans`).
- Drive and sample the APB interface synchronously with the clock via a UVM driver and monitor.
- Independently predict expected DUT behavior and self-check it against actual DUT outputs using a scoreboard.
- Collect functional coverage on APB interface signals using a UVM subscriber-based covergroup.
- Demonstrate a working QuestaSim compile → optimize → simulate → coverage flow driven by a `run.do` script.

---

## 🚌 APB Protocol Overview

The **AMBA APB (Advanced Peripheral Bus)** protocol is a low-complexity, low-power bus used to connect peripheral devices in an SoC. Key concepts relevant to this project:

- **Two-phase transfer**: an APB transfer consists of a **SETUP phase** (`PSEL` asserted, `PENABLE` low) followed by an **ACCESS phase** (`PENABLE` asserted on the next clock edge), during which the actual data transfer completes.
- **PSEL** — selects the target slave.
- **PENABLE** — indicates the access (second) phase of the transfer.
- **PWRITE** — indicates transfer direction (`1` = write, `0` = read).
- **PSTRB** — byte-lane write strobes, introduced in **APB4**, allowing sub-word (byte-granular) writes.
- **PREADY** — asserted by the slave to indicate the transfer can complete; can be used to insert wait states.
- **PSLVERR** — optional slave error response indicating a failed transfer.

This project's interface (`apb_inf.sv`) implements the APB4 signal set, including `PSTRB`.

---

## 🏗️ Verification Architecture

The testbench follows a classic **UVM class-based architecture** with a single agent's worth of components (driver, sequencer, monitor) built directly inside the environment, plus a scoreboard and a coverage subscriber fed from the monitor.

### Architecture / Data-Flow Diagram

```
 apb_test
    │
    ├── creates & runs ──► apb_seq  (2 directed transactions)
    │                          │
    │                          ▼
    └── apb_env ──────► apb_sqr (sequencer)
            │                   │
            │                   ▼
            ├────────────► apb_driver ───► apb_inf (virtual interface) ───► apb_dut (RTL)
            │                                       ▲
            │                                       │ (signals sampled every clock)
            ├────────────► apb_mon  ◄───────────────┘
            │                   │
            │        (uvm_analysis_port: mon)
            │                   │
            │        ┌──────────┴───────────┐
            │        ▼                      ▼
            └──► apb_sco (scoreboard)   apb_cov (functional coverage)
```

### Data Flow

1. **`apb_seq`** generates `apb_trans` sequence items and sends them to the sequencer via `uvm_do_with`.
2. **`apb_sqr`** (a plain `uvm_sequencer#(apb_trans)`) arbitrates and forwards items to the driver.
3. **`apb_driver`** pulls each item with `get_next_item()`, drives the APB signals onto the virtual interface (`apb_inf`) synchronized to `pclk`, then samples the DUT's response (`pready`, `prdata`, `pslverr`) back into the same item and calls `item_done()`.
4. **`apb_dut`** (the RTL) reacts to the driven signals on the clock edge and performs the memory read/write.
5. **`apb_mon`** independently samples the same interface every clock edge, packages the observed values into an `apb_trans`, and broadcasts them through its `uvm_analysis_port`.
6. **`apb_sco`** and **`apb_cov`** both subscribe to the monitor's analysis port (fan-out connection) — the scoreboard checks correctness, and the coverage collector samples the covergroup.

---

## 🧩 UVM Testbench Components

| Component | File | Type | Responsibility |
|---|---|---|---|
| `apb_trans` | `apb_trans.sv` | `uvm_sequence_item` | APB transaction model: randomizable `paddr`, `pprot`, `psel`, `penable`, `pwrite`, `pwdata`, `pstrb`, plus response fields `pready`, `prdata`, `pslverr`. |
| `apb_seq` | `apb_seq.sv` | `uvm_sequence#(apb_trans)` | Generates the test stimulus — a directed write followed by a read (see [Testcases](#-testcases--test-scenarios)). |
| `apb_sqr` | `apb_sqr.sv` | `uvm_sequencer#(apb_trans)` | Default parameterized sequencer; arbitrates sequence items to the driver. No custom logic. |
| `apb_driver` | `apb_driver.sv` | `uvm_driver#(apb_trans)` | Drives sequence items onto the `apb_inf` virtual interface on `pclk` edges and captures the DUT's response back into the item. |
| `apb_mon` | `apb_mon.sv` | `uvm_monitor` | Passively samples the interface every clock edge and publishes observed transactions via a `uvm_analysis_port#(apb_trans)`. |
| `apb_sco` | `apb_sco.sv` | `uvm_scoreboard` | Receives monitored transactions through a `uvm_tlm_analysis_fifo`, computes expected results, and compares them to actual DUT outputs. |
| `apb_cov` | `apb_cov.sv` | `uvm_subscriber#(apb_trans)` | Samples a `covergroup` on every observed transaction to collect functional coverage. |
| `apb_env` | `apb_env.sv` | `uvm_env` | Instantiates and connects the sequencer, driver, monitor, scoreboard, and coverage collector. |
| `apb_test` | `apb_test.sv` | `uvm_test` | Builds the environment, creates and runs `apb_seq` on the sequencer, and manages the phase objection. |
| `apb_inf` | `apb_inf.sv` | `interface` | Bundles all APB signals (`paddr`, `pprot`, `psel`, `penable`, `pwrite`, `pwdata`, `pstrb`, `pready`, `prdata`, `pslverr`) parameterized by `pclk`/`presetn`. |
| `apb_top` | `apb_top.sv` | Top-level module | Generates clock/reset, instantiates the interface and DUT, registers the virtual interface in `uvm_config_db`, and calls `run_test("apb_test")`. |
| `apb_dut` | `apb_dut.sv` | RTL module | The Design Under Test — see below. |
| `run.sv` | `run.sv` | Compile wrapper | Single file that `` `include``s the UVM package and every source file above in the correct compile order. |

---

## 🖥️ DUT Description

**File:** `apb_dut.sv`

`apb_dut` is a synchronous APB **slave** with a **1 KB byte-addressable memory** (`reg [7:0] mem[1023:0]`). On every rising edge of `pclk`:

- If `psel` is **not** asserted → the DUT prints a message (`"Select the Slave in order for data transaction"`) and takes no action.
- If `psel` is asserted but `penable` is **not** asserted (setup phase) → the DUT prints `"PENABLE is 0 enable it to continue the operation"`.
- If both `psel` and `penable` are asserted (access phase):
  - If `paddr % 4 != 0` (**unaligned address**) → `pslverr` is asserted (`1'b1`) and a message (`"Address is unligned with data"`) is printed; no memory access occurs.
  - If `paddr % 4 == 0` (**word-aligned address**) → `pslverr` is deasserted and:
    - **Write (`pwrite == 1`)**: each of the 4 bytes of `pwdata` is written to `mem[paddr]`…`mem[paddr+3]`, gated individually by the corresponding bit of `pstrb`. A strobe bit of `0` writes `8'h00` to that byte lane.
    - **Read (`pwrite == 0`)**: all 4 bytes are read back from `mem[paddr]`…`mem[paddr+3]` into `prdata`.
  - `pready` is asserted whenever `psel` is high.

**Observed characteristics worth noting for a reviewer:**
- `presetn` and `pprot` are declared as module inputs but are **not referenced** anywhere in the DUT's logic — reset and protection-type checking are not implemented in the RTL.
- `pready` and `pslverr` are driven only inside conditional branches (no default/else assignment each cycle), so they can retain a stale value when `psel` is deasserted.
- On a strobe bit of `0` during a write, the DUT writes `0x00` to that byte rather than leaving the existing memory content untouched.

---

## 🔌 APB Interface Signals

**File:** `apb_inf.sv`

| Signal | Width | Direction (Master → Slave unless noted) | Description |
|---|---|---|---|
| `pclk` | 1 | Global | System clock, shared by interface and DUT. |
| `presetn` | 1 | Global | Active-low reset (declared on the interface/DUT port list; not consumed in DUT logic — see DUT notes above). |
| `paddr` | 32 | M → S | Transfer address. |
| `pprot` | 3 | M → S | Protection-type indicator (declared, not used in DUT logic). |
| `psel` | 1 | M → S | Slave select. |
| `penable` | 1 | M → S | Enable — distinguishes SETUP vs ACCESS phase. |
| `pwrite` | 1 | M → S | Transfer direction: `1` = write, `0` = read. |
| `pwdata` | 32 | M → S | Write data bus. |
| `pstrb` | 4 | M → S | Byte-lane write strobes (APB4). |
| `pready` | 1 | **S → M** | Slave-ready / wait-state indicator. |
| `prdata` | 32 | **S → M** | Read data bus. |
| `pslverr` | 1 | **S → M** | Slave error response. |

---

## 🧪 Testcases / Test Scenarios

**File:** `apb_seq.sv` — the sequence contains exactly **two directed transactions**, generated with `uvm_do_with`:

| # | Transaction | Constraints applied | Purpose |
|---|---|---|---|
| 1 | Write | `paddr == 32'h0000`, `psel == 1`, `penable == 1`, `pwrite == 1`, `pstrb == 4'hf` | Full-word (all 4 byte lanes enabled) write to address `0x0`. |
| 2 | Read | `paddr == 32'h0000`, `psel == 1`, `penable == 1`, `pwrite == 0` | Read-back from address `0x0` to confirm the previously written data. |

This sequence is run once by `apb_test` (`seq.start(env.sqr)`), so the testbench currently executes a **single write-then-read-back scenario at address `0x0`**.

### ✅ (a) Actually exercised by the current testbench
- Word-aligned write of all four bytes at address `0x0`.
- Word-aligned read-back at address `0x0`.

### ⚠️ (b) DUT functionality present in RTL but **not currently tested**
- **Unaligned-address error response** (`paddr % 4 != 0` → `pslverr`) — the DUT implements this, but no sequence item drives an unaligned address.
- **Partial byte-strobe writes** (`pstrb` values other than `4'hf`) — `pstrb` is a randomizable field, but only `4'hf` is constrained/used in the existing sequence.
- **Multiple/different addresses** — only address `0x0` is ever exercised; the rest of the 1 KB memory space is untested.
- **`psel`/`penable` deassertion behavior** (the "not selected" and "setup phase" `$display` branches in the DUT).
- **Reset (`presetn`) behavior** — not driven as part of any transaction and not used by the DUT.
- **Back-to-back / randomized traffic** — the testbench issues exactly two fixed transactions per run; there is no randomized or stress sequence.

---

## 🔄 Verification Flow

1. `apb_top` generates `pclk` (toggling every 5 time units) and a `presetn` pulse (low for 10 time units, then high).
2. `apb_top` instantiates `apb_inf` and `apb_dut`, wires them together, and registers the virtual interface handle in `uvm_config_db`.
3. `run_test("apb_test")` starts the UVM phasing.
4. `apb_test::build_phase` constructs `apb_env` (which in turn builds the sequencer, driver, monitor, scoreboard, and coverage collector, and connects them in `connect_phase`).
5. `apb_test::run_phase` raises an objection, creates `apb_seq`, and starts it on `env.sqr`.
6. The driver executes the two transactions against the DUT; the monitor observes the same activity and streams it to the scoreboard and coverage collector.
7. After the sequence completes, the test waits `#100` time units, then drops the objection, ending the run.

---

## ✅ Scoreboard / Checking Mechanism

**File:** `apb_sco.sv`

The scoreboard receives monitored transactions through a `uvm_tlm_analysis_fifo#(apb_trans)` and, for each transaction, independently **predicts** the expected DUT response:

```systemverilog
exp_pready  = (tx.psel == 1'b1) ? 1'b1 : 1'b0;
exp_pslverr = (tx.paddr % 4 == 0) ? 1'b0 : 1'b1;
// exp_prdata is built byte-by-byte from tx.pwdata, gated by tx.pstrb bits
```

It then compares the predicted values against the actual values captured by the monitor (`tx.pready`, `tx.pslverr`, `tx.prdata`) and prints a `SCOREBOARD PASS::` or `SCOREBOARD FAIL::` message via `$display`, showing both the expected and actual `prdata`, `pready`, and `pslverr`.

**Note for reviewers:** the current `PASS`/`FAIL` conditions each require **all three** fields to match (or **all three** to mismatch) simultaneously (`&&` in both branches). A partial mismatch (e.g., only `pslverr` differs) does not trigger either message — this is a known limitation of the current checking logic rather than an intended feature.

---

## 📊 Functional Coverage

**File:** `apb_cov.sv`

`apb_cov` extends `uvm_subscriber#(apb_trans)` and defines a single covergroup, `cg`, sampled once per observed transaction (inside the subscriber's `write()` callback):

| Coverpoint label | Signal covered |
|---|---|
| A | `paddr` |
| B | `pprot` |
| C | `psel` |
| D | `penable` |
| E | `pwrite` |
| F | `pwdata` |
| G | `pstrb` |
| H | `prdata` |
| I | `pready` |
| J | `pslverr` |

All ten coverpoints use **default automatic bins** (no explicit `bins` statements) and there are **no cross-coverage points**. Coverage is sampled on every transaction observed by the monitor — with only two transactions currently generated per run, coverage closure against these bins is expected to be very low.

---

## 🛠️ Simulation Environment

- **Simulator:** QuestaSim (Mentor/Siemens), invoked through `run.do`.
- **UVM version:** **UVM 1.1c**, referenced via `+incdir+C:/questasim64_10.7c/verilog_src/uvm-1.1c/src` and linked at simulation time via `-sv_lib C:/questasim64_10.7c/uvm-1.1c/win64/uvm_dpi`.
- **Compile wrapper:** `run.sv` — a single file that `` `include``s `uvm_pkg.sv`, imports `uvm_pkg::*`, and then `` `include``s every design/testbench source file in dependency order (DUT → interface → transaction → sequence → sequencer → driver → monitor → scoreboard → coverage → environment → test → top).
- **Simulation script:** `run.do` — drives the full compile/optimize/simulate/coverage flow (see below).

---

## ▶️ Running the Simulation

### Quick Run

Open **QuestaSim**, navigate to the project directory, and execute:

```tcl
do run.do
```

Run this command directly in the **QuestaSim Transcript window** (the interactive `vsim` console), with the current working directory set to the folder containing `run.sv` and `run.do`.

### Manual Compilation/Simulation

The steps below are the exact commands contained in `run.do`:

```tcl
# 1. Compile the design + testbench (single-file include wrapper), pointing to the UVM 1.1c library
vlog +incdir+C:/questasim64_10.7c/verilog_src/uvm-1.1c/src run.sv

# 2. Optimize the top module with functional coverage enabled (best coverage mode)
vopt work.apb_top +cover=fcbest -o apb

# 3. Launch simulation with coverage enabled, linking the UVM DPI shared library
vsim -coverage apb -sv_lib C:/questasim64_10.7c/uvm-1.1c/win64/uvm_dpi

# 4. Add all interface signals to the waveform viewer
add wave -position insertpoint sim:/apb_top/vif/*

# 5. Save functional coverage results on exit
coverage save -onexit run.ucdb

# 6. Run the simulation to completion
run -all
```

**Notes:**
- The **top module** is `apb_top` (`apb_top.sv`), and the UVM **test** is hardcoded via `run_test("apb_test")` inside `apb_top` (no `+UVM_TESTNAME` plusarg is used in `run.do`).
- The paths in `run.do` (`C:/questasim64_10.7c/...`) point to a specific local QuestaSim/UVM 1.1c installation — update these paths to match your own QuestaSim install directory if they differ.
- **Waveforms:** the `add wave` command loads every signal under the `apb_inf` instance (`sim:/apb_top/vif/*`) into the Wave window automatically when running interactively.
- **Coverage:** running `do run.do` produces a coverage database, `run.ucdb`, which can be opened in QuestaSim's coverage viewer (`vcover report run.ucdb` or via the GUI **Coverage** window) after the run completes.

---

## 🖨️ Expected Simulation Output

Based on the `$display` statements actually present in the source code, a simulation run should print:

- From `apb_dut.sv`, depending on the driven signals each cycle:
  - `"Select the Slave in order for data transaction"` (when `psel == 0`)
  - `"PENABLE is 0 enable it to continue the operation"` (when `psel == 1`, `penable == 0`)
  - `"Address is unligned with data"` (when an unaligned address is accessed — not exercised by the current sequence)
- From `apb_sco.sv`, for each completed transaction observed by the monitor:
  - A `SCOREBOARD PASS::` block listing expected vs. actual `prdata`, `pready`, `pslverr`, **or**
  - A `SCOREBOARD FAIL::` block with the same fields, if all three mismatch simultaneously.

No sample transcript/log file is included in this repository, so the exact console text from an actual run is not reproduced here.

---

## 📈 Results

No simulation log files, coverage reports, or waveform database files (`.ucdb`, `.wlf`, transcript, etc.) are included in this repository. The project provides the source code and simulation script needed to generate these artifacts, but actual PASS/FAIL counts and coverage percentages are **not available** in the uploaded project and are not fabricated here.

---

## 🗂️ Project File Structure

```
UVM_based_verification/
├── apb_trans.sv     # UVM sequence item — APB transaction model
├── apb_seq.sv       # UVM sequence — write + read directed stimulus
├── apb_sqr.sv       # UVM sequencer
├── apb_driver.sv    # UVM driver — drives apb_inf from sequence items
├── apb_mon.sv       # UVM monitor — samples apb_inf, publishes via analysis port
├── apb_sco.sv       # UVM scoreboard — predicts & checks expected vs. actual
├── apb_cov.sv       # UVM subscriber — functional coverage covergroup
├── apb_env.sv       # UVM environment — instantiates & connects all components
├── apb_test.sv      # UVM test — builds env, runs apb_seq
├── apb_inf.sv        # SystemVerilog interface — APB signal bundle
├── apb_dut.sv       # RTL — APB slave DUT (1 KB memory)
├── apb_top.sv       # Testbench top — clock/reset gen, DUT + interface wiring, run_test()
├── run.sv           # Single-file include wrapper (compile order for all sources)
└── run.do           # QuestaSim do-script: compile, optimize, simulate, coverage
```

---

## 🧰 Technologies & Tools Used

- **SystemVerilog** (RTL + testbench)
- **UVM 1.1c** (Universal Verification Methodology class library)
- **AMBA APB4** protocol (with `PSTRB` byte-strobe support)
- **QuestaSim** (Mentor/Siemens) — compilation, simulation, and functional coverage (`+cover=fcbest`, `vcover`/coverage database)

---

## 💡 Key Verification Concepts Demonstrated

- UVM component hierarchy: `uvm_test` → `uvm_env` → (`uvm_sequencer`, `uvm_driver`, `uvm_monitor`) plus `uvm_scoreboard` and `uvm_subscriber`.
- Virtual interface handling via `uvm_config_db#(virtual apb_inf)`.
- Constrained-random sequence items driven with directed constraints (`uvm_do_with`).
- Driver/monitor synchronization to a clocked interface.
- Analysis-port fan-out from a single monitor to multiple subscribers (scoreboard + coverage).
- Self-checking scoreboard using a `uvm_tlm_analysis_fifo`.
- Functional coverage collection via `uvm_subscriber` and a `covergroup`.
- Phase objections (`raise_objection` / `drop_objection`) to control simulation run length.

---

## ⚠️ Limitations / Current Scope

- Only **one test scenario** (single write + single read-back at address `0x0`) is implemented — no negative testing, no address sweep, no randomized/stress testing.
- The DUT's **unaligned-address error path** (`pslverr`) is implemented in RTL but never exercised by the current sequence.
- `presetn` and `pprot` are present on the interface/DUT ports but are **not functionally used** in the DUT logic.
- The scoreboard's `PASS`/`FAIL` conditions both use `&&` across all three checked fields, so a **partial mismatch** produces neither message (see [Scoreboard](#-scoreboard--checking-mechanism)).
- Coverage covergroup has **no cross-coverage** and relies entirely on default auto-bins.
- `pready`/`pslverr` in the DUT are not given a default value every cycle and can hold stale values when `psel` is low.
- Absolute Windows-specific paths to a local QuestaSim/UVM installation are hardcoded in `run.do`.
- No regression list, Makefile, or multi-test infrastructure (e.g., `+UVM_TESTNAME` plusarg usage) is present — the test is hardcoded in `apb_top.sv`.

---

## 🚀 Future Improvements

- Add sequences for unaligned-address accesses to exercise the `pslverr` path.
- Randomize `paddr` (within a constrained aligned range) and `pstrb` across many transactions to improve coverage closure.
- Fix the scoreboard's pass/fail conditions to correctly flag any single-field mismatch (e.g., using `||` for the fail check, or independent per-field checks).
- Add cross-coverage (e.g., `pwrite` × `pstrb`, `paddr` × `pslverr`) to the covergroup.
- Drive/verify `presetn` behavior and add corresponding checks once the DUT implements reset logic.
- Parameterize the test name via `+UVM_TESTNAME` and build a regression list for multiple test scenarios.
- Add a UVM `uvm_report_server`/`uvm_info`-based reporting flow instead of raw `$display` in the scoreboard and DUT.

---

## 🏁 Conclusion

This project delivers a compact but complete UVM verification environment for a SystemVerilog APB slave DUT, covering the essential UVM building blocks — transaction, sequence, sequencer, driver, monitor, scoreboard, and coverage — connected through a standard `uvm_env`, and driven through a working QuestaSim compile/simulate/coverage flow. The current stimulus validates the DUT's basic word-aligned write/read datapath at a single address; the identified gaps above outline a clear path toward a more exhaustive verification environment.

---

## 👤 Author / Portfolio Section

**Verification Engineer Portfolio Project**
UVM-Based APB Protocol Verification | SystemVerilog · UVM · QuestaSim

*This README was generated from a direct inspection of the project's source files to ensure technical accuracy.*
