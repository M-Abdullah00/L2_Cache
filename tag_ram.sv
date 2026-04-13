module tag_ram (
    input logic clk,
    input logic rst_n,
 
    // Read port (Stage 1, combinational)
    input  logic [6:0]  rd_index,
 
    output logic [17:0] rd_tag_w0,
    output logic [17:0] rd_tag_w1,
    output logic [17:0] rd_tag_w2,
    output logic [17:0] rd_tag_w3,
 
    output logic rd_valid_w0,
    output logic rd_valid_w1,
    output logic rd_valid_w2,
    output logic rd_valid_w3,
 
    output logic [1:0]  rd_victim_way,  // pseudo-LRU victim
    output logic [2:0]  rd_plru_bits,   // raw PLRU state for this set
 
    //Write port (Stage 4, synchronous)
    input logic        wr_en,
    input logic [6:0]  wr_index,
    input logic [1:0]  wr_way,
    input logic [17:0] wr_tag,
    input logic        wr_valid_bit,
 
    // PLRU update (synchronous, from control unit)
    input logic plru_update_en,
    input logic [6:0] plru_index,
    input logic [1:0] plru_way_used   // which way was accessed this cycle
);
 
    // Parameters
    localparam SETS = 128;
    localparam WAYS = 4;
 
    // Storage arrays
    logic [17:0] tags  [SETS][WAYS];
    logic valid [SETS][WAYS];
    logic [2:0]  plru  [SETS];
 
    // Combinational read 
    assign rd_tag_w0 = tags [rd_index][0];
    assign rd_tag_w1 = tags [rd_index][1];
    assign rd_tag_w2 = tags [rd_index][2];
    assign rd_tag_w3 = tags [rd_index][3];
 
    assign rd_valid_w0 = valid[rd_index][0];
    assign rd_valid_w1 = valid[rd_index][1];
    assign rd_valid_w2 = valid[rd_index][2];
    assign rd_valid_w3 = valid[rd_index][3];
 
    assign rd_plru_bits = plru[rd_index];
 
    // Victim decode — combinational
    // bit2=0 → victim in left  → bit1=0 → W1, bit1=1 → W0
    // bit2=1 → victim in right → bit0=0 → W3, bit0=1 → W2
    assign rd_victim_way =
        (!plru[rd_index][2]) ?
            (plru[rd_index][1] ? 2'd0 : 2'd1) :
            (plru[rd_index][0] ? 2'd2 : 2'd3);
 
    // Synchronous write and PLRU update 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int s = 0; s < SETS; s++) begin
                plru[s] <= 3'b000;
                for (int w = 0; w < WAYS; w++) begin
                    valid[s][w] <= 1'b0;
                    tags[s][w]  <= 18'h0;
                end
            end
        end else begin
            // Tag write — MSHR replay only
            if (wr_en) begin
                tags [wr_index][wr_way] <= wr_tag;
                valid[wr_index][wr_way] <= wr_valid_bit;
            end
 
            // PLRU update
            // Rule: point tree AWAY from accessed way
            // so next victim selection will not pick the recently used way
            if (plru_update_en) begin
                case (plru_way_used)
                    2'd0: plru[plru_index] <= {1'b1, 1'b0, plru[plru_index][0]};
                    2'd1: plru[plru_index] <= {1'b1, 1'b1, plru[plru_index][0]};
                    2'd2: plru[plru_index] <= {1'b0, plru[plru_index][1], 1'b0};
                    2'd3: plru[plru_index] <= {1'b0, plru[plru_index][1], 1'b1};
                    default: ;
                endcase
            end
        end
    end
 
endmodule