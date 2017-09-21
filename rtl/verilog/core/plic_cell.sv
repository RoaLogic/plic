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
// FILE NAME      : plic_cell.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2017-07-01  rherveille  initial release
// ------------------------------------------------------------------
// KEYWORDS : RISC-V PLATFORM LEVEL INTERRUPT CONTROLLER - PLIC
// ------------------------------------------------------------------
// PURPOSE  : One source-target combination. Single cell of the 
//            source-target matrix.
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE  DESCRIPTION              DEFAULT UNITS
//  ID                1+     ID (source number)       1
//  SOURCES           1+     No. of interupt sources  8
//  PRIORITIES        1+     No. of priority levels   8
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : none 
//   Clock Domains       : none, asynchronous block
//   Critical Timing     : 
//   Test Features       : 
//   Asynchronous I/F    : Fully asynchronous block
//   Scan Methodology    : na
//   Instantiations      : none
//   Synthesizable (y/n) : Yes
//   Other               : End-points (registers) are in the
//                         plic_target module
// -FHDR-------------------------------------------------------------

module plic_cell #(
  parameter ID         = 1,
  parameter SOURCES    = 8,
  parameter PRIORITIES = 7,

  //These should be localparams, but that's not supported by all tools yet
  parameter SOURCES_BITS  = $clog2(SOURCES +1), //0=reserved
  parameter PRIORITY_BITS = $clog2(PRIORITIES)
)
(
  //Interrupt Request
  input                      ip_i,        //Interrupt pending
  input                      ie_i,        //Interrupt Enable
  input  [PRIORITY_BITS-1:0] ipriority_i, //Interrupt priority

  //from previous cell
  input  [SOURCES_BITS -1:0] id_i,        //previous interrupt request
  input  [PRIORITY_BITS-1:0] priority_i,  //previous interrupt priority

  //to next cell
  output [SOURCES_BITS -1:0] id_o,        //current interrupt request
  output [PRIORITY_BITS-1:0] priority_o   //current interrupt priority
);
  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  logic interrupt,
        gt_priority;

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  /** Handle interrupt?
   * interrupt = InterruptPending && InterruptEnable && (Priority > 0)
   * Lower IDs take priority over higher IDs
   * As such (Priority > 0) is covered by gt_priority.
   */
  assign interrupt   = ip_i & ie_i;
  assign gt_priority = ipriority_i >  priority_i;


  /** Mux output
   *
   */
  assign id_o       = (interrupt && gt_priority) ? ID          : id_i;
  assign priority_o = (interrupt && gt_priority) ? ipriority_i : priority_i;

endmodule : plic_cell
