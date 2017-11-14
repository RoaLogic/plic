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
  input                          rst_ni,      //Asynchronous active low reset
  input                          clk_i,       //System clock

  //Interrupt Request
  input                          ip_i,        //Interrupt pending
  input                          ie_i,        //Interrupt Enable
  input      [PRIORITY_BITS-1:0] priority_i,  //Interrupt priority

  output reg [SOURCES_BITS -1:0] id_o,        //Pending interrupt ID
  output reg [PRIORITY_BITS-1:0] priority_o   //Pending interrupt priority
);
  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  always @(posedge clk_i,negedge rst_ni)
    if      (!rst_ni      ) priority_o <= 0;
    else if ( ip_i && ie_i) priority_o <= priority_i;
    else                    priority_o <= 0;

  always @(posedge clk_i,negedge rst_ni)
    if      (!rst_ni      ) id_o <= 0;
    else if ( ip_i && ie_i) id_o <= ID;
    else                    id_o <= 0;

endmodule : plic_cell
