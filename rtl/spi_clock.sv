module spi_clock #(
    parameters divider = 8
) (
    input clk,
    input rst,
    output spi_clk
);
    
logic [$clog2(divider)-1:0] counter;

always_ff @( posedge clk ) begin 
    if(rst) begin
        counter <= 'b0;
    end
    else begin
        counter <= counter + 1;
    end
end

assign spi_clk = (counter == divider);

endmodule