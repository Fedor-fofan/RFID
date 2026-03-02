module spi_master(
    input clk,
    input rst,

    input logic [7:0] spi_tx_data,
    input logic spi_tx_valid,
    output wire spi_tx_ready,

    output logic [7:0] spi_rx_data,
    output wire spi_rx_valid, 
    input wire spi_rx_ready, 

    input wire spi_start,
    input logic spi_last,
    output wire spi_busy,
    output wire spi_done,

    output logic spi_mosi, 
    input wire spi_miso,
    output wire spi_clk,
    output wire spi_cs
);
	logic [2:0] counter; 
	wire spi_clk_rst;

	spi_clock(
		.clk(clk&(state==SPI_SHIFT)),
		.rst(rst|spi_clk_rst),
		.spi_clk(spi_clk)
	);

	enum logic [2:0] { 
		IDLE, 
		SPI_WAIT, 
		SPI_SHIFT,
		SPI_DONE
	} state, next_state;

	always_comb begin
		next_state = state;

		spi_tx_ready = 'b0;
		spi_rx_valid = counter==3'b7;
		spi_busy = 'b0;
		spi_done = 'b0;
		spi_cs = 1'b1;
		spi_clk_rst = 1'b0;

		case(state)
			IDLE: if (spi_start) next_state = SPI_WAIT; 
			SPI_WAIT: begin
				spi_tx_ready = spi_tx_valid;
				spi_cs = 1'b0;
				spi_clk_rst = 1'b1;

				if (spi_tx_valid&spi_rx_ready) next_state = SPI_SHIFT;
			end
			SPI_SHIFT: begin
				spi_tx_ready = 1'b1;
				spi_busy = 1'b1;
				spi_cs = 1'b0;

				if (counter==3'd7) next_state = spi_last ? SPI_DONE : SPI_WAIT;
			end
			SPI_DONE begin
				spi_done = 1'b1;
				spi_clk_rst = 1'b1;

				next_state = IDLE;
			end
		endcase
	end

	always_ff @(posedge clk) begin
		if(rst) begin
			state <= IDLE;
			counter <= 'b0;
			spi_rx_valid <= 'b0;
		end else begin
			state <= next_state;
			if (state!=SPI_SHIFT && counter!=0) counter <= 0;
		end
	end

	always_ff @( posedge spi_clk ) begin
		if (state==SPI_SHIFT && counter<3'd7) begin
			{spi_mosi, spi_tx_data} <= {spi_tx_data, spi_rx_data[7]};
			spi_rx_data <= {spi_rx_data[6:0],spi_miso};
			counter <= counter + 1;
		end
	end

endmodule