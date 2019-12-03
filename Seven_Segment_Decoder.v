module seven_segment_decoder	(	inBits, outBits	);
input	[3:0]	inBits;
output	[6:0]	outBits;
reg		[6:0]	outBits;
always @(inBits)
begin
	case(inBits)
		4'h1:
			outBits = 7'b1111001;	// ---t----
		4'h2:
			outBits = 7'b0100100; 	// |	    |
		4'h3:
			outBits = 7'b0110000; 	// lt	   rt
		4'h4:
			outBits = 7'b0011001; 	// |	    |
		4'h5:
			outBits = 7'b0010010; 	// ---m----
		4'h6:
			outBits = 7'b0000010; 	// |	    |
		4'h7:
			outBits = 7'b1111000; 	// lb	   rb
		4'h8:
			outBits = 7'b0000000; 	// |	    |
		4'h9:
			outBits = 7'b0011000; 	// ---b----
		4'ha:
			outBits = 7'b0001000;
		4'hb:
			outBits = 7'b0000011;
		4'hc:
			outBits = 7'b1000110;
		4'hd:
			outBits = 7'b0100001;
		4'he:
			outBits = 7'b0000110;
		4'hf:
			outBits = 7'b0001110;
		4'h0:
			outBits = 7'b1000000;
	endcase
end
endmodule
