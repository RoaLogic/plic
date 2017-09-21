/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//   RISC-V Platform-Level Interrupt Controller Testbench (top)    //
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
//    This soure file is free software; you can redistribute it    //
//  and/or modify it under the terms of the GNU General Public     //
//  License as published by the Free Software Foundation,          //
//  either version 3 of the License, or (at your option) any later //
//  versions. The current text of the License can be found at:     //
//  http://www.gnu.org/licenses/gpl.html                           //
//                                                                 //
//    This source file is distributed in the hope that it will be  //
//  useful, but WITHOUT ANY WARRANTY; without even the implied     //
//  warranty of MERCHANTABILITY or FITTNESS FOR A PARTICULAR       //
//  PURPOSE. See the GNU General Public License for more details.  //
//                                                                 //
/////////////////////////////////////////////////////////////////////

module testbench_top;
  parameter SOURCES           = 35; //Number of interrupt sources
  parameter TARGETS           = 4;  //Number of interrupt targets
  parameter PRIORITIES        = 7;  //Number of priority levels
  parameter MAX_PENDING_COUNT = 8;  //Number of 'event' counts
  parameter HAS_THRESHOLD     = 1;  //Has 'Priority' Threshold?
  parameter HAS_CONFIG_REG    = 1;  //Has 'config' register?

  parameter HADDR_SIZE        = 16;
  parameter HDATA_SIZE        = 32;


  /////////////////////////////////////////////////////////
  //
  // Variables
  //
  //AHB signals
  logic                   HSEL;
  logic [HADDR_SIZE -1:0] HADDR;
  logic [HDATA_SIZE -1:0] HWDATA;
  logic [HDATA_SIZE -1:0] HRDATA;
  logic                   HWRITE;
  logic [            2:0] HSIZE;
  logic [            2:0] HBURST;
  logic [            3:0] HPROT;
  logic [            1:0] HTRANS;
  logic                   HMASTLOCK;
  logic                   HREADY;
  logic                   HREADYOUT;
  logic                   HRESP;

  //Interrupt signals
  logic [SOURCES    -1:0] src;
  logic [TARGETS    -1:0] irq;


  /////////////////////////////////////////////////////////
  //
  // Clock & Reset
  //
  bit HCLK, HRESETn;
  initial begin : gen_HCLK
      HCLK <= 1'b0;
      forever #10 HCLK = ~ HCLK;
  end : gen_HCLK

  initial begin : gen_HRESETn;
    HRESETn = 1'b1;
    //ensure falling edge of HRESETn
    #10;
    HRESETn = 1'b0;
    #32;
    HRESETn = 1'b1;
  end : gen_HRESETn;


  /////////////////////////////////////////////////////////
  //
  // Instantiate the TB and DUT
  //
  test #(
    .HADDR_SIZE        ( HADDR_SIZE        ),
    .HDATA_SIZE        ( HDATA_SIZE        ),
    .SOURCES           ( SOURCES           ),
    .TARGETS           ( TARGETS           ),
    .PRIORITIES        ( PRIORITIES        ),
    .MAX_PENDING_COUNT ( MAX_PENDING_COUNT ),
    .HAS_THRESHOLD     ( HAS_THRESHOLD     ),
    .HAS_CONFIG_REG    ( HAS_CONFIG_REG    ))
  tb (
    .*
  );


  ahb3lite_plic_top #(
    .HADDR_SIZE        ( HADDR_SIZE        ),
    .HDATA_SIZE        ( HDATA_SIZE        ),

    .SOURCES           ( SOURCES           ),
    .TARGETS           ( TARGETS           ),
    .PRIORITIES        ( PRIORITIES        ),
    .MAX_PENDING_COUNT ( MAX_PENDING_COUNT ),
    .HAS_THRESHOLD     ( HAS_THRESHOLD     ),
    .HAS_CONFIG_REG    ( HAS_CONFIG_REG    )
  )
  dut (
    .*
  );
 
  assign HREADY = HREADYOUT;

endmodule : testbench_top
