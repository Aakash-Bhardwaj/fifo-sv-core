.PHONY: help sim sim_fwft sim_all synth synth_fwft synth_all synth_sky130 synth_fwft_sky130 synth_all_sky130 timing timing_fwft timing_all clean all_standard all_fwft all

help:
	@echo "UART SV Core"
	@echo ""
	@echo "Available targets:"
	@echo "  sim                  Run simulation for Standard FIFO"
	@echo "  sim_fwft             Run simulation for FWFT FIFO"
	@echo "  sim_all              Run simulation for both Standard FIFO & FWFT FIFO"
	@echo "  synth                Run generic synthesis for Standard FIFO"
	@echo "  synth_fwft           Run generic synthesis for FWFT FIFO"
	@echo "  synth_all            Run generic synthesis for both Standard FIFO & FWFT FIFO"
	@echo "  synth_sky130         Run Sky130 technology-mapped synthesis for Standard FIFO"
	@echo "  synth_fwft_sky130    Run Sky130 technology-mapped synthesis for FWFT FIFO"
	@echo "  synth_all_sky130     Run Sky130 technology-mapped synthesis for both Standard FIFO & FWFT FIFO"
	@echo "  timing               Run OpenSTA timing analysis for Standard FIFO"
	@echo "  timing_fwft          Run OpenSTA timing analysis for FWFT FIFO"
	@echo "  timing_all           Run OpenSTA timing analysis for both Standard FIFO and FWFT FIFO"
	@echo "  all_standard         Run simulation, synthesis, and timing analysis for Standard FIFO"
	@echo "  all_fwft             Run simulation, synthesis, and timing analysis for FWFT FIFO"
	@echo "  all                  Run simulation, synthesis, and timing analysis for both Standard FIFO and FWFT FIFO"
	@echo "  clean                Remove generated files"

sim:
	iverilog -g2012 -o sim/sync_fifo rtl/*.sv assertions/*.sv tb/*.sv
	vvp sim/sync_fifo

sim_fwft:
	iverilog -g2012 -o sim/sync_fifo_fwft -DFWFT_MODE rtl/*.sv assertions/*.sv tb/*.sv
	vvp sim/sync_fifo_fwft

sim_all: sim sim_fwft

synth:
	mkdir -p reports/synthesis
	yosys -s scripts/synth_standard_fifo.ys | tee reports/synthesis/generic_synthesis_report_standard_fifo.txt

synth_fwft:
	mkdir -p reports/synthesis
	yosys -s scripts/synth_fwft_fifo.ys | tee reports/synthesis/generic_synthesis_report_fwft_fifo.txt

synth_all: synth synth_fwft

synth_sky130:
	mkdir -p reports/synthesis
	yosys -s scripts/synth_standard_fifo_sky130.ys | tee reports/synthesis/sky130_synthesis_report_standard_fifo.txt

synth_fwft_sky130:
	mkdir -p reports/synthesis
	yosys -s scripts/synth_fwft_fifo_sky130.ys | tee reports/synthesis/sky130_synthesis_report_fwft_fifo.txt

synth_all_sky130: synth_sky130 synth_fwft_sky130

timing:
	mkdir -p reports/timing
	sta scripts/timing_standard_fifo.tcl | tee reports/timing/opensta_report_standard_fifo.txt

timing_fwft:
	mkdir -p reports/timing
	sta scripts/timing_fwft_fifo.tcl | tee reports/timing/opensta_report_fwft_fifo.txt

timing_all: timing timing_fwft

all_standard: sim synth synth_sky130 timing

all_fwft: sim_fwft synth_fwft synth_fwft_sky130 timing_fwft

all: all_standard all_fwft

clean:
	rm -f simv
	rm -f *.vcd