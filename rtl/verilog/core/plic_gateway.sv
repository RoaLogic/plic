/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//   RISC-V Platform-Level Interrupt Controller                    //
//                                                                 //
/////////////////////////////////////////////////////////////////////
//                                                                 //
//             Copyright (C) 2017 ROA Logic BV                     //
//             www.roalogic.com                                    //
//                                                                 //
//   This source file may be used and distributed without          //
//   restriction provided that this copyright statement is not     //
//   removed from the file and that any derivative work contains   //
//   the original copyright notice and the associated disclaimer.  //
//                                                                 //
//      THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY        //
//   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED     //
//   TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS     //
//   FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR OR     //
//   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,  //
//   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT  //
//   NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;  //
//   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)      //
//   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     //
//   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  //
//   OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS          //
//   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.  //
//                                                                 //
/////////////////////////////////////////////////////////////////////

// +FHDR -  Semiconductor Reuse Standard File Header Section  -------
// FILE NAME      : plic_gateway.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2017-07-01  rherveille  initial release
//         2017-09-12  rherveille  Added 'claim' and 'complete'
// ------------------------------------------------------------------
// KEYWORDS : RISC-V PLATFORM LEVEL INTERRUPT CONTROLLER - PLIC
// ------------------------------------------------------------------
// PURPOSE  : PLIC Gateway, input section for each interrupt source
//            Supports edge-level triggered selection and interrupt
//            pending counter for events (edge triggered interrupts)
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE  DESCRIPTION              DEFAULT UNITS
//  MAX_PENDING_COUNT 0+     Max. pending interrupts  0
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : external asynchronous active low; rst_n
//   Clock Domains       : 1, clk, rising edge
//   Critical Timing     : 
//   Test Features       : na
//   Asynchronous I/F    : no
//   Scan Methodology    : na
//   Instantiations      : none
//   Synthesizable (y/n) : Yes
//   Other               :                                         
// -FHDR-------------------------------------------------------------

module plic_gateway #(
  parameter MAX_PENDING_COUNT = 16
)
(
  input      rst_n,    //Active low asynchronous reset
             clk,      //System clock

  input      src,      //Interrupt source
  input      edge_lvl, //(rising) edge or level triggered

  output     ip,       //interrupt pending
  input      claim,    //interrupt claimed
  input      complete  //interrupt handling completed
);


  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  localparam SAFE_MAX_PENDING_COUNT = (MAX_PENDING_COUNT >= 0) ? MAX_PENDING_COUNT : 0;
  localparam COUNT_BITS = $clog2(SAFE_MAX_PENDING_COUNT+1);
  localparam LEVEL = 1'b0,
             EDGE  = 1'b1;


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  logic                  src_dly, src_edge;
  logic [COUNT_BITS-1:0] nxt_pending_cnt, pending_cnt;
  logic                  decr_pending;
  logic [           1:0] ip_state;


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  /** detect rising edge on interrupt source
   */
  always @(posedge clk,negedge rst_n)
    if (!rst_n)
    begin
        src_dly  <= 1'b0;
        src_edge <= 1'b0;
    end
    else
    begin
        src_dly  <= src;
        src_edge <= src & ~src_dly;
    end


  /** generate pending-counter
   */
  always_comb
    case ({decr_pending,src_edge})
      2'b00: nxt_pending_cnt = pending_cnt; //do nothing
      2'b01: if (pending_cnt < SAFE_MAX_PENDING_COUNT)
               nxt_pending_cnt = pending_cnt +'h1;
             else
               nxt_pending_cnt = pending_cnt;
      2'b10: if (pending_cnt > 0)
               nxt_pending_cnt = pending_cnt -'h1;
             else
               nxt_pending_cnt = pending_cnt;
      2'b11: nxt_pending_cnt = pending_cnt; //do nothing
    endcase


  always @(posedge clk,negedge rst_n)
    if      (!rst_n           ) pending_cnt <= 'h0;
    else if ( edge_lvl != EDGE) pending_cnt <= 'h0;
    else                        pending_cnt <= nxt_pending_cnt;


  /** generate interrupt pending
   *  1. assert IP
   *  2. target 'claims IP'
   *     clears IP bit
   *     blocks IP from asserting again
   *  3. target 'completes' 
   */
  always @(posedge clk,negedge rst_n)
    if (!rst_n)
    begin
        ip_state     <= 2'b00;
        decr_pending <= 1'b0;
    end
    else
    begin
        decr_pending <= 1'b0; //strobe signal

        case (ip_state)
          //wait for interrupt request from source
          2'b00  : if ((edge_lvl == EDGE  && |nxt_pending_cnt) ||
                       (edge_lvl == LEVEL && src             ))
                   begin
                       ip_state     <= 2'b01;
                       decr_pending <= 1'b1; //decrement 
                   end

          //wait for 'interrupt claim'
          2'b01  : if (claim   ) ip_state <= 2'b10;

          //wait for 'interrupt completion'
          2'b10  : if (complete) ip_state <= 2'b00;

          //oops ...
          default: ip_state <= 2'b00;
        endcase
    end

  //IP-bit is ip_state LSB
  assign ip = ip_state[0];

endmodule : plic_gateway
