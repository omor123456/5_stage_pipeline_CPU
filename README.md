# 5_stage_pipeline_CPU
# 64-Bit Pipelined CPU Design

A custom 64-bit pipelined CPU implemented in SystemVerilog, featuring a five-stage instruction pipeline, ALU operations, register and memory access, data forwarding, hazard detection, conditional branching, and gate-level logic.

This project focused on understanding how processor datapaths operate at the hardware level and verifying that instructions move correctly through the pipeline under both normal and hazard conditions.

---

### Project Overview

The CPU is organized into five primary pipeline stages:

- Instruction Fetch (IF)
- Instruction Decode (ID)
- Execute (EX)
- Memory Access (MEM)
- Write Back (WB)

Pipeline registers separate each stage so multiple instructions can be processed simultaneously. The processor uses a program counter, instruction memory, register file, ALU, data memory, control unit, forwarding logic, hazard detection, branch logic, and pipeline registers.

The design also includes mechanisms to handle data dependencies and control hazards that occur when instructions depend on results from previous instructions.

---

### My Contributions

I worked on the implementation and verification of the CPU datapath and control logic, including:

- Designed and integrated the five-stage pipelined CPU architecture
- Implemented instruction fetch, decode, execute, memory, and write-back datapaths
- Connected the control unit and ALU control logic to generate instruction-specific control signals
- Implemented register selection logic for source and destination registers
- Implemented immediate-value sign and zero extension
- Designed branch target calculation and register-indirect branch handling
- Implemented data forwarding from later pipeline stages to the EX stage
- Implemented forwarding for branch instructions in the ID stage
- Implemented load-use hazard detection and pipeline stalling
- Implemented branch redirection and pipeline flushing
- Implemented condition checking for CBZ and BLT instructions
- Implemented ALU flag generation and forwarding for signed comparisons
- Integrated instruction and data memory
- Implemented the write-back datapath and memory-to-register selection
- Built gate-level logic for zero detection and branch decision logic
- Created and used test cases/testbench simulations to verify processor behavior
- Analyzed pipeline behavior and performance across different instruction sequences

---

### CPU Datapath

The processor follows the general pipeline:

```text
        ┌──────────────┐
        │ Instruction  │
        │    Memory    │
        └──────┬───────┘
               │
               ▼
        ┌──────────────┐
        │      IF      │
        │ Instruction  │
        │    Fetch     │
        └──────┬───────┘
               │
            IF/ID
               │
               ▼
        ┌──────────────┐
        │      ID      │
        │ Decode +     │
        │ Register Read│
        └──────┬───────┘
               │
            ID/EX
               │
               ▼
        ┌──────────────┐
        │      EX      │
        │ ALU +        │
        │ Forwarding   │
        └──────┬───────┘
               │
            EX/MEM
               │
               ▼
        ┌──────────────┐
        │     MEM      │
        │ Data Memory  │
        └──────┬───────┘
               │
            MEM/WB
               │
               ▼
        ┌──────────────┐
        │      WB      │
        │ Register     │
        │    Write     │
        └──────────────┘
```

The implementation uses pipeline registers between stages to preserve instruction state while allowing multiple instructions to execute concurrently.

---

### Instruction Decode & Control

The decode stage determines the control signals required for each instruction.

The control logic generates signals including:

```text
Reg2Loc
ALUSrc
ImmSel
ALUOp
MemToReg
LinkReg
RegWrite
MemRead
MemWrite
SetFlags
UncondBr
BrSel
BZero
BLess
```

These signals determine how the instruction interacts with the register file, ALU, memory, branch logic, and write-back stage.

The register-selection logic also supports different instruction formats by selecting the appropriate source and destination register fields.

---

### ALU & Execute Stage

The execute stage contains the main ALU datapath.

The ALU receives its operands through forwarding multiplexers so that recently produced values can be used without waiting for them to reach the register file.

The ALU supports arithmetic/logic operations and generates condition flags:

```text
Negative
Zero
Overflow
Carry
```

For branch comparisons such as signed less-than, the design uses the relationship between the negative and overflow flags:

```text
Less Than = Negative XOR Overflow
```

This allows branch decisions to use the result of an immediately preceding flag-setting instruction.

---

### Data Forwarding

One of the major challenges in a pipelined CPU is data hazards.

For example:

```text
ADD  X1, X2, X3
SUB  X4, X1, X5
```

The `SUB` instruction needs the result of the `ADD` before that result has necessarily reached the register file.

To avoid unnecessary stalls, the processor implements forwarding from later pipeline stages.

The forwarding logic selects the newest available value from:

```text
Register File
      │
      ├── WB result
      │
      ├── MEM result
      │
      └── EX result
```

The forwarding priority is:

```text
EX → MEM → WB → Register File
```

The processor also includes a separate forwarding path for branch instructions in the decode stage so that branch comparisons can use recently produced register values.

---

### Hazard Detection

The processor includes a hazard detection unit to identify situations where forwarding alone cannot resolve a dependency.

A key example is a load-use hazard:

```text
LDUR X1, [X2, #0]
ADD  X3, X1, X4
```

The value loaded by `LDUR` is not immediately available for the following instruction.

The hazard unit detects this condition and introduces a pipeline stall/bubble so the dependent instruction executes with the correct data.

The design therefore handles:

```text
Data hazards
Load-use hazards
Control hazards
Branch dependencies
```

---

### Branch & Control Hazard Handling

The CPU supports branch decisions during the decode stage.

Branch conditions include:

- Unconditional branches
- Register-indirect branches
- CBZ
- BLT

The branch target is calculated from the current PC and sign-extended branch offset:

```text
Branch Target = PC + (SignExtended Offset << 2)
```

The design then selects between the normal sequential PC and the branch target.

When a branch changes program flow, the pipeline can flush instructions that were fetched along the incorrect path.

An optional `ENABLE_FLUSH` parameter was included to control branch-flush behavior during testing and comparison of pipeline behavior.

---

### Gate-Level Logic

A portion of the CPU was implemented using explicit gate-level logic rather than relying entirely on behavioral operators.

For example, the zero detector determines whether a 64-bit value is equal to zero by dividing the input into 4-bit groups and using NOR gates, followed by AND gates.

Conceptually:

```text
64-bit Input
     │
     ▼
16 × 4-bit NOR groups
     │
     ▼
4 intermediate AND signals
     │
     ▼
Final AND
     │
     ▼
Zero = 1
```

This provides a hardware-level implementation of:

```text
Zero = (Input == 0)
```

The branch decision logic similarly combines gate-level signals for unconditional branches, CBZ, and signed less-than conditions.

---

### Testbench & Verification

The CPU was verified using simulation-based test cases designed to exercise both normal instruction execution and pipeline edge cases.

Testing focused on:

```text
✓ Arithmetic operations
✓ Register-to-register operations
✓ Immediate operations
✓ Load/store operations
✓ Register dependencies
✓ Forwarding paths
✓ Load-use hazards
✓ Pipeline stalls
✓ Conditional branches
✓ Branch target calculation
✓ Branch flushing
✓ Register-indirect branches
✓ ALU flags
✓ Zero detection
✓ Write-back behavior
```

The testbench was used to observe internal processor signals and verify that instructions produced the expected results as they propagated through the pipeline.

Example dependency test:

```text
Instruction 1 → produces value
Instruction 2 → immediately consumes value
Instruction 3 → consumes previous result
```

These tests were particularly useful for verifying that the forwarding unit selected the newest available result instead of using stale register-file data.

---

### Performance & Pipeline Analysis

Pipeline performance was evaluated by examining instruction throughput and the additional cycles introduced by hazards.

With a five-stage pipeline, multiple instructions can occupy different stages during the same clock cycle:

```text
Cycle:   1   2   3   4   5   6   7

Inst 1: IF  ID  EX MEM  WB
Inst 2:     IF  ID  EX MEM  WB
Inst 3:         IF  ID  EX MEM  WB
Inst 4:             IF  ID  EX MEM  WB
```

After the pipeline is filled, the processor can approach one completed instruction per clock cycle for instruction sequences without stalls or control hazards.

Performance is reduced when the processor encounters:

- Load-use dependencies
- Taken branches
- Pipeline flushes
- Other instruction dependencies that cannot be resolved through forwarding

The testbench was used to compare these cases and identify the additional cycles introduced by pipeline hazards.

---

### Example Hazard Scenario

A dependent ALU sequence:

```assembly
ADD  X1, X2, X3
SUB  X4, X1, X5
```

Instead of waiting for `X1` to be written back, the forwarding unit can route the newly calculated result directly to the ALU.

This reduces unnecessary pipeline stalls and improves instruction throughput.

For a load-use dependency:

```assembly
LDUR X1, [X2, #0]
ADD  X3, X1, X4
```

Forwarding alone is insufficient because the loaded memory value is not available early enough. The hazard unit therefore inserts a stall/bubble.

---

### Verification Strategy

The verification process followed a hardware-debugging approach:

1. Reset the processor
2. Load the instruction sequence
3. Clock the processor through multiple pipeline cycles
4. Monitor PC and pipeline registers
5. Check register-file values
6. Check ALU outputs and flags
7. Check memory accesses
8. Verify forwarding selections
9. Verify stall and flush signals
10. Compare final results against expected values

This allowed individual datapath components and the complete pipelined processor to be tested independently.

---

### Technologies

```text
SystemVerilog
Verilog
Digital Logic
CPU Architecture
Pipelining
RTL Design
Gate-Level Logic
Hardware Verification
Simulation / Testbench Development
```

---

### Engineering Takeaways

This project provided hands-on experience with the hardware mechanisms required to implement a pipelined processor, including:

- RTL datapath design
- CPU control logic
- Five-stage pipelining
- Pipeline registers
- Data forwarding
- Hazard detection
- Branch prediction/control-flow handling
- ALU flag generation
- Gate-level combinational logic
- Memory interfaces
- Hardware verification
- Timing and pipeline performance analysis

The project strengthened my understanding of how high-level instructions are translated into clock-by-clock hardware operations and how real processor designs maintain correctness while maximizing instruction throughput.
