`timescale 1ns/1ps

module tb_spi_master();
parametr real clk_period = 10.0;

logic clk;

\\na peredachu

logic [7:0] spi_tx_data;
logic spi_tx_valid; \\ dannye gotovi k otpravke
logic spi_tx_ready; \\ master gotov prinimat

\\na priem
logic [7:0] spi_rx_data;
logic spi_rx_valid;
logic spi_rx_ready; 

logic spi_start;
logic spi_last;

logic spi_busy;
logic spi_done;

logic spi_mosi;
logic spi_miso;

logic spi_clk;
logic spi_cs; \\chip select

spi_master dut(
.clk            (clk),
.spi_tx_data    (spi_tx_data),
.spi_tx_valid   (spi_tx_valid),
.spi_tx_ready   (spi_tx_ready),
.spi_rx_data    (spi_rx_data),
.spi_rx_valid   (spi_rx_valid),
.spi_rx_ready   (spi_rx_ready),
.spi_start      (spi_start),
.spi_last       (spi_last),
.spi_busy       (spi_busy),
.spi_done       (spi_done),
.spi_mosi       (spi_mosi),
.spi_miso       (spi_miso),
.spi_clk        (spi_clk),
.spi_CS         (spi_CS)
  );
initial begin
clk = 0;
forever #(clk_period) clk = ~clk;
end

