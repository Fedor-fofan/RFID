`timescale 1ns/1ps

module tb_spi_master;

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

    // подключаем SPI master
    spi_master uut(
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

    // Clock generation
    always #5 clk <= ~clk; // 100MHz

    // ћоделируем SPI slave
    always @(posedge spi_clk) begin
        if(uut.state_ff == uut.SPI_SHIFT) begin
            // просто зеркалим MOSI в MISO дл€ теста
            spi_miso <= spi_mosi;
        end
    end

    initial begin
        // инициализаци€
        clk <= 0;
        rst <= 1;
        spi_tx_data <= 8'hAA;
        spi_tx_valid <= 0;
        spi_rx_ready <= 1; // готов принимать
        spi_start <= 0;
        spi_last <= 1;
        spi_miso <= 0;

        #20;
        rst <= 0;

        // первый тест: отправл€ем байт
        #10;
        spi_tx_valid <= 1;
        spi_start <= 1;
        #10;
        spi_start <= 0;

        wait(spi_done) #20; // ждЄм окончани€ передачи
        $display("Test 1: SPI RX = %h (should match TX)", spi_rx_data);

        // второй тест: другой байт
        #20;
        spi_tx_data <= 8'h5A;
        spi_tx_valid <= 1;
        spi_start <= 1;
        #10;
        spi_start <= 0;

        wait(spi_done);
        $display("Test 2: SPI RX = %h (should match TX)", spi_rx_data);

        #50;
        $finish;
    end

endmodule