module main(
	input clk, reset,
	input [1:0] raw_buttons,
	output reg [1:0] oLed,
	output reg [6:0] seven_segment_bits
);

/*
This is a basic game of Simon using two buttons.
*/

	/* = INPUT SETUP = */

	wire [1:0] raw_bundle = raw_buttons;

	wire [1:0] buttons;
	wire any_button_pressed;

	button_synchronizer b_inst(clk, raw_bundle, any_button_pressed, buttons);


	/* = COUNTERS = */

	wire [4:0] max_sequence, cur_sequence, completed_sequences;
	wire reset_max_sequence, reset_cur_sequence, reset_completed_sequences;
	wire inc_max_sequence, inc_cur_sequence, inc_completed_sequences;

	wire [4:0] cur_speed;

	counter_one max_sequence_counter(clk, inc_max_sequence,  reset_max_sequence, max_sequence);
	counter_zero cur_sequence_counter(clk, inc_cur_sequence,  reset_cur_sequence, cur_sequence);
	counter_zero completed_sequences_counter(clk, inc_completed_sequences,  reset_completed_sequences, completed_sequences);

	/* = SEVEN SEGMENT DISPLAY = */

	wire [6:0] seven_seg_wire;

	seven_segment_decoder seg_dec(cur_sequence,seven_seg_wire);

	/* = DELAY MODULES = */

	wire reset_var, reset_short, reset_round;
	wire var_delay, short_delay, round_delay;

	variable_delay delay_var(clk, reset_var, cur_speed, var_delay);
	variable_delay delay_short(clk, reset_short, 5'b11110, short_delay);
	variable_delay delay_round(clk, reset_round, 5'b01100, round_delay);

	/* = SEQUENCE GENERATOR = */

	wire randomize_seq, seq_next, seq_start_over;
	wire [7:0] seq_out;

	sequence_generator seq_inst(clk, randomize_seq, seq_next, seq_start_over, seq_out);

	/* = STATES = */

	reg [4:0] state;
	reg [4:0] nState;

	parameter INIT = 5'b00000;
	parameter RANDOMIZE = 5'b00001;
	parameter START_OVER = 5'b00010;
	parameter GENERATING = 5'b00011;
	parameter RESET_DELAY_VAR = 5'b00100;
	parameter SHOWING = 5'b00101;
	parameter RESET_DELAY_SHORT = 5'b00110;
	parameter WAIT_PAUSE = 5'b00111;
	parameter SHOWING_COMPLETE = 5'b01000;

	parameter START_OVER_INPUT = 5'b01001;
	parameter GENERATING_INPUT = 5'b01010;

	parameter ACCEPTING_INPUT = 5'b01011;
		parameter RESET_INPUT_BUFFER_DOWN = 5'b01100;
		parameter WAIT_INPUT_BUFFER_DOWN = 5'b01101;

	parameter WAITING_BUTTON_UP = 5'b01110;
		parameter RESET_INPUT_BUFFER_UP = 5'b01111;
		parameter WAIT_INPUT_BUFFER_UP = 5'b10000;

	parameter BUTTON_SUCCESSFUL = 5'b10000;

	parameter ROUND_INCREMENT = 5'b10001;
	parameter ROUND_WIN = 5'b10010;
	parameter GAME_WIN = 5'b10011;

	parameter GAME_OVER = 5'b11111;
	// Start at the absolute start state
	initial begin
		state = INIT;
	end

	// Transition states
	always @ (posedge clk) begin

		state <= nState;

	end

	always @ (*) begin

		seven_segment_bits = seven_seg_wire;

		// Reset is active low
		if(~reset)
		begin

			/* ================== STATE TRANSITION ================= */

			case (state)
				INIT: nState = RANDOMIZE;
				RANDOMIZE: nState = START_OVER;
				START_OVER:nState = GENERATING;
				GENERATING: nState = RESET_DELAY_VAR;
				RESET_DELAY_VAR: nState = SHOWING;
				SHOWING: begin
					if (var_delay) begin
						if (cur_sequence >= max_sequence)
							nState = SHOWING_COMPLETE;
						else
							nState = RESET_DELAY_SHORT;
					end
					else
						nState = SHOWING;
				end
				RESET_DELAY_SHORT: nState = WAIT_PAUSE;
				WAIT_PAUSE: begin
					if (short_delay)
						nState = GENERATING;
					else
						nState = WAIT_PAUSE;
				end
				SHOWING_COMPLETE: nState = START_OVER_INPUT;
				START_OVER_INPUT: nState = GENERATING_INPUT;
				GENERATING_INPUT: nState = ACCEPTING_INPUT;
				ACCEPTING_INPUT: begin
					if (~any_button_pressed)
						if (cur_sequence >= max_sequence)
							if (max_sequence == GAME_OVER) // Since GAME_OVER is 2^5, this checks if the player has mastered the sequence with length 2^5
								nState = GAME_WIN;
							else
								nState = ROUND_WIN;
						else
							nState = ACCEPTING_INPUT;
					else
						if (buttons == seq_out)
							nState = RESET_INPUT_BUFFER_DOWN;
						else
							nState = GAME_OVER;
							oLed[0]=1; oLed[1]=1;
				end

				RESET_INPUT_BUFFER_DOWN: nState = WAIT_INPUT_BUFFER_DOWN;
				WAIT_INPUT_BUFFER_DOWN: begin
					if (short_delay)
						nState = WAITING_BUTTON_UP;
					else
						nState = WAIT_INPUT_BUFFER_DOWN;
				end
				WAITING_BUTTON_UP: begin
					if (any_button_pressed)
						nState = WAITING_BUTTON_UP;
					else
						nState = BUTTON_SUCCESSFUL;
				end

				BUTTON_SUCCESSFUL: nState = RESET_INPUT_BUFFER_UP;
				RESET_INPUT_BUFFER_UP: nState = WAIT_INPUT_BUFFER_UP;
				WAIT_INPUT_BUFFER_UP: begin
					if (short_delay)
						nState = GENERATING_INPUT;
					else
						nState = WAIT_INPUT_BUFFER_UP;
				end
				GAME_OVER: nState = GAME_OVER;
				GAME_WIN: nState = GAME_OVER;
				ROUND_WIN: nState = ROUND_INCREMENT;
				ROUND_INCREMENT: nState = START_OVER;
				default: nState = INIT;
			endcase

			/* ================ LIGHT OUTPUT ============= */

			case (state)
				SHOWING: begin
					case (seq_out)
						2'b01: begin
							oLed[0]=1; oLed[1]=0;
						end
						2'b10: begin
							oLed[0]=0; oLed[1]=1;
						end
						default: begin
							oLed[0]=0; oLed[1]=0;
						end
					endcase

				end
				WAITING_BUTTON_UP: begin
					oLed[0] = ~buttons[1];
					oLed[1] = ~buttons[0];
				end
				GAME_OVER: begin
					oLed[0]=1; oLed[1]=1;
				end
				default: begin
					oLed[0]=0; oLed[1]=0;
				end
			endcase
		end
		else begin
			nState = INIT;
			oLed[0]=0; oLed[1]=0;
		end
	end

	/* ====== INTERNAL WIRES AND SUBMODULE CONNECTIONS ===== */

	// mostly resets, incrementers, and other commands that correspond to one or multiple states

	assign reset_var = (state == RESET_DELAY_VAR);
	assign reset_short = (state == RESET_DELAY_SHORT) | (state == RESET_INPUT_BUFFER_UP) | (state == RESET_INPUT_BUFFER_DOWN);
	assign reset_round = (state == START_OVER);


	assign randomize_seq = (state == RANDOMIZE);
	assign seq_next = (state == GENERATING) | (state == GENERATING_INPUT);
	assign seq_start_over = (state == START_OVER) | (state == START_OVER_INPUT);



	assign reset_max_sequence = (state == INIT);
	assign reset_cur_sequence = (state == INIT) | (state == START_OVER) | (state == SHOWING_COMPLETE);
	assign reset_completed_sequences = (state == INIT);

	assign inc_max_sequence = (state == ROUND_INCREMENT);
	assign inc_cur_sequence = (state == GENERATING) | (state == BUTTON_SUCCESSFUL);
	assign inc_completed_sequences = (state == ROUND_INCREMENT);

	assign cur_speed = max_sequence - 5'b00001;

endmodule
