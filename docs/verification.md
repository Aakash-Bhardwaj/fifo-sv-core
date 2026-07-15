# FIFO SV Core Verification Plan

## 1. Verification Objectives

The objective of verification is to ensure that the Parameterized Synchronous FIFO SV Core satisfies all functional requirements defined in the project specification.

Verification shall confirm correct functionality through simulation, self-checking testbenches, assertions, and synthesis.

---

## 2. Verification Methodology

Verification shall follow a layered approach consisting of:

* Directed testing
* Self-checking testbenches
* Immediate SystemVerilog assertions
* Waveform analysis
* Synthesis using Yosys
* Static timing analysis using OpenSTA

---

## 3. Verification Environment

| Tool           | Use              |
| -------------- | ---------------- |
| Icarus Verilog | Simulation       |
| GTKWave        | Waveform viewing |
| Yosys          | Synthesis        |
| OpenSTA        | Timing analysis  |

---

## 4. Module Verification

### 4.1 Synchronous FIFO

*To be updated after implementation.*

---

## 5. Functional Test Cases

### 5.1 Synchronous FIFO

*To be updated after implementation.*

---

## 6. Assertions

*To be updated after implementation.*

---

## 7. Coverage Goals

The verification process shall aim to:

* Verify all supported FIFO operations.
* Verify all supported parameter configurations.
* Verify reset behaviour.
* Verify boundary conditions.
* Verify all supported operating modes.

---

## 8. Success Criteria

Verification is considered complete when:

* All planned tests pass.
* All assertions pass.
* No simulation errors remain.
* Generic synthesis completes successfully.
* Technology-mapped synthesis completes successfully.
* Static timing analysis reports no timing violations.

---

## 9. Static Timing Analysis Results

*To be updated after implementation.*

---

## 10. Future Verification Enhancements

* UVM
* Cocotb
* Constrained-random verification
* Functional coverage
* Formal verification
