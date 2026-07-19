module sync_fifo #(
    parameter int DATA_WIDTH       = 8,                  // Max. size of each element in queue
    parameter int DEPTH            = 16,                 // Length of queue
    parameter bit FWFT             = 1'b0,               // 0 for Standard FIFO, 1 for FWFT
    parameter int AFULL_THRESHOLD  = DEPTH - 1,          // threshold for almost full flag
    parameter int AEMPTY_THRESHOLD = 1,                  // threshold for almost empty flag
    parameter int LEVEL_WIDTH      = $clog2(DEPTH + 1)   // Derived parameter
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // Enables for reading and writing
    input  logic                   wr_en,
    input  logic                   rd_en,
    // To input data for writing
    input  logic [DATA_WIDTH-1:0]  wr_data,
    // To output data for reading
    output logic [DATA_WIDTH-1:0]  rd_data,
    // Flags to show FIFO status
    output logic                   full,
    output logic                   empty,
    output logic                   almost_full,
    output logic                   almost_empty,
    output logic                   overflow,
    output logic                   underflow,
    // To show number of elements stored
    output logic [LEVEL_WIDTH-1:0] level
);

    localparam int ADDR_WIDTH = (DEPTH > 1) ? $clog2(DEPTH) : 1;
    // FIFO storage memory
    logic [DATA_WIDTH-1:0] mem [DEPTH];
    // Read and write pointers
    logic [ADDR_WIDTH-1:0] write_ptr, read_ptr;
    // Registers for output
    logic [LEVEL_WIDTH-1:0] level_reg;
    logic [DATA_WIDTH-1:0] rd_data_reg;

    // To check whether to accept read/write or not
    logic do_write, do_read;
    assign do_write = wr_en && !full;
    assign do_read  = rd_en && !empty;

    // Function Logic
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            level_reg <= '0;
            write_ptr <= '0;
            read_ptr  <= '0;
        end
        // Standard FIFO mode
        else if (!FWFT) begin
            if (do_read && do_write) begin
                rd_data_reg    <= mem[read_ptr];
                // DEPTH not always a power of 2
                read_ptr       <= (read_ptr == DEPTH - 1) ? '0 : read_ptr + 1'b1;
                mem[write_ptr] <= wr_data;
                write_ptr      <= (write_ptr == DEPTH - 1) ? '0 : write_ptr + 1'b1;
                // Occupancy remains unchanged
            end
            else if (do_read) begin
                rd_data_reg <= mem[read_ptr];
                read_ptr    <= (read_ptr == DEPTH - 1) ? '0 : read_ptr + 1'b1;
                level_reg   <= level_reg - 1'b1;
            end
            else if (do_write) begin
                mem[write_ptr] <= wr_data;
                write_ptr      <= (write_ptr == DEPTH - 1) ? '0 : write_ptr + 1'b1;
                level_reg      <= level_reg + 1'b1;
            end
        end
        // First word fall through mode
        else begin
            if (do_read && do_write) begin
                read_ptr       <= (read_ptr == DEPTH - 1) ? '0 : read_ptr + 1'b1;
                mem[write_ptr] <= wr_data;
                write_ptr      <= (write_ptr == DEPTH - 1) ? '0 : write_ptr + 1'b1;
                // Occupancy remains unchanged
            end
            else if (do_write) begin
                mem[write_ptr] <= wr_data;
                write_ptr      <= (write_ptr == DEPTH - 1) ? '0 : write_ptr + 1'b1;
                level_reg      <= level_reg + 1'b1;
            end
            else if (do_read) begin
                read_ptr    <= (read_ptr == DEPTH - 1) ? '0 : read_ptr + 1'b1;
                level_reg   <= level_reg - 1'b1;
            end
        end
    end

    // Output logic
    assign level        = level_reg;
    assign full         = (level_reg == DEPTH);
    assign empty        = (level_reg == 0);
    assign almost_full  = (level_reg >= AFULL_THRESHOLD);
    assign almost_empty = (level_reg <= AEMPTY_THRESHOLD);
    assign overflow     = full   && wr_en;
    assign underflow    = empty  && rd_en;
    always_comb begin
        if (FWFT)
            rd_data = empty ? '0 : mem[read_ptr];
        else
            rd_data = rd_data_reg;
    end

    // synthesis translate_off

    // Parameter validation
    initial begin
        bit error_check;
        error_check = 0;
        if (DATA_WIDTH <= 0) begin
            $error("DATA WIDTH cannot be less than or equal to 0");
            error_check = 1;
        end
        if (DEPTH <= 0) begin
            $error("DEPTH cannot be less than or equal to 0");
            error_check = 1;
        end
        if (AFULL_THRESHOLD > DEPTH || AFULL_THRESHOLD < 0) begin
            $error("AFULL THRESHOLD should be any value between 0 and DEPTH, including both");
            error_check = 1;
        end
        if (AEMPTY_THRESHOLD > DEPTH || AEMPTY_THRESHOLD < 0) begin
            $error("AEMPTY THRESHOLD should be any value between 0 and DEPTH, including both");
            error_check = 1;
        end
        if (LEVEL_WIDTH != $clog2(DEPTH + 1)) begin
            $error("LEVEL WIDTH must be equal to \"$clog2(DEPTH + 1)\"");
            error_check = 1;
        end
        if (error_check) begin
            $fatal(0);
        end
    end

    // synthesis translate_on


endmodule
