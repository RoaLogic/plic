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
// FILE NAME      : plic_priority_index.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2017-11-14  rherveille  initial release
// ------------------------------------------------------------------
// KEYWORDS : RISC-V PLATFORM LEVEL INTERRUPT CONTROLLER - PLIC
// ------------------------------------------------------------------
// PURPOSE  : PLIC Target - Priority Index
//            Builds a binary tree to search for the highest priority
//            and its associated ID
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE  DESCRIPTION              DEFAULT UNITS
//  SOURCES           1+     No. of interupt sources  8
//  PRIORITIES        1+     No. of priority levels   8
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : none
//   Clock Domains       : none
//   Critical Timing     :
//   Test Features       : na
//   Asynchronous I/F    : yes
//   Scan Methodology    : na
//   Instantiations      : Itself (recursive)
//   Synthesizable (y/n) : Yes
//   Other               :                                         
// -FHDR-------------------------------------------------------------

module plic_priority_index #(
  parameter SOURCES    = 16,
  parameter PRIORITIES = 7,
  parameter HI         = 16,
  parameter LO         = 0,

  //These should be localparams, but that's not supported by all tools yet
  parameter SOURCES_BITS  = $clog2(SOURCES +1), //0=reserved
  parameter PRIORITY_BITS = $clog2(PRIORITIES)
)
(
  input  [PRIORITY_BITS-1:0] priority_i [SOURCES], //Interrupt Priority
  input  [SOURCES_BITS -1:0] idx_i      [SOURCES],
  output [PRIORITY_BITS-1:0] priority_o,
  output [SOURCES_BITS -1:0] idx_o
);

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  logic [PRIORITY_BITS-1:0] priority_hi, priority_lo;
  logic [SOURCES_BITS -1:0] idx_hi,      idx_lo;

  //initial if (HI-LO>1) $display ("HI=%0d, LO=%0d -> hi(%0d,%0d) lo(%0d,%0d)", HI, LO, HI, HI-(HI-LO)/2, LO+(HI-LO)/2, LO);

  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //

  generate
    if (HI - LO > 1)
    begin
        plic_priority_index #(
          .SOURCES    ( SOURCES        ),
          .PRIORITIES ( PRIORITIES     ),
          .HI         ( LO + (HI-LO)/2 ),
          .LO         ( LO             )
        )
        lo (
          .priority_i ( priority_i  ),
          .idx_i      ( idx_i       ),
          .priority_o ( priority_lo ),
          .idx_o      ( idx_lo      )
        );

        plic_priority_index #(
          .SOURCES    ( SOURCES        ),
          .PRIORITIES ( PRIORITIES     ),
          .HI         ( HI             ),
          .LO         ( HI - (HI-LO)/2 )
        ) hi
        (
          .priority_i ( priority_i  ),
          .idx_i      ( idx_i       ),
          .priority_o ( priority_hi ),
          .idx_o      ( idx_hi      )
        );
    end
    else
    begin
        assign priority_lo = priority_i[LO];
        assign priority_hi = priority_i[HI];
        assign idx_lo      = idx_i     [LO];
        assign idx_hi      = idx_i     [HI];
    end
  endgenerate

  assign priority_o = priority_hi > priority_lo ? priority_hi : priority_lo;
  assign idx_o      = priority_hi > priority_lo ? idx_hi      : idx_lo;

endmodule : plic_priority_index

