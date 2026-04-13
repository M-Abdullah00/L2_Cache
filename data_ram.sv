module data_ram(

    input logic clk,

    // read port
    input logic  rd_en,
    input logic [6:0] rd_index,
    input logic [1:0] rd_way,
    output logic [1023:0] rd_data,

    // write port
    input logic wr_en,
    input logic [6:0] wr_index,
    input logic [1:0] wr_way,
    input logic wr_full,
    input logic [1023:0] wr_line,
    input logic [6:0] wr_offset,
    input logic [31:0] wr_word,
    input logic [3:0] wr_strb
);
    localparam SETS = 128;
    localparam WAYS = 4;

    logic [1023:0] mem [SETS][WAYS];

    // read
    always_ff @(posedge clk) begin
        if (rd_en)
            rd_data <= mem[rd_index][rd_way];
    end

    // write
    always_ff @(posedge clk) begin
        if (wr_en) begin

            // full cache line write
            if (wr_full) begin
                mem[wr_index][wr_way] <= wr_line;
            end

            // partial word write (byte-wise)
            else begin
                // select word using wr_offset[6:2]
                // multiply by 32 to get starting bit of that word

                if (wr_strb[0])
                    mem[wr_index][wr_way][(wr_offset[6:2]*32)+0  +:8] <= wr_word[7:0];

                if (wr_strb[1])
                    mem[wr_index][wr_way][(wr_offset[6:2]*32)+8  +:8] <= wr_word[15:8];

                if (wr_strb[2])
                    mem[wr_index][wr_way][(wr_offset[6:2]*32)+16 +:8] <= wr_word[23:16];

                if (wr_strb[3])
                    mem[wr_index][wr_way][(wr_offset[6:2]*32)+24 +:8] <= wr_word[31:24];
            end
        end
    end

endmodule