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
// FILE NAME      : ahb3lite_plic_top.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2017-07-05  rherveille  initial release
//         2017-09013  rherveille  Added 'claim' and 'complete'
// ------------------------------------------------------------------
// KEYWORDS : RISC-V PLATFORM LEVEL INTERRUPT CONTROLLER - PLIC
//            AHB3-Lite, AMBA
// ------------------------------------------------------------------
// PURPOSE  : AHB3-Lite Top Level
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE   DESCRIPTION              DEFAULT UNITS
//  HADDR_SIZE        [32,64] HADDR width              32
//  HDATA_SIZE        [32,64] HDATA width              32
//  SOURCES           1+      No. of interupt sources  16
//  TARGETS           1+      No. of interrupt targets 4
//  PRIORITIES        1+      No. of priority levels   8
//  MAX_PENDING_COUNT 0+      Max. pending events      8
//  HAS_THRESHOLD     [0,1]   Is 'threshold' impl.?    1
//  HAS_CONFIG_REG    [0,1]   Is 'config' implemented? 1
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : external asynchronous active low; HRESETn
//   Clock Domains       : 1, HCLK, rising edge
//   Critical Timing     : cell-array for each target
//   Test Features       : na
//   Asynchronous I/F    : no
//   Scan Methodology    : na
//   Instantiations      : plic_core, plic_dynamic_registers
//   Synthesizable (y/n) : Yes
//   Other               :                                         
// -FHDR-------------------------------------------------------------



module ahb3lite_plic_top #(
  //AHB Parameters
  parameter HADDR_SIZE = 32,
  parameter HDATA_SIZE = 32,

  //PLIC Parameters
  parameter SOURCES           = 35,  //Number of interrupt sources
  parameter TARGETS           = 4,   //Number of interrupt targets
  parameter PRIORITIES        = 8,   //Number of Priority levels
  parameter MAX_PENDING_COUNT = 8,   //Max. number of 'pending' events
  parameter HAS_THRESHOLD     = 1,   //Is 'threshold' implemented?
  parameter HAS_CONFIG_REG    = 1    //Is the 'configuration' register implemented?
)
(
  input                       HRESETn,
                              HCLK,

  //AHB Slave Interface
  input                       HSEL,
  input      [HADDR_SIZE-1:0] HADDR,
  input      [HDATA_SIZE-1:0] HWDATA,
  output reg [HDATA_SIZE-1:0] HRDATA,
  input                       HWRITE,
  input      [           2:0] HSIZE,
  input      [           2:0] HBURST,
  input      [           3:0] HPROT,
  input      [           1:0] HTRANS,
  output reg                  HREADYOUT,
  input                       HREADY,
  output                      HRESP,

  input      [SOURCES   -1:0] src,       //Interrupt sources
  output     [TARGETS   -1:0] irq        //Interrupt Requests
);

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  import ahb3lite_pkg::*;
  localparam HDATA_BYTES = (HDATA_SIZE+7)/8;   //number of bytes in HDATA
  localparam BE_SIZE     = HDATA_BYTES;

  localparam SOURCES_BITS     = $clog2(SOURCES+1);  //0=reserved
  localparam PRIORITY_BITS    = $clog2(PRIORITIES);


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
  logic                     ahb_we,
                            ahb_re;
  logic [BE_SIZE      -1:0] ahb_be;
  logic [HADDR_SIZE   -1:0] ahb_waddr;

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
  // Functions
  //

  /** AHB Accesses
   */
  function logic [6:0] address_offset;
    //returns a mask for the lesser bits of the address
    //meaning bits [  0] for 16bit data
    //             [1:0] for 32bit data
    //             [2:0] for 64bit data
    //etc

    //default value, prevent warnings
    address_offset = 0;

    //What are the lesser bits in HADDR?
    case (HDATA_SIZE)
          1024: address_offset = 7'b111_1111; 
           512: address_offset = 7'b011_1111;
           256: address_offset = 7'b001_1111;
           128: address_offset = 7'b000_1111;
            64: address_offset = 7'b000_0111;
            32: address_offset = 7'b000_0011;
            16: address_offset = 7'b000_0001;
       default: address_offset = 7'b000_0000;
    endcase
  endfunction : address_offset


  function logic [6:0] address_mask;
    //Returns a mask for the major bits of the address
    //meaning bits [HADDR_SIZE-1:0] for 8bits data
    //             [HADDR_SIZE-1:1] for 16bits data
    //             [HADDR_SIZE-1:2] for 32bits data
    //etc
    address_mask = ~address_offset();
  endfunction : address_mask


  function logic [BE_SIZE-1:0] gen_be;
    input [           2:0] hsize;
    input [HADDR_SIZE-1:0] haddr;

    logic [127:0] full_be;
    logic [  6:0] haddr_masked;

    //get number of active lanes for a 1024bit databus (max width) for this HSIZE
    case (hsize)
       HSIZE_B1024: full_be = 'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff; 
       HSIZE_B512 : full_be = 'hffff_ffff_ffff_ffff;
       HSIZE_B256 : full_be = 'hffff_ffff;
       HSIZE_B128 : full_be = 'hffff;
       HSIZE_DWORD: full_be = 'hff;
       HSIZE_WORD : full_be = 'hf;
       HSIZE_HWORD: full_be = 'h3;
       default    : full_be = 'h1;
    endcase

    //generate masked address
    haddr_masked = haddr & address_offset();

    //create byte-enable
    gen_be = full_be[BE_SIZE-1:0] << haddr_masked;
  endfunction : gen_be


  function logic [HDATA_SIZE-1:0] gen_wval;
    //Returns the new value for a register
    // if be[n] == '1' then gen_val[byte_n] = new_val[byte_n]
    // else                 gen_val[byte_n] = old_val[byte_n]
    input [HDATA_SIZE-1:0] old_val,
                           new_val;
    input [BE_SIZE   -1:0] be;

    for (int n=0; n < BE_SIZE; n++)
      gen_wval[n*8 +: 8] = be[n] ? new_val[n*8 +: 8] : old_val[n*8 +: 8];
  endfunction : gen_wval


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //


  /** AHB accesses
   */
  //The core supports zero-wait state accesses on all transfers.
  assign HREADYOUT = 1'b1;       //always ready
  assign HRESP     = HRESP_OKAY; //Never an error


  /** AHB Reads
   */
  assign ahb_re = HREADY & HSEL & !HWRITE & (HTRANS != HTRANS_BUSY) & (HTRANS != HTRANS_IDLE);


  /** AHB Writes
   */
  //generate internal write signal
  always @(posedge HCLK)
    if (HREADY) ahb_we <= HSEL & HWRITE & (HTRANS != HTRANS_BUSY) & (HTRANS != HTRANS_IDLE);
    else        ahb_we <= 1'b0;

  //decode Byte-Enables
  always @(posedge HCLK)
    if (HREADY) ahb_be <= gen_be(HSIZE,HADDR);

  //store write address
  always @(posedge HCLK)
    if (HREADY) ahb_waddr <= HADDR;


  /** Hookup Dynamic Register block
   */
  plic_dynamic_registers #(
    //Bus Interface Parameters
    .ADDR_SIZE  ( HADDR_SIZE ),
    .DATA_SIZE  ( HDATA_SIZE ),

    //PLIC Parameters
    .SOURCES           ( SOURCES           ),
    .TARGETS           ( TARGETS           ),
    .PRIORITIES        ( PRIORITIES        ),
    .MAX_PENDING_COUNT ( MAX_PENDING_COUNT ),
    .HAS_THRESHOLD     ( HAS_THRESHOLD     ),
    .HAS_CONFIG_REG    ( HAS_CONFIG_REG    )
  )
  dyn_register_inst (
    .rst_n    ( HRESETn         ), //Active low asynchronous reset
    .clk      ( HCLK            ), //System clock

    .we       ( HREADY & ahb_we ), //write when write-cycle and HREADY
    .re       ( HREADY & ahb_re ), //read when HREADY
    .be       ( ahb_be          ), //stored byte-enables
    .waddr    ( ahb_waddr       ), //stored write address
    .raddr    ( HADDR           ), //read address
    .wdata    ( HWDATA          ), //write data
    .rdata    ( HRDATA          ), //read data

    .el       ( el              ), //Edge/Level
    .ip       ( ip              ), //Interrupt Pending

    .ie       ( ie              ), //Interrupt Enable
    .p        ( p               ), //Priority
    .th       ( th              ), //Priority Threshold

    .id       ( id              ), //Interrupt ID
    .claim    ( claim           ), //Interrupt Claim
    .complete ( complete        )  //Interrupt Complete
 );


  /** Hookup PLIC Core
   */
  plic_core #(
    .SOURCES           ( SOURCES           ),
    .TARGETS           ( 4                 ),
    .PRIORITIES        ( PRIORITIES        ),
    .MAX_PENDING_COUNT ( MAX_PENDING_COUNT )
  )
  plic_core_inst (
    .rst_n     ( HRESETn  ),
    .clk       ( HCLK     ),

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

endmodule : ahb3lite_plic_top

