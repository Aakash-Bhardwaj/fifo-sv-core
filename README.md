# FIFO SV Core

A reusable, parameterized **SystemVerilog Synchronous FIFO IP Core** supporting configurable data width and FIFO depth for FPGA and ASIC implementations.

This project follows a structured RTL engineering workflow, progressing from specification and architecture through implementation, verification, synthesis, and static timing analysis. The goal is to develop a reusable Synchronous FIFO IP core while emphasizing good design practices, documentation, and reproducibility.

This project emphasizes correctness, modularity, parameterization, and reproducibility. Each design decision is documented, verified, synthesized, and analyzed before integration.

---

## Objectives

* Design a reusable synchronous FIFO IP Core.
* Follow modern SystemVerilog coding practices.
* Support arbitrary positive FIFO depths.
* Support both Standard FIFO and optional First-Word Fall-Through (FWFT) operation.
* Develop comprehensive self-checking testbenches.
* Verify functionality using self-checking SystemVerilog testbenches and immediate assertions.
* Perform generic synthesis using Yosys.
* Perform technology-mapped synthesis using the Sky130 HDLL standard-cell library.
* Perform static timing analysis using OpenSTA.
* Maintain clear documentation throughout development.

---

## Planned Features

### Version 1

* [x] Parameterized data width
* [x] Parameterized FIFO depth
* [x] Standard synchronous FIFO
* [x] Optional First-Word Fall-Through (FWFT) mode
* [x] Full flag
* [x] Empty flag
* [x] Programmable Almost Full flag
* [x] Programmable Almost Empty flag
* [x] Occupancy counter
* [x] Overflow pulse
* [x] Underflow pulse
* [x] Support for arbitrary positive FIFO depths

### Future Enhancements

* [ ] Asynchronous FIFO
* [ ] Error correction (ECC)
* [ ] Parity support
* [ ] AXI-Stream wrapper
* [ ] APB wrapper
* [ ] AXI-Lite wrapper
* [ ] Vendor-specific memory inference
* [ ] Dual-port memory implementation
* [ ] Formal verification

---

## Repository Structure

```text
rtl/             Synthesizable SystemVerilog RTL
tb/              Self-checking testbenches
assertions/      Immediate SystemVerilog assertions
constraints/     OpenSTA timing constraints
scripts/         Synthesis and timing scripts
reports/         Synthesis and timing reports
docs/            Project documentation
docs/images/     Architecture, datapath, waveform and timing figures
```

---

## Documentation

The project documentation is organized into the following documents.

| Document                                      | Description                                                                                         |
| --------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| [Specification](docs/specification.md)   | Functional requirements, timing requirements, reset behaviour, assumptions and future enhancements. |
| [Architecture](docs/architecture.md)     | Design philosophy, module hierarchy and architectural organization.                                 |
| [Implementation](docs/implementation.md) | RTL implementation details, algorithms, synthesis and design decisions.                             |
| [Verification](docs/verification.md)     | Verification methodology, test plan, assertions and timing validation.                              |

---

## Toolchain

| Tool           | Purpose                |
| -------------- | ---------------------- |
| SystemVerilog  | RTL Design             |
| Icarus Verilog | Simulation             |
| GTKWave        | Waveform Viewing       |
| Yosys          | Logic Synthesis        |
| OpenSTA        | Static Timing Analysis |
| Sky130 HDLL    | Technology Mapping     |
| Git            | Version Control        |

---

## Development Workflow

```text
Specification
      ↓
Architecture
      ↓
RTL Design
      ↓
Verification
      ↓
Simulation
      ↓
Synthesis
      ↓
Timing Analysis
      ↓
Documentation
```

---

## Project Status

* [x] Repository initialized
* [x] Design specification
* [x] Architecture
* [x] RTL implementation
* [x] Self-checking verification
* [x] Immediate assertions
* [x] Generic synthesis
* [x] Sky130 technology mapping
* [ ] Static timing analysis

---

## Results

*Results will be added after RTL implementation, verification, synthesis, and timing analysis have been completed.*

---

## License

This project is licensed under the MIT License.
