/*
* RX PS2 keyboard scan code based on ps2_rx
* keyboard scan code: make_code + typematic(n*make_code) + break code(0xF0+make_code)
*/

module ps2_key
	#(
	parameter N=8
	)
	(
		input clk, rst,
		input en,
		input ps2c, ps2d,
		output done,
		output [7:0] ascii
	);							  
	
	localparam		BREAK_CODE = 8'hF0;	  
	
	typedef enum
	{		   
		KEY_S_WAIT_BREAK,
		KEY_S_GET_SCAN_CODE
	}KEY_STATE;
	
	wire rx_done;
	wire [7:0] rx_data;
	wire [7:0] ascii_code;		
	reg ascii_ready;	
	
	KEY_STATE state_r, state_n;
	
	ps2_rx
	#(
	.FILTER_STEPS(N)
	)
	rx_inst
	(
		.clk(clk),
		.rst(rst),
		.en(en),
		.ps2c(ps2c),
		.ps2d(ps2d),
		.done(rx_done),
		.data(rx_data)
	);		
	
	key2ascii
	key_2_asc_ins
	(
		.scan_code(rx_data),
		.ascii(ascii_code)
	);
	
	always_ff@(posedge(clk), posedge(rst))
	if(rst)
		state_r <= KEY_S_WAIT_BREAK;
	else
		state_r <= state_n;
		
	always_comb
	begin
		state_n = state_r;
		ascii_ready = 1'b0;
		
		case (state_r)
			KEY_S_WAIT_BREAK:
				begin  
					if(rx_done && rx_data == BREAK_CODE)
						state_n = KEY_S_GET_SCAN_CODE;
				end
			KEY_S_GET_SCAN_CODE:
				begin
					if(rx_done ) // next rs_done after BREAK_CODE is received
						begin
							ascii_ready = 1'b1;
							state_n = KEY_S_WAIT_BREAK;
						end	
				end
				
			default:
			begin
			end
		endcase
			
	end	
	
	assign ascii = ascii_code;
	assign done = ascii_ready;

endmodule

