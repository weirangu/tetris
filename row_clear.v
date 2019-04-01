module row_clear
    (
        input enable,
        input clk,
        input [5:0] ram_Q,
        output reg [7:0] ram_addr, 
        output reg [5:0] ram_data,
        output reg ram_wren,
        output reg complete
    );
    reg [5:0] curr_y;   // The current y row that we're checking
    reg [4:0] curr_x;
    reg has_empty_blk;  // Whether the current Y that we're checking has an empty block

    // Used for shifting the rows down
    reg sd_enable, sd_complete, sd_ram_wren;
    reg [7:0] sd_ram_addr;
    reg [5:0] sd_ram_data;
    shift_down sd (
        .enable(sd_enable),
        .end_addr(check_ram_addr),
        .clk(clk),
        .ram_Q(ram_Q),
        .ram_addr(sd_ram_addr),
        .ram_data(sd_ram_data),
        .ram_wren(sd_ram_wren),
        .complete(sd_complete)
    );

    // Used for checking the rows
    reg [7:0] check_ram_addr;
    reg [5:0] check_ram_data;

    coord_to_addr read (
        .X(curr_x),
        .Y(curr_y),
        .addr(check_ram_addr)
    );

    always @(posedge clk) begin
        if (~enable) begin
            curr_y <= 6'd24;
            curr_x <= 5'd10;
            has_empty_blk <= 1'b0;
            complete <= 1'b0;
            ram_addr <= check_ram_addr;
            ram_data <= 6'd0;
            ram_wren <= 1'b0;
        end else begin
            if (curr_x == 5'd10) begin
                // We've checked all the x values
                if (~has_empty_blk) begin
                    // We should be shifting the row down
                    ram_addr <= sd_ram_addr;
                    ram_data <= sd_ram_data;
                    ram_wren <= sd_ram_wren;
                    if (sd_complete) begin
                        // We don't modify curr_y because we don't need to, 
                        // the rows are shifted down so we can still test this row
                        curr_x <= 5'd0;
                        sd_enable <= 1'b0;
                        has_empty_blk <= 1'b0;
                    end else begin
                        sd_enable <= 1'b1;
                    end
                end else begin
                    if (curr_y == 6'd0) complete <= 1'b1;
                    curr_y <= curr_y - 1'b1;
                    curr_x <= 5'd0;
                    has_empty_blk <= 1'b0;
                end
            end else begin
                // Let's check the current x values
                has_empty_blk <= has_empty_blk || ram_Q;

                // Setup RAM for next read
                curr_x <= curr_x + 1'b1;
                ram_addr <= check_ram_addr;
            end
        end
    end
endmodule

// Shifts all blocks from [0: end_addr - 10) 10 blocks down, overwrites [end_addr - 10, end_addr)
// Assumes end_addr >= 10
module shift_down
    (
        input enable,
        input [7:0] end_addr,
        input clk,
        input [5:0] ram_Q,
        output reg [7:0] ram_addr, 
        output reg [7:0] ram_data, 
        output reg ram_wren,
        output reg complete
    );
    localparam 
        READ_PREP = 3'b000,
        READ = 3'b001,
        WRITE_PREP = 3'b010,
        WRITE = 3'b011,
        WRITE_END = 3'b100;

    reg [7:0] counter; // Keeps track of which module we're currently writing
    reg [5:0] temp_data;
    reg [2:0] curr_state, next_state;

    always @(posedge clk) begin
        if (~enable) begin
            counter <= end_addr - 7'd10;
            ram_wren <= 1'b0;
            ram_addr <= 8'd0;
            ram_data <= 6'd0;
            complete <= 1'd0;
        end
        else begin
            case (curr_state)
                READ_PREP: ram_addr <= end_addr;
                READ: temp_data <= ram_Q;
                WRITE_PREP: begin 
                    ram_data <= temp_data;
                    ram_addr <= counter + 7'd10;
                end
                WRITE: ram_wren <= 1'b1;
                WRITE_END: begin
                    ram_wren <= 1'b0;
                    if (counter == 8'd0) complete <= 1'd1;
                    else counter <= counter - 8'd1;
                end
            endcase
            curr_state <= curr_state + 1'd1;
        end
    end
endmodule
