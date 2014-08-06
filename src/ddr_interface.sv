
///////////////////////////////////////////////////////////////////////////////
//
// FILE NAME: DDR_INTERFACE.SV
//
// AUTHOR: Jeff Nguyen
//
// DATE CREATED: 07/29/2014
//
// DESCRIPTION:  The module defines all signals connect DDR Controller and DDR
// memory and used as a module port.  The module also includes the method of
//  * translating signal level for device commmands
//  * assertion test for function protocol.
//
///////////////////////////////////////////////////////////////////////////////                       
                  

`include "ddr_package.pkg"
interface DDR_INTERFACE;
timeunit 1ps;
timeprecision 1ps;


logic clock_n, clock_t;
logic clock_w,clock_r;   //create data strobe signals
logic reset_n;
   
logic cke, cs_n,act_n;
logic ras_n_a16, cas_n_a15, we_n_a14;
logic bc_n_a12, ap_a10;
logic addr17;
logic addr13;
logic addr11;
logic [9:0] addr9_0;
logic [BG_WIDTH - 1:0] bg_addr;
logic [BA_WIDTH - 1:0] ba_addr;
logic [2:0] C2_0 = CHIP_ID;

logic [DATA_WIDTH-1:0] dq;
logic dqs_t, dqs_c;
   
   //Not necessary use
wire dm_n, dbi_n, tdqs_t;
logic PAR;
wire ODT;
   
 
   
//simple clock resource 
initial
begin 
   clock_n = FALSE;
   forever #HALF_PERIOD clock_n = ~clock_n;
end   

//differential clock 
initial
begin 
   clock_t = TRUE;
   forever #HALF_PERIOD clock_t = ~clock_t;
end 
   
//write clock with 90 phase shift, double freq to clock_n
initial
begin
   clock_r = FALSE;
   #QUARTER_PERIOD;
   forever #QUARTER_PERIOD clock_r = ~clock_r;
end    
   
//data strobe/read clock , double freq to clock_n
initial
begin
   clock_w = FALSE;
   forever #QUARTER_PERIOD clock_w = ~clock_w;
end    
   
// method for strobe pins
task set_strobe_pins (input rw_data_type data);
@(posedge clock_r)
   dqs_t = 1'b1;
   dqs_c = 1'b0;
   repeat (data.preamble-1) @ (posedge clock_r); 
   repeat (data.burst_length + 2 ) begin
     @(posedge clock_r) 
     dqs_t = ~dqs_t;
     dqs_c = ~dqs_c;
   end; 
     dqs_t <= 1;
     dqs_c <= 1;
endtask

//method for write data 
task set_wdata_pins (input rw_data_type data);
@ (negedge clock_r) dq = 'z;
   repeat (data.preamble) @(negedge clock_r);
   repeat (data.burst_length +1) begin
      @ (negedge clock_r ) 
      dq = data.data_wr[7:0];
      data.data_wr = {8'h00, data.data_wr[63:8]};
   end
   dq = 'z;
endtask
   
   // method for read data (e.g. data in from the Memory) and strobe pins
 
                         
 
 
 
//method for set command, address pin
task set_cmd_pins (input command_type command);
@(posedge clock_n);
begin
   case (command.cmd)
   ACT: begin
      cs_n      <= 1'b0;
      act_n     <= 1'b0;
      bg_addr   <= command.cmd_data.addr.bg_addr;
      ba_addr   <= command.cmd_data.addr.ba_addr;
      //setup row addr   
      addr17    <= 1'b1;
      ras_n_a16 <= 1'b1;
      cas_n_a15 <= 1'b1;
      we_n_a14  <= 1'b1;
      addr13    <= command.cmd_data.addr.row_addr [13];
      bc_n_a12  <= command.cmd_data.addr.row_addr [12];
      addr11    <= command.cmd_data.addr.row_addr [11];
      ap_a10    <= command.cmd_data.addr.row_addr [10];
      addr9_0   <= command.cmd_data.addr.row_addr [9:0];
   end
   
   //precharge command
   PRE: begin
      cs_n      <= 1'b0;
      act_n     <= 1'b1;
      bg_addr   <= command.cmd_data.addr.bg_addr;
      ba_addr   <= command.cmd_data.addr.ba_addr;
      //setup row addr   
      addr17    <= 1'b1;
      ras_n_a16 <= 1'b0;
      cas_n_a15 <= 1'b1;
      we_n_a14  <= 1'b0;
      addr13    <= 1'b1;
      bc_n_a12  <= 1'b1;
      addr11    <= 1'b1;
      ap_a10    <= 1'b0;
      addr9_0   <= '1;
   end
               
   //read command
   CAS_R: begin
      cs_n      <= 1'b0;
      act_n     <= 1'b1;
      bg_addr   <= command.cmd_data.addr.bg_addr;
      ba_addr   <= command.cmd_data.addr.ba_addr;
      //setup row addr   
      addr17    <= 1'b1;
      ras_n_a16 <= 1'b1;
      cas_n_a15 <= 1'b0;
      we_n_a14  <= 1'b1;
      addr13    <= 1'b1;
      bc_n_a12  <= 1'b0;
      addr11    <= 1'b1;
      ap_a10    <= 1'b0;
      addr9_0   <= command.cmd_data.addr.col_addr [9:0];
   end
               
   //write command
   CAS_W: begin
      cs_n      <= 1'b0;
      act_n     <= 1'b1;
      bg_addr   <= command.cmd_data.addr.bg_addr;
      ba_addr   <= command.cmd_data.addr.ba_addr;
      //setup row addr   
      addr17    <= 1'b1;
      ras_n_a16 <= 1'b1;
      cas_n_a15 <= 1'b0;
      we_n_a14  <= 1'b0;
      addr13    <= 1'b1;
      bc_n_a12  <= 1'b0;
      addr11    <= 1'b1;
      ap_a10    <= 1'b0;
      addr9_0   <= command.cmd_data.addr.col_addr [9:0];
   end
         //MRS      
   MRS: begin
      cs_n      <= 1'b0;
      act_n     <= 1'b1;
      bg_addr   <= command.cmd_data.addr.bg_addr;
      ba_addr   <= command.cmd_data.addr.ba_addr;                
      addr17    <= command.cmd_data.addr.row_addr[14];
      ras_n_a16 <= 1'b0;
      cas_n_a15 <= 1'b0;
      we_n_a14  <= 1'b0;
      addr13    <= command.cmd_data.addr.row_addr[13];
      bc_n_a12  <= command.cmd_data.addr.row_addr[12];
      addr11    <= command.cmd_data.addr.row_addr[11];
      ap_a10    <= command.cmd_data.addr.row_addr[10];
      addr9_0   <= command.cmd_data.addr.row_addr [9:0];
   end      

   //REFRESH
   REF: begin
      cs_n      <= 1'b0;
      act_n     <= 1'b1;
      bg_addr   <= '1;
      ba_addr   <= '1;                
      addr17    <= '1;
      ras_n_a16 <= 1'b0;
      cas_n_a15 <= 1'b0;
      we_n_a14  <= 1'b1;
      addr13    <= '1;
      bc_n_a12  <= '1;
      addr11    <= '1;
      ap_a10    <= '1;
      addr9_0   <= '1;
   end          
               
   //ZQCL   
   ZQCL: begin
      cs_n      <= 1'b0;
      act_n     <= 1'b1;
      bg_addr   <= '1;
      ba_addr   <= '1; 
      addr17    <= 1'b1;
      ras_n_a16 <= 1'b1;
      cas_n_a15 <= 1'b1;
      we_n_a14  <= 1'b0;
      addr13    <= 1'b1;
      bc_n_a12  <= 1'b1;
      addr11    <= 1'b1;
      ap_a10    <= 1'b1;
      addr9_0   <= '1;
   end        
   
    //DES      
    DES: begin
      cs_n      <= 1'b1;
      act_n     <= 'X;
      bg_addr   <= command.cmd_data.addr.bg_addr;
      ba_addr   <= command.cmd_data.addr.ba_addr; 
      addr17    <= command.cmd_data.addr.row_addr[14];
      ras_n_a16 <= 'X;
      cas_n_a15 <= 'X;
      we_n_a14  <= 'X;
      addr13    <= command.cmd_data.addr.row_addr[13];
      bc_n_a12  <= command.cmd_data.addr.row_addr[12];
      addr11    <= command.cmd_data.addr.row_addr[11];
      ap_a10    <= command.cmd_data.addr.row_addr[10];
      addr9_0   <= command.cmd_data.addr.row_addr [9:0];
   end      
   
   //nop command       
   NOP:  begin
      cs_n      <=  1'b1;
      act_n     <= 1'b1;      
      bg_addr   <= command.cmd_data.addr.bg_addr;
      ba_addr   <= command.cmd_data.addr.ba_addr;
      addr17    <= 1'b1;
      ras_n_a16 <= 1'b1;
      cas_n_a15 <= 1'b1;
      we_n_a14  <= 1'b1;
      addr13    <= command.cmd_data.addr.row_addr [13];
      bc_n_a12  <= command.cmd_data.addr.row_addr [12];
      addr11    <= command.cmd_data.addr.row_addr [11];
      ap_a10    <= command.cmd_data.addr.row_addr [10];
      addr9_0   <= command.cmd_data.addr.row_addr [9:0];             
   end
 endcase;
end
endtask
         


endinterface













