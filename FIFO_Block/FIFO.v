module FIFO(clock,reset,write_en,soft_reset,lfd_state,data_in,read_en,empty,full,data_out);

//FIFO Parameters
parameter depth=16,    // Depth of FIFO memory
          width=9;     // Width of FIFO memory

// Input Pins
input lfd_state;       //Used to identify the header byte
input clk,reset,write_en,soft_reset,read_en;
input [(width-2):0]data_in;                               // 8-bit wide memory

// Output Pins
output empty, full;
output [(width-2):0]data_out;                            // 8-bit wide memory

// Read and Write Pointers
reg [4:0]write_ptr, read_ptr;

// Declare 9-bit wide memory having 16 locations
reg [(width-1):0]memory[0:(depth-1)]; 
integer i;

reg [6:0]count;                                          // Read Data
reg temp;                                                // Delay lfd by 1 clock cycle

 //Full and Empty Logic 
assign full = ((write_ptr[4] != read_ptr[4]) && (write_ptr[3:0] == read_ptr[3:0])) ? 1'b1 : 1'b0;
assign empty = (write_ptr[4:0] == read_ptr[4:0]);        
always@(posedge clock)
begin
 if(reset)
  temp<=0;
 end
 else
  temp<=lfd_state;             //Delaying lfd_state by 1 clock to latch the header byte
 end

//Write Logic
always@(posedge clock)                                 
begin
 if(reset)                    // If Hard Reset triggered memory is cleared and write pointer is reset to 0
 begin
  for(i=0;i<depth;i=i+1)
   memory[i]<=0;
   write_ptr<=0;
 end
 else if(soft_reset)         // If Soft Reset triggered memory is cleared and write pointer is reset to 0
 begin
  for(i=0;i<depth;i=i+1)
   memory[i]<=0;
   write_ptr<=0;
 end
 else if(write_en && !full)
 begin
  {memory[write_ptr[3:0]][8],memory[write_ptr[3:0]][7:0]} <= {temp,data_in};
  write_ptr <= write_ptr + 1'b1;
 end
end
 
//Read Logic
always@(posedge clock)                                 
begin
 if(reset)                 // If Hard Reset triggered output data is cleared and read pointer is reset to 0
 begin
  for(i=0;i<(width-2);i=i+1)
   data_out[i]<=0;
   read_ptr<=0;
 end
 else if(soft_reset)      // If Soft Reset triggered output data is high impedance and read pointer is reset to 0
 begin
   data_out<=8'bz;
   read_ptr<=0;
 end 
 else if(count == 0)     // If Counter to read data is set to 0 then output data is high impedance 
 begin 
  data_out <= 8'bz;
 end
 else if(read_en && !empty)
 begin
  data_out <= memory[read_ptr[3:0]][7:0];
  read_ptr <= read_ptr + 1'b1;
 end
 else
  data_out <= 8'bz;
end
 
//Counter Logic
always@(posedge clock)
begin
 if(reset)
  count <= 0;
 else if(soft_reset)
  count <= 0;
 else if(memory[read_ptr[3:0]][8]==1)  // If Header Byte is 1, then counter will store the payload & Parity
 begin
  count <= memory[read_ptr[3:0]][7:2] + 1'b1;
 end
 else if(read_en && !empty)
  count <= count - 1'b1;
 else
  count <= count;
end

endmodule
