module spi_master(
    input clk,
    input rst,

    input logic [7:0] spi_tx_data,
    input logic spi_tx_valid,
    output logic spi_tx_ready,


    output logic [7:0] spi_rx_data,
    input logic spi_rx_ready, 
    output logic spi_rx_valid, 

    input logic spi_start,
    input logic spi_last,
    output logic spi_busy,
    output logic spi_done,

    output logic spi_mosi, 
    input logic spi_miso,
    output logic spi_clk,
    output logic spi_cs
);

typedef enum logic [2:0] { 
    IDLE, SPI_WAIT, SPI_SHIFT,
    SPI_DONE
 } state_t;
    

state_t state_ff, state_nx;

logic [7:0] spi_rx_reg, spi_shift_reg; // регистры приёма, передачи и сдвиговый регистр

logic [2:0] counter; 
logic spi_clok;

spi_clock(
    .clk(clk),
    .rst(rst),
    .spi_clk(spi_clok)
);

always_ff @(posedge clk) begin
    if(rst) begin
        state_ff <= IDLE;
        spi_rx_reg <= 'b0; 
        spi_shift_reg <= 'b0;
        counter <= 'b0;
    end
    else begin
        state_ff <= state_nx;
    end

    if(state_ff == SPI_WAIT && spi_tx_valid) begin
        spi_shift_reg <= spi_tx_data;
    end
    if(state_ff == SPI_DONE) begin
        counter <= 'b0;

    end
end

always_ff @( posedge spi_clk ) begin
    if(state_ff == SPI_SHIFT) begin
        if(counter <= 3'd7) begin
            spi_rx_reg <= {spi_rx_reg[7:1], spi_miso};
            spi_shift_reg <= {spi_shift_reg[7:1], 1'b0};
            counter <= counter + 1;
        end
    end
end

always_comb begin

    spi_tx_ready = 1'b1;
    spi_rx_valid = 1'b0;
    spi_busy = 1'b0;
    spi_done = 1'b0;
    spi_cs = 1'b1;

    case(state_ff)

    IDLE: begin
        if(spi_start) state_nx = SPI_WAIT; //если пришёл spi_start запускаем spi в ожидание данных
    end 
    
    SPI_WAIT: begin
            //значения по умолчанию после передачи данных
            spi_busy = 1'b0;
            spi_cs = 1'b1;
            spi_tx_ready = 1'b1;

        if(spi_rx_ready && spi_tx_valid) begin
            state_nx = SPI_SHIFT;
            spi_busy = 1'b1;
            spi_tx_ready = 1'b0;
            spi_cs = 1'b0;
            spi_rx_valid = 1'b0;
        end        
    end

    SPI_SHIFT: begin
        if(counter == 3'd7) begin
            spi_rx_valid = 1'b1;
            state_nx = SPI_DONE;
        end
    end

    SPI_DONE: begin
        spi_cs = 1'b1;
        spi_busy = 1'b0;
        spi_tx_ready = 1'b1;
        spi_done = 1'b1;

        if(spi_last) state_nx = IDLE;
        else state_nx = SPI_WAIT;
    end

    endcase
end

assign spi_mosi = spi_shift_reg[7];
assign spi_rx_data = spi_rx_reg;

endmodule