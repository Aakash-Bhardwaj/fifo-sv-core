# FIFO Timing Constraints

# 50 MHz clock
create_clock -name clk -period 20 [get_ports clk]

# Input delays
set_input_delay 0 -clock clk [all_inputs]

# Output delays
set_output_delay 0 -clock clk [all_outputs]