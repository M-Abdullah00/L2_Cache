module comparator (
    input  logic [17:0] req_tag,
 
    input logic [17:0] tag_w0,
    input logic [17:0] tag_w1,
    input logic [17:0] tag_w2,
    input logic [17:0] tag_w3,
 
    input logic valid_w0,
    input logic valid_w1,
    input logic valid_w2,
    input logic valid_w3,
 
    output logic hit,
    output logic [1:0] hit_way,   // for binary encoding
    output logic [3:0] hit_way_oh   // for one-hot encoding
);
 
    logic match_w0, match_w1, match_w2, match_w3;
 
    always_comb begin
        match_w0 = valid_w0 && (tag_w0==req_tag);
        match_w1 = valid_w1 && (tag_w1==req_tag);
        match_w2 = valid_w2 && (tag_w2==req_tag);
        match_w3 = valid_w3 && (tag_w3==req_tag);
 
        hit = match_w0 | match_w1 | match_w2 | match_w3;
        hit_way_oh = {match_w3, match_w2, match_w1, match_w0};
 
        // Binary encode
        if      (match_w0) hit_way = 2'd0;
        else if (match_w1) hit_way = 2'd1;
        else if (match_w2) hit_way = 2'd2;
        else               hit_way = 2'd3;
    end
 
endmodule