module fnd_rom(
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic [7:0] i_btn,

    output logic [7:0] o_data
    );

    logic [3:0] addr;
    logic btn_fall_pulse;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) btn_fall_pulse <= 0;
        else begin
            if(start && i_btn == 8'h80)
                btn_fall_pulse <= i_btn[7];
            else btn_fall_pulse <= 0;
        end
    end

    always @(posedge clk, posedge rst) begin
        if (rst) addr <= 4'd0;
        else if (btn_fall_pulse) begin
            if (addr == 4'd10) addr <= 4'd0;
            else addr <= addr + 1;
        end
    end


    always @(*) begin
        case (addr)
            4'd0: o_data    = 8'h92;
            4'd1: o_data    = 8'h8c;
            4'd2: o_data    = 8'hf9;
            4'd3: o_data    = 8'hbf;
            4'd4: o_data    = 8'hf9;
            4'd5: o_data    = 8'ha4;
            4'd6: o_data    = 8'hc6;
            4'd7: o_data    = 8'hbf;
            4'd8: o_data    = 8'h83;
            4'd9: o_data    = 8'hc1;
            4'd10: o_data    = 8'h92;
            default: o_data = 8'hff;
        endcase
    end
endmodule
