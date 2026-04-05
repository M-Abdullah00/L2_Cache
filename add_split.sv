module add_split (

    input  logic [31:0] addr_in,
    output logic [17:0] tag_out,
    output logic [6:0] index_out,
    output logic [6:0] offset_out
);
 
    assign tag_out = addr_in[31:14];
    assign index_out = addr_in[13:7];
    assign offset_out = addr_in[6:0];
 
endmodule