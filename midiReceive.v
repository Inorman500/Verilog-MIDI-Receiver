module midiReceive(
clck,
LED_out,
rst_n,
midi_data,
bitcount,
state_next,
MIDIbit,
displaytoggle_nxt
);
//necessary input and outputs
input clck;// input clock 
input rst_n;// reset pin on board
input midi_data;// midi Data
output reg [7:0] LED_out; // LED bar on board

/// All other regs  tagged with output are used only to see the result of the waveform simulation
wire EdgeDetected; // wire to receive the output of the Edge detector module
wire [8:0]counterVal; // Wire to read the current value of the counter
reg manual_reset;// A reg used to reset the timer independent of the reset button
reg [9:0] frame;// a 10 bit register to hold 1 byte, 1 start and 1 stop bit of a MIDI frame
reg [1:0] state;// a 2 bit register to represent all 3 states.: Edge detet(0), initial bit recived (1),receiving all 3 midi bytes(2),and  Sampling a MIDI bit every 32us(3)  
output reg [5:0]bitcount;// This counts how many bits we've sampled so far 
reg displaytoggle=1'b0;// This will let us know when we should display an note
output reg MIDIbit; //register to hold the value sampled from midi_data

// next registers that will pass the updated value to the orginal registers on the next clock cycle
reg [7:0] LED_out_nxt; 
output reg [1:0] state_next; 
output reg displaytoggle_nxt=1'b0;
reg [5:0]bitcount_nxt=6'b000000;
reg [9:0]frame_next;
reg manual_reset_next=1'b0;

up_counter count(counterVal,clck,rst_n,manual_reset);//instantiation of modules
edge_detect fallingedge(midi_data,clck,EdgeDetected,rst_n);

always@(posedge clck)begin 

if (!rst_n) begin //setting all regs to  0 on when resest is pressed
state<=2'b00;
bitcount<=6'b0;
manual_reset<=1'b1;
frame<=10'b000000000;
displaytoggle=1'b0;
LED_out<=8'b00000000;

end
else begin // update registers with new values
state<=state_next;
bitcount<=bitcount_nxt;
manual_reset<=manual_reset_next;
frame[9:1]<=frame_next[8:0];
frame[0]<=MIDIbit;
displaytoggle<=displaytoggle_nxt;
LED_out<=displaytoggle_nxt? LED_out_nxt:8'b00000000;// Displays the curent value of LED_out_nxt if display is true

end  
end 

always@(*) begin 

case(state)

2'b00: begin // this is where we are dectecting an edge 
	if (EdgeDetected)begin // if we detect an edge, move onto the next state
		state_next=2'b01;// Move to next state
		manual_reset_next=1'b1;// Hold the rest for the counter 
		bitcount_nxt=6'b000000;// Keeping bitcount as 0
		MIDIbit=frame[0];// setting MIDIbit to the last bit in frame
		end
	else begin
		state_next=2'b00;// Keep looking for an edge 
		manual_reset_next=1'b1; /// Continue to hold the reset of the timer
		bitcount_nxt=6'b000000;// Keeping bitcount as 0
		MIDIbit=frame[0];// setting MIDIbit to the last bit in frame
		end
		end
2'b01: begin // this is the initial bit state. We will wait 16us for the start bit to arrive and then move to the next state
	if (counterVal==64) begin // if timer counts to 16us go to the sampling state
		manual_reset_next=1'b1;// stop timer 
		state_next=2'b10;// this will send us to the next state
		bitcount_nxt[5:0]=0;// Keeping bitcount as 0
		MIDIbit=midi_data;// sample the start bit
	end
	else begin 
		manual_reset_next=1'b0; // This will let the timer count up
		state_next=2'b01;// stay in the current state until 16us has passed
		bitcount_nxt[5:0]=0;// Keeping bitcount as 0
		MIDIbit=frame[0];// setting MIDIbit to the last bit in frame
	end
	
end		
2'b10: begin // This is the state where we check if all 30 bits have been sampled 
if (bitcount==6'b11110)begin //once all bits have been sampled, go back to state 0
	state_next=2'b00; // go back to edge detect state
	manual_reset_next=1;// stop timer
	bitcount_nxt[5:0]=0;// clear bit counter 
	MIDIbit=frame[0];// setting MIDIbit to the last bit in frame
	
	end 
	else begin// if we still need to sample bits, 
	manual_reset_next=1'b0;// start the counter 
	state_next=2'b11;// send us to the sampleing state
	bitcount_nxt=bitcount;// keep the current bitcount value 
	MIDIbit=frame[0];// setting MIDIbit to the last bit in frame
	end
	end 		

2'b11: begin// This is the sampling state
	
if (counterVal==128)begin// When the counter has counted 32us
	manual_reset_next=1'b1;// Reset timer
	state_next=2'b10;// go back to the pevious state
	bitcount_nxt=bitcount+1'b1; // incremeant bit count 
	MIDIbit=midi_data;// sample the bit from midi_data
	end
	else begin// when we need to keep counting 
	state_next=2'b11;// stay in the current state
	manual_reset_next=1'b0;// continue to count up
	bitcount_nxt=bitcount;// keep the current value of bitcount
	MIDIbit=frame[0];// setting MIDIbit to the last bit in frame
	end 
end 

default: begin 
state_next=2'b00; // go to state 0
manual_reset_next=1'b1;// reset the timer 
MIDIbit=frame[0];//setting MIDIbit to the last bit in frame
bitcount_nxt=6'b0; // set bitcount to 0
end
endcase
end

always @(*) begin 
if (counterVal==128)begin // when we have sampled the secound midi bit
frame_next<=frame;//set frame to frame next
end 
else begin// shift over all values 
frame_next[0]<=frame[1];
frame_next[1]<=frame[2];
frame_next[2]<=frame[3];
frame_next[3]<=frame[4];
frame_next[4]<=frame[5];
frame_next[5]<=frame[6];
frame_next[6]<=frame[7];
frame_next[7]<=frame[8];
frame_next[8]<=frame[9];
frame_next[9]<=frame[9];
end 
end


always @(*) begin 
if (frame[8:1]==8'h90)begin// when frame is 0x90(note on)
displaytoggle_nxt=1;// set display toggle to 1
end 
else if (frame[8:1]==8'h80) begin // when frame is 0x80(note off)
displaytoggle_nxt=0;// set display toggle to 0
end 
else begin
displaytoggle_nxt=displaytoggle;// set the next value to the current value 
end
end

always @(*) begin 
if (bitcount==19)begin// if we have finshed sampling the seconf MIDI byte
LED_out_nxt=frame[8:1];// set thhose bits to LED out
end 
else begin
LED_out_nxt=LED_out; // set the next value to the current value 
end
end

endmodule

// SUb modules 
module up_counter    (
  counter_out     ,  // Output Value of the counter 
  clck     ,  // clock Input
  reset_bttn, // reset button
  manual_reset // A reset independent of the clock
  );
// try to push the counter on the clock and update it off the clock 
//----------Output Ports--------------
     output reg [8:0] counter_out;
      reg [8:0] counter_nxt = 8'b0;
     //reg [8:0]out_next;
 //------------Input Ports--------------
      input reset_bttn,clck,manual_reset;
always @(*)begin 
if (manual_reset)begin // if we reset
counter_nxt=0;// set the counter to 0 
end else begin 
counter_nxt=counter_out+1'b1;// incremeant the counter 
end 
end
 
 always @(posedge clck) begin 
 if (!reset_bttn) begin
     counter_out <= 8'b00000000 ;// reset counter to an 8 bit zero value
 end else begin
    counter_out <= counter_nxt; //update counter with current value
  end
  end
 
     
endmodule

module edge_detect	(// this module will detect if the MIDI data line has a falling edge, indicating that a set of bytes is incomming
	input data,// Data line of midi
	input clk,// clock input
	output reg Edge_detected,// an output that lets us know if if an edge was detected 
	input rst_n// This tells us when the reset pin has been set
	);
	reg r1=0; 
	reg r2=0;
	reg Edge=0;
	
	always @(*) begin 
	if (r1==0 && r2==1)begin// if r1 and r2 have differnt values 
     Edge = 1; //Edge is detected 
     end
     else begin 
		 Edge = 0;// Edge not detected
		end
		end
		
	always @(posedge clk) begin
	if (!rst_n)begin // if reset is pressed, reset registers to 0
	r1 <= 0;
	r2 <= 0;
	Edge_detected<=0;
	end
	else begin // shift 1 bit of MIDI data into r1 and r2
		r1 <= data;
		r2 <= r1;
		Edge_detected<= Edge; 
	end
	end
	
endmodule
