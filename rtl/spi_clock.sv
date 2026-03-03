module spi_clock #(
    parameters divider = 8
) (
    input logic clk,
    input logic rst,
    output logic spi_clk
);
    
logic [$clog2(divider)-1:0] counter;

always_ff @( posedge clk ) begin 
    if(rst) begin
        counter <= 'b0;
        spi_clk <= 'b0;
    end
    else begin
        counter <= counter + 1;
        if(counter == divider - 1) begin
            counter <= 'b0;
            spi_clk <= ~spi_clk;
        end
    end
end


endmodule