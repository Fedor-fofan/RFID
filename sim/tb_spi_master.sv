`timescale 1ns/1ps

module tb_spi_master;
	localparam CLK_PERIOD = 10;

    logic clk;
    logic rst;

    logic [7:0] spi_tx_data;
    logic spi_tx_valid;
    logic spi_tx_ready;

    logic [7:0] spi_rx_data;
    logic spi_rx_ready;
    logic spi_rx_valid;

    logic spi_start;
    logic spi_last;
    logic spi_busy;
    logic spi_done;

    logic spi_mosi;
    logic spi_miso;
    logic spi_clk;
    logic spi_cs;

    spi_master dut(
        .clk(clk),
        .rst(rst),
        .spi_tx_data(spi_tx_data),
        .spi_tx_valid(spi_tx_valid),
        .spi_tx_ready(spi_tx_ready),
        .spi_rx_data(spi_rx_data),
        .spi_rx_ready(spi_rx_ready),
        .spi_rx_valid(spi_rx_valid),
        .spi_start(spi_start),
        .spi_last(spi_last),
        .spi_busy(spi_busy),
        .spi_done(spi_done),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_clk(spi_clk),
        .spi_cs(spi_cs)
    );

// Utils

	initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

	task automatic reset_dut(input int cycles=1);
		@(posedge clk);
        rst <= 1'b1;
		repeat (cycles) @(posedge clk);
        rst <= 1'b0;
    endtask

	task automatic init_signals();
		@(posedge clk);
        spi_tx_data  <= 8'h00;
        spi_tx_valid <= 1'b0;
        spi_rx_ready <= 1'b0;
        spi_start    <= 1'b0;
        spi_last     <= 1'b0;
        spi_miso     <= 1'b0;
    endtask

	task automatic start_transactions();
		@(posedge clk);
		spi_start <= 1'b1;
		@(posedge clk);
		spi_start <= 1'b0;
	endtask

	task automatic commit_transaction(input logic [7:0] tx_data, input logic last);
        while (!spi_tx_ready) @(posedge clk);
        spi_tx_data  <= tx_data;
        spi_tx_valid <= 1'b1;
		spi_rx_ready <= 1'b1;
		spi_last <= last;
		@(posedge clk);
    endtask

	task automatic read_mosi_write_miso(
		input  logic [7:0] miso,
		output logic [7:0] mosi
	);
		for (int i=0; i<8; i++) begin
			@(posedge spi_clk);
			mosi = {mosi[6:0], spi_mosi};
			spi_miso <= miso[7-i];
		end
	endtask

// Tests
 	task automatic test_spi_out_state(
        input logic cs       = 0,
        input logic slow_clk = 0,
        input logic mosi     = 0,
        input logic busy     = 0,
        input logic done     = 0,
        input logic tx_ready = 0,
        input logic rx_valid = 0,

		input string tag = "test"
	);
        assert (spi_cs       ===       cs) else $error("[%s] spi_cs expected %b, got %b", tag, cs, spi_cs);
        assert (spi_clk      === slow_clk) else $error("[%s] spi_clk expected %b, got %b", tag, slow_clk, spi_clk);
        assert (spi_mosi     ===     mosi) else $error("[%s] spi_mosi expected %b, got %b", tag, mosi, spi_mosi);
        assert (spi_busy     ===     busy) else $error("[%s] spi_busy expected %b, got %b", tag, busy, spi_busy);
        assert (spi_done     ===     done) else $error("[%s] spi_done expected %b, got %b", tag, done, spi_done);
        assert (spi_tx_ready === tx_ready) else $error("[%s] spi_tx_ready expected %b, got %b", tag, tx_ready, spi_tx_ready);
        assert (spi_rx_valid === rx_valid) else $error("[%s] spi_rx_valid expected %b, got %b", tag, rx_valid, spi_rx_valid);
    endtask


 	task automatic test_reset_state();
        @(posedge clk);

		test_spi_out_state(
			.cs      (1'b1),
			.tx_ready(1'b1),
			.tag("test_reset_state")
		);
    endtask

	task automatic test_transaction();
		logic [7:0] mosi, miso, tx_data, rx_data;

		tx_data = 8'($random);
		miso = 8'($random);

		start_transactions();

		test_spi_out_state(
			.tx_ready(1'b1),
			.tag("test_transaction: start_transaction")
		);

		commit_transaction(tx_data, 1'b1);

		test_spi_out_state(
			.tx_ready(1'b1),
			.tag("test_transaction: commit_transaction")
		);
		
		read_mosi_write_miso(miso, mosi);
		while (spi_busy) @(posedge clk);

		test_spi_out_state(
			.cs      (1'b1),
			.done    (1'b1),
			.rx_valid(1'b1),
			.tag("test_transaction: commit_transaction")
		);

        assert (mosi        === tx_data) else $error("[test_transaction: read_mosi_wire_miso] mosi expected %b, got %b", tx_data, mosi);
        assert (spi_rx_data ===    miso) else $error("[test_transaction: read_mosi_wire_miso] spi_rx_data expected %b, got %b", miso, spi_rx_data);
	endtask

	initial begin
        init_signals();
        reset_dut(5);

        test_reset_state();

		test_transaction();

        #100 $finish;
    end

endmodule