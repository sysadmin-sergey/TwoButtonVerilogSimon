/*
   This module is used for sycronizing the keys to the clock.
   The key input is active low, like the keys on the board.
   This module inverts the buttons so that the pressed output is active high
   button_down is high if any of the buttons are pressed
*/
module button_synchronizer(
	input clk,
	input [1:0] key,
	output button_down,
	output reg [1:0] pressed
);
// To prevent metastability
reg [1:0] key1;

assign button_down = |pressed;

always @(posedge clk) begin
	pressed <= key1;
	key1 <= ~key; // Invert the keys to check of pressed
end
endmodule
