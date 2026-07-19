module sva_sync_fifo #(
    parameter int DEPTH            = 16,
    parameter int AFULL_THRESHOLD  = DEPTH - 1,
    parameter int AEMPTY_THRESHOLD = 1,
    parameter int LEVEL_WIDTH      = $clog2(DEPTH + 1)
)(
    input logic                   clk,
    input logic                   rst_n,
    input logic                   wr_en,
    input logic                   rd_en,
    input logic                   full,
    input logic                   empty,
    input logic                   almost_full,
    input logic                   almost_empty,
    input logic                   overflow,
    input logic                   underflow,
    input logic [LEVEL_WIDTH-1:0] level
);

// Level never exceeds DEPTH
always @(posedge clk) begin
    if (rst_n) begin
        assert (level <= DEPTH)
            else $error("FIFO level exceeded DEPTH");
    end
end

// FIFO cannot be full and empty simultaneously
always @(posedge clk) begin
    if (rst_n) begin
        assert (!(full && empty))
            else $error("FIFO is both full and empty");
    end
end

// Full flag correctness
always @(posedge clk) begin
    if (rst_n) begin
        assert (full == (level == DEPTH))
            else $error("Full flag incorrect");
    end
end

// Empty flag correctness
always @(posedge clk) begin
    if (rst_n) begin
        assert (empty == (level == 0))
            else $error("Empty flag incorrect");
    end
end

// Almost full flag correctness
always @(posedge clk) begin
    if (rst_n) begin
        assert (almost_full == (level >= AFULL_THRESHOLD))
            else $error("Almost full flag incorrect");
    end
end

// Almost empty flag correctness
always @(posedge clk) begin
    if (rst_n) begin
        assert (almost_empty == (level <= AEMPTY_THRESHOLD))
            else $error("Almost empty flag incorrect");
    end
end

// Overflow flag correctness
always @(posedge clk) begin
    if (rst_n) begin
        assert (overflow == (wr_en && full))
            else $error("Overflow flag incorrect");
    end
end

// Underflow flag correctness
always @(posedge clk) begin
    if (rst_n) begin
        assert (underflow == (rd_en && empty))
            else $error("Underflow flag incorrect");
    end
end

// Outputs should not contain unknowns
always @(posedge clk) begin
    if(rst_n) begin
        assert (!$isunknown(level))
            else $error("level contains X");

        assert (!$isunknown(full))
            else $error("full contains X");

        assert (!$isunknown(empty))
            else $error("empty contains X");

        assert (!$isunknown(almost_full))
            else $error("almost_full contains X");

        assert (!$isunknown(almost_empty))
            else $error("almost_empty contains X");

        assert (!$isunknown(overflow))
            else $error("overflow contains X");

        assert (!$isunknown(underflow))
            else $error("underflow contains X");
    end
end

endmodule
