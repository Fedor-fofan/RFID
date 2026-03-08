module spi_master(
    input logic clk,
    input logic rst,

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
    SPI_DONE, START
 } state_t;
    

state_t state_ff, state_nx;

logic [7:0] spi_rx_reg, spi_shift_reg;

logic [3:0] counter; 
logic spi_clk;

spi_clock spi_clk_1(
    .clk(clk),
    .rst(rst),
    .spi_clk(spi_clk)
);

always_ff @(posedge clk) begin
    if(rst) begin
        state_ff <= IDLE;
        spi_rx_reg <= 'b0; 
        spi_shift_reg <= 'b0;
        counter <= 'b0;
        spi_busy <= 1'b0;
        spi_cs <= 1'b1;
    end
    else begin
        state_ff <= state_nx;
    end
    // load tx data if handshake
    if(spi_tx_ready && spi_tx_valid) begin
        spi_shift_reg <= spi_tx_data;
    end
    //reset counter if data_shit is end
    if(state_ff == SPI_DONE) begin
        counter <= 'b0;
    end

    //default values
    if(state_ff == START & ~spi_start) begin
        spi_busy <= 1'b0;
        spi_cs <= 1'b1;
    end
    //if spi is busy
    if(spi_start)  begin 
        spi_busy <= 1'b1; 
        spi_cs <= 1'b0;
    //if spi done    
    end
    if(state_ff == SPI_DONE & spi_done) begin 
        spi_busy <= 1'b0; 
        spi_cs <= 1'b1;
    end
end

always_ff @( posedge spi_clk ) begin
    if(state_ff == SPI_SHIFT) begin
        if(counter <= 4'd8) begin
            spi_rx_reg <= {spi_rx_reg[6:0], spi_miso};
            spi_shift_reg <= {spi_shift_reg[6:0], 1'b0};
        end
        counter <= counter + 1;
    end
end

always_comb begin
    //default values
    state_nx = state_ff;
    spi_tx_ready = 1'b1;
    spi_rx_valid = 1'b0;
    spi_done = 1'b0;

    case(state_ff)

    IDLE: begin
        state_nx = START; 
    end 
    
    START: begin
        if(spi_start & ~spi_tx_valid) state_nx = SPI_WAIT;
        else if(spi_start & spi_tx_valid) state_nx = SPI_SHIFT;
    end

    SPI_WAIT: begin

        if(spi_tx_valid) begin // first handshake when submitting valid data for tx
            state_nx = SPI_SHIFT;
        end        
    end

    SPI_SHIFT: begin
        // while master is busy
        spi_tx_ready = 1'b0;

        if(counter >= 4'd9) begin
            state_nx = SPI_DONE;
        end
    end

    SPI_DONE: begin
        spi_tx_ready = 1'b0;
        spi_rx_valid = 1'b1;
        if(spi_rx_ready) begin // second handshake when ready to recieve data
            if(spi_last) begin 
                state_nx = START; 
                spi_done = 1'b1;
            end
            else state_nx = SPI_WAIT;
        end
    end

    endcase
end

assign spi_mosi = spi_shift_reg[7];
assign spi_rx_data = spi_rx_reg;

endmodule