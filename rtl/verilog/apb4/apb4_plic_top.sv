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
//             Copyright (C) 2017-2021 ROA Logic BV                //
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
// FILE NAME      : apb4_plic_top.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2021-10-27  rherveille  initial release
// ------------------------------------------------------------------
// KEYWORDS : RISC-V PLATFORM LEVEL INTERRUPT CONTROLLER - PLIC
//            APB, APB4, AMBA
// ------------------------------------------------------------------
// PURPOSE  : APB4-Lite Top Level
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE   DESCRIPTION              DEFAULT UNITS
//  PADDR_SIZE        [32,64] PADDR width              32
//  PDATA_SIZE        [32,64] PDATA width              32
//  SOURCES           1+      No. of interupt sources  16
//  TARGETS           1+      No. of interrupt targets 4
//  PRIORITIES        1+      No. of priority levels   8
//  MAX_PENDING_COUNT 0+      Max. pending events      8
//  HAS_THRESHOLD     [0,1]   Is 'threshold' impl.?    1
//  HAS_CONFIG_REG    [0,1]   Is 'config' implemented? 1
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : external asynchronous active low; PRESETn
//   Clock Domains       : 1, PCLK, rising edge
//   Critical Timing     : cell-array for each target
//   Test Features       : na
//   Asynchronous I/F    : no
//   Scan Methodology    : na
//   Instantiations      : plic_core, plic_dynamic_registers
//   Synthesizable (y/n) : Yes
//   Other               :                                         
// -FHDR-------------------------------------------------------------



module apb4_plic_top #(
  //AHB Parameters
  parameter PADDR_SIZE = 32,
  parameter PDATA_SIZE = 32,

  //PLIC Parameters
  parameter SOURCES           = 64,//35,  //Number of interrupt sources
  parameter TARGETS           = 4,   //Number of interrupt targets
  parameter PRIORITIES        = 8,   //Number of Priority levels
  parameter MAX_PENDING_COUNT = 8,   //Max. number of 'pending' events
  parameter HAS_THRESHOLD     = 1,   //Is 'threshold' implemented?
  parameter HAS_CONFIG_REG    = 1    //Is the 'configuration' register implemented?
)
(
  input                         PRESETn,
                                PCLK,

  //AHB Slave Interface
  input                         PSEL,
  input                         PENABLE,
  input      [PADDR_SIZE  -1:0] PADDR,
  input                         PWRITE,
  input      [PDATA_SIZE/8-1:0] PSTRB,
  input      [PDATA_SIZE  -1:0] PWDATA,
  output reg [PDATA_SIZE  -1:0] PRDATA,
  output                        PREADY,
  output                        PSLVERR,

  input      [SOURCES     -1:0] src,       //Interrupt sources
  output     [TARGETS     -1:0] irq        //Interrupt Requests
);

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //

  localparam SOURCES_BITS  = $clog2(SOURCES+1);  //0=reserved
  localparam PRIORITY_BITS = $clog2(PRIORITIES);


/** Address map
 * Configuration (if implemented)
 * GateWay control
 *   [SOURCES      -1:0] el
 *   [PRIORITY_BITS-1:0] priority  [SOURCES]
 *
 * PLIC-Core
 *   [SOURCES      -1:0] ie        [TARGETS]
 *   [PRIORITY_BITS-1:0] threshold [TARGETS] (if implemented)
 *
 * Target
 *   [SOURCES_BITS -1:0] id        [TARGETS]
 */

  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  //AHB write action
  logic                     apb_we,
                            apb_re;

  //Decoded registers
  logic [SOURCES      -1:0] el,
                            ip;
  logic [PRIORITY_BITS-1:0] p  [SOURCES];
  logic [SOURCES      -1:0] ie [TARGETS];
  logic [PRIORITY_BITS-1:0] th [TARGETS];
  logic [SOURCES_BITS -1:0] id [TARGETS];

  logic [TARGETS      -1:0] claim,
                            complete;


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //


  /** APB accesses
   */
  //The core supports zero-wait state accesses on all transfers.
  assign PREADY  = 1'b1;  //always ready
  assign PSLVERR = 1'b0;  //Never an error


  /** APB Read/Write
   */
  assign apb_re = PSEL & ~PENABLE & ~PWRITE;
  assign apb_we = PSEL &  PENABLE &  PWRITE;


  /** Hookup Dynamic Register block
   */
  plic_dynamic_registers #(
    //Bus Interface Parameters
    .ADDR_SIZE  ( PADDR_SIZE ),
    .DATA_SIZE  ( PDATA_SIZE ),

    //PLIC Parameters
    .SOURCES           ( SOURCES           ),
    .TARGETS           ( TARGETS           ),
    .PRIORITIES        ( PRIORITIES        ),
    .MAX_PENDING_COUNT ( MAX_PENDING_COUNT ),
    .HAS_THRESHOLD     ( HAS_THRESHOLD     ),
    .HAS_CONFIG_REG    ( HAS_CONFIG_REG    )
  )
  dyn_register_inst (
    .rst_n    ( PRESETn  ), //Active low asynchronous reset
    .clk      ( PCLK     ), //System clock

    .we       ( apb_we   ), //write cycle
    .re       ( apb_re   ), //read cycle
    .be       ( PSTRB    ), //PSTRB=byte-enables
    .waddr    ( PADDR    ), //write address
    .raddr    ( PADDR    ), //read address
    .wdata    ( PWDATA   ), //write data
    .rdata    ( PRDATA   ), //read data

    .el       ( el       ), //Edge/Level
    .ip       ( ip       ), //Interrupt Pending

    .ie       ( ie       ), //Interrupt Enable
    .p        ( p        ), //Priority
    .th       ( th       ), //Priority Threshold

    .id       ( id       ), //Interrupt ID
    .claim    ( claim    ), //Interrupt Claim
    .complete ( complete )  //Interrupt Complete
 );


  /** Hookup PLIC Core
   */
  plic_core #(
    .SOURCES           ( SOURCES           ),
    .TARGETS           ( TARGETS           ),
    .PRIORITIES        ( PRIORITIES        ),
    .MAX_PENDING_COUNT ( MAX_PENDING_COUNT )
  )
  plic_core_inst (
    .rst_n     ( PRESETn  ),
    .clk       ( PCLK     ),

    .src       ( src      ),
    .el        ( el       ),
    .ip        ( ip       ),
    .ie        ( ie       ),
    .ipriority ( p        ),
    .threshold ( th       ),

    .ireq      ( irq      ),
    .id        ( id       ),
    .claim     ( claim    ),
    .complete  ( complete )
  );

endmodule : apb4_plic_top

