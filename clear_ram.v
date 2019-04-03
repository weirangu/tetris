module clear_ram
    (
        input enable,
        input clk,
        output reg [7:0] ram_addr,
        output reg wren,
        output [5:0] data,
        output reg complete
    );
    
	 assign data = 6'b000000;

    always @(posedge clk) begin
        if (~enable) begin
				ram_addr <= 7'd0;
            wren <= 1'b0;
            complete <= 1'b0;
        end
        else begin
            if (ram_addr < 8'd250) begin
                wren <= 1'b1;
                ram_addr <= ram_addr + 1'd1;
            end
            else begin
                ram_addr <= 7'd0;
                wren <= 1'b0;
                complete <= 1'b1;
            end
        end
    end
endmodule