# FIFO SV Core Specification

## 1. Introduction

The Parameterized Synchronous FIFO (First-In First-Out) SV Core is a reusable SystemVerilog hardware IP that provides temporary data storage between producer and consumer logic operating within the same clock domain.

The FIFO preserves the order of data, ensuring that the first data written is the first data read.

The design targets:

* FPGA implementation
* ASIC implementation
* Generic synthesis
* Sky130 HDLL technology mapping
* Educational and production-quality reusable IP

This project follows the same documentation-driven development methodology established during the UART SV Core project.

---

## 2. Scope

Version 1.0 implements a configurable synchronous FIFO supporting:

* Single clock domain
* Active-low synchronous reset
* Parameterized data width
* Parameterized FIFO depth
* Single write port
* Single read port
* Standard FIFO operation
* Optional First-Word Fall-Through (FWFT) mode
* Occupancy tracking
* Full and Empty status flags
* Programmable Almost Full and Almost Empty flags
* Overflow and Underflow pulse generation

Clock-domain crossing is outside the scope of this version and will be addressed by a future asynchronous FIFO implementation.

---

## 3. Functional Requirements

The FIFO SV Core shall:

* Store input data words in the order they are written.
* Return stored data in the same order.
* Support Standard FIFO and First-Word Fall-Through (FWFT) operating modes selected through the `FWFT` parameter.
* Accept a write operation only when `wr_en` is asserted and the FIFO is not full.
* Ignore write requests while the FIFO is full.
* Accept a read operation only when `rd_en` is asserted and the FIFO is not empty.
* Ignore read requests while the FIFO is empty.
* During simultaneous read and write requests:
  * If partially filled, perform both operations in the same clock cycle, while leaving occupancy unchanged.
  * If full, ignore the write and perform the read.
  * If empty, ignore the read and perform the write.
* Assert `empty` whenever no valid entries are stored.
* Assert `full` whenever no additional entries can be written.
* Assert `almost_full` when the occupancy reaches or exceeds the programmable almost-full threshold.
* Assert `almost_empty` when the occupancy reaches or falls below the programmable almost-empty threshold.
* Generate a one-clock-cycle `overflow` pulse whenever a write request occurs while the FIFO is full.
* Generate a one-clock-cycle `underflow` pulse whenever a read request occurs while the FIFO is empty.
* Provide the current FIFO occupancy through the `level` output.
* Support any positive FIFO depth, including non-power-of-two values and `DEPTH = 1`.

---

## 4. Parameters

| Parameter          | Description                                           |
| ------------------ | ----------------------------------------------------- |
| `DATA_WIDTH`       | Width of each stored data word                        |
| `DEPTH`            | Number of FIFO storage locations                      |
| `FWFT`             | Selects Standard FIFO or First-Word Fall-Through mode |
| `AFULL_THRESHOLD`  | Almost-full threshold                                 |
| `AEMPTY_THRESHOLD` | Almost-empty threshold                                |

---

## 5. Interface

### Inputs

| Signal    |        Width | Description                  |
| --------- | -----------: | ---------------------------- |
| `clk`     |            1 | System clock                 |
| `rst_n`   |            1 | Active-low synchronous reset |
| `wr_en`   |            1 | Write enable                 |
| `rd_en`   |            1 | Read enable                  |
| `wr_data` | `DATA_WIDTH` | Input write data             |

### Outputs

| Signal         |             Width | Description            |
| -------------- | ----------------: | ---------------------- |
| `rd_data`      |      `DATA_WIDTH` | Output read data       |
| `full`         |                 1 | FIFO full indicator    |
| `empty`        |                 1 | FIFO empty indicator   |
| `almost_full`  |                 1 | Almost-full indicator  |
| `almost_empty` |                 1 | Almost-empty indicator |
| `overflow`     |                 1 | Overflow pulse         |
| `underflow`    |                 1 | Underflow pulse        |
| `level`        | `$clog2(DEPTH+1)` | Current FIFO occupancy |

---

## 6. Timing Requirements

* All sequential logic shall operate on the rising edge of the system clock.
* All read and write operations shall be synchronous to the system clock.
* The design shall operate entirely within a single clock domain.
* Registered outputs shall update on the rising edge of the system clock.
* Combinational outputs shall reflect the current FIFO state without requiring an additional clock edge.
* No internally generated clocks shall be used.

---

## 7. Reset Behaviour

The FIFO SV Core shall use an active-low synchronous reset.

Following reset:

* Write pointer shall be cleared.
* Read pointer shall be cleared.
* FIFO occupancy shall become zero.
* `empty` shall be asserted.
* `full` shall be deasserted.
* `almost_full` and `almost_empty` shall reflect the reset occupancy.
* Overflow and underflow outputs shall be deasserted.
* Output data shall return to its default value in Standard FIFO mode.
* In FWFT mode, the output reflects the memory contents. Since the memory array is not reset, its contents are considered invalid until valid data has been written.

---

## 8. Parameter Validation

The implementation shall validate configuration parameters during elaboration whenever possible.

The following constraints apply:

* `DATA_WIDTH > 0`
* `DEPTH > 0`
* `AFULL_THRESHOLD >= 1`
* `AFULL_THRESHOLD <= DEPTH`
* `AEMPTY_THRESHOLD >= 0`
* `AEMPTY_THRESHOLD < DEPTH`

---

## 9. Assumptions

The following assumptions apply to Version 1.0:

* A stable system clock is available.
* Read and write logic operate in the same clock domain.
* Input control signals are synchronous to the system clock.
* Only one write request and one read request may occur per clock cycle.
* Synthesis tools infer an appropriate memory implementation from the RTL.
* Simultaneous read and write requests are resolved according to the current FIFO state (empty, partially filled, or full).

---

## 10. Future Enhancements

Future versions of the FIFO SV Core may include:

* Asynchronous FIFO
* Error correction (ECC)
* Parity generation
* Runtime-programmable thresholds
* AXI-Stream wrapper
* APB wrapper
* AXI-Lite wrapper
* Vendor-specific memory inference
* Dual-port memory implementation
* Formal verification
