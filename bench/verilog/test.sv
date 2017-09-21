/////////////////////////////////////////////////////////////////////
//   ,------.                    ,--.                ,--.          //
//   |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---.    //
//   |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--'    //
//   |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--.    //
//   `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---'    //
//                                             `---'               //
//   RISC-V Platform-Level Interrupt Controller Testbench (Tests)  //
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

module test #(
  parameter HADDR_SIZE        = 16,
  parameter HDATA_SIZE        = 32,

  parameter SOURCES           = 16,  //Number of interrupt sources
  parameter TARGETS           = 4,   //Number of interrupt targets
  parameter PRIORITIES        = 7,   //Number of Priority levels
  parameter MAX_PENDING_COUNT = 8,   //
  parameter HAS_THRESHOLD     = 1, 
  parameter HAS_CONFIG_REG    = 1
)
(
  input                       HRESETn,
                              HCLK,

  output                      HSEL,
  output     [HADDR_SIZE-1:0] HADDR,
  output     [HDATA_SIZE-1:0] HWDATA,
  input      [HDATA_SIZE-1:0] HRDATA,
  output                      HWRITE,
  output     [           2:0] HSIZE,
  output     [           2:0] HBURST,
  output     [           3:0] HPROT,
  output     [           1:0] HTRANS,
  output                      HMASTLOCK,
  input                       HREADY,
  input                       HRESP,

  output reg [SOURCES   -1:0] src,
  input      [TARGETS   -1:0] irq
);

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  import ahb3lite_pkg::*;

  localparam BE_SIZE       = (HDATA_SIZE+7)/8;
  localparam PRIORITY_BITS = $clog2(PRIORITIES);

  typedef enum {CONFIG, EDGE_LEVEL, IPRIORITY, IENABLE, PTHRESHOLD, ID} registers_t;

  //Configuration Bits
  localparam MAX_SOURCES_BITS   = 16;
  localparam MAX_TARGETS_BITS   = 16;
  localparam MAX_PRIORITY_BITS  = MAX_SOURCES_BITS;
  localparam HAS_THRESHOLD_BITS = 1;

  //How many CONFIG registers are there (only 1)
  localparam CONFIG_REGS      = HAS_CONFIG_REG == 0 ? 0 : (MAX_SOURCES_BITS + MAX_TARGETS_BITS + MAX_PRIORITY_BITS + HAS_THRESHOLD_BITS + HDATA_SIZE -1) / HDATA_SIZE;

  //Amount of Edge/Level registers
  localparam EDGE_LEVEL_REGS  = (SOURCES + HDATA_SIZE -1) / HDATA_SIZE;

  //Amount of Interrupt Enable registers
  localparam IE_REGS          = EDGE_LEVEL_REGS * TARGETS;

  //Each PRIORITY field starts at a new nibble boundary
  //Get the number of nibbles in 'PRIORITY_BITS' ?
  localparam PRIORITY_NIBBLES = (PRIORITY_BITS +3 -1) / 4;

  //How many PRIORITY fields fit in 1 register?
  localparam PRIORITY_FIELDS_PER_REG = HDATA_SIZE / (PRIORITY_NIBBLES*4); 

  //Amount of Priority registers
  localparam PRIORITY_REGS    = (SOURCES + PRIORITY_FIELDS_PER_REG -1) / PRIORITY_FIELDS_PER_REG;

  //Amount of Threshold registers
  localparam PTHRESHOLD_REGS = HAS_THRESHOLD == 0 ? 0 : TARGETS;

  //Amount of ID registers
  localparam ID_REGS = TARGETS;

  //Total amount of registers
  localparam TOTAL_REGS       = CONFIG_REGS + EDGE_LEVEL_REGS + IE_REGS + PRIORITY_REGS + PTHRESHOLD_REGS + ID_REGS;


  //////////////////////////////////////////////////////////////////
  //
  // Functions
  //
  function automatic registers_t register_function;
    //return register-type for specified register
    input int r;

    int idx;
    idx = r;

    //1. Configuration Register
    if (idx < CONFIG_REGS  ) return CONFIG;
    idx -= CONFIG_REGS;

    //2. Gateway control registers
    //  Edge/Level
    //  Interrupt Pending/Acknowledge
    if (idx < EDGE_LEVEL_REGS) return EDGE_LEVEL;
    idx -= EDGE_LEVEL_REGS;

    //3. PLIC Core fabric registers
    if (idx < PRIORITY_REGS) return IPRIORITY;
    idx -= PRIORITY_REGS;
    if (idx < IE_REGS      ) return IENABLE;
    idx -= IE_REGS;

    //4. Target Registers
    if (idx < PTHRESHOLD_REGS) return PTHRESHOLD;
    return ID;
  endfunction : register_function


  function automatic int register_idx;
    //return offset in register-type
    input int r;

    int idx;
    idx = r;

    //1. Configuration registers
    if (idx < CONFIG_REGS    ) return idx;
    idx -= CONFIG_REGS;

    //2. first Gateway control registers
    //  Edge/Level
    //  Interrupt Pending/Acknowledge
    if (idx < EDGE_LEVEL_REGS) return idx;
    idx -= EDGE_LEVEL_REGS;

    //3. PLIC Core fabric registers
    if (idx < PRIORITY_REGS  ) return idx;
    idx -= PRIORITY_REGS;
    if (idx < IE_REGS        ) return idx;
    idx -= IE_REGS;

    //4. TARGET registers
    if (idx < PTHRESHOLD_REGS) return idx;
    idx -=PTHRESHOLD_REGS;
    return idx;
  endfunction : register_idx


  function string register_function_name;
    //returns the 'string' name associated with a register type
    input registers_t function_number;

    string name_array[registers_t];
    name_array[CONFIG    ] = "Configuration";
    name_array[EDGE_LEVEL] = "Edge/Level";
    name_array[IENABLE   ] = "Interrupt Enable";
    name_array[IPRIORITY ] = "Interrupt Priority";
    name_array[PTHRESHOLD] = "Priority Threshold";
    name_array[ID        ] = "ID";

    return name_array[function_number];
  endfunction : register_function_name


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //
  int reset_watchdog,
      got_reset,
      errors;

  /////////////////////////////////////////////////////////
  //
  // Instantiate the AHB-Master
  //
  ahb3lite_master_bfm #(
    .HADDR_SIZE ( HADDR_SIZE ),
    .HDATA_SIZE ( HDATA_SIZE )
  )
  ahb_mst_bfm (
    .*
  );


  initial
  begin
      errors         = 0;
      reset_watchdog = 0;
      got_reset      = 0;

      forever
      begin
          reset_watchdog++;
          @(posedge HCLK);
          if (!got_reset && reset_watchdog == 1000)
              $fatal(-1,"HRESETn not asserted\nTestbench requires an AHB reset");
      end
  end


  always @(negedge HRESETn)
  begin
      //wait for reset to negate
      @(posedge HRESETn);
      got_reset = 1;

      welcome_text();

      //check initial values
      test_reset_register_values();

      //Test dynamic register access to EL
      test_el();

      //Test a single interrupt source
      test_single();


      //Finish simulation
      repeat (100) @(posedge HCLK);
      finish_text();
      $finish();
  end


  /////////////////////////////////////////////////////////
  //
  // Tasks
  //
  task welcome_text();
    $display ("------------------------------------------------------------");
    $display (" ,------.                    ,--.                ,--.       ");
    $display (" |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---. ");
    $display (" |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--' ");
    $display (" |  |\\  \\ ' '-' '\\ '-'  |    |  '--.' '-' ' '-' ||  |\\ `--. ");
    $display (" `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---' ");
    $display ("                                           `---'            ");
    $display (" AHB3Lite PLIC Testbench Initialized                        ");
    $display ("------------------------------------------------------------");
  endtask : welcome_text


  task finish_text();
    if (errors>0)
    begin
        $display ("------------------------------------------------------------");
        $display (" AHB3Lite PLIC Testbench failed with (%0d) errors @%0t", errors, $time);
        $display ("------------------------------------------------------------");
    end
    else
    begin
        $display ("------------------------------------------------------------");
        $display (" AHB3Lite PLIC Testbench finished successfully @%0t", $time);
        $display ("------------------------------------------------------------");
    end
  endtask : finish_text


  /** test_reset_register_values
   *  Test if all register are zero after reset
   */
  task test_reset_register_values;
    int r;

    logic [HDATA_SIZE-1:0] rbuffer[][];
    logic [          63:0] config_reg_contents;

    $display ("Checking reset values ...");

    //Is 'config' implemented?
    if (HAS_CONFIG_REG)
    begin
        //create new read-buffers (1 per transaction)
        rbuffer = new[CONFIG_REGS];

        //read register(s) contents
        for (r=0; r < CONFIG_REGS; r++)
        begin
            rbuffer[r] = new[1];
            ahb_mst_bfm.read (r*HDATA_SIZE/8,
                              rbuffer[r],
                              HDATA_SIZE == 32 ? HSIZE_WORD : HSIZE_DWORD,
                              HBURST_SINGLE);
        end
        ahb_mst_bfm.idle(); //Idle the AHB bus
        wait fork;          //Wait for all transactions to finish

        //copy contents into 'config_reg_contents'
        for (r=0; r<CONFIG_REGS; r++)
          config_reg_contents[r*32 +: HDATA_SIZE] = rbuffer[r][0];


        $display ("  Checking Configuration (%x)", config_reg_contents);
        //Check values
        if (config_reg_contents[15: 0] !== SOURCES)
        begin
            errors++;
            $error("Configuration register error (SOURCES). Expected %0d, got %0d", SOURCES, config_reg_contents[15: 0]);
        end
        if (config_reg_contents[31:16] !== TARGETS)
        begin
            errors++;
            $error("Configuration register error (TARGETS). Expected %0d, got %0d", TARGETS, config_reg_contents[31:16]);
        end
        if (config_reg_contents[47:32] !== PRIORITIES)
        begin
            errors++;
            $error("Configuration register error (PRIORITY). Expected %0d, got %0d", PRIORITIES, config_reg_contents[47:32]);
        end
        if (config_reg_contents[48] !== HAS_THRESHOLD)
        begin
            errors++;
            $error("Configuration register error (THRESHOLD). Expected %0d, got %0d", HAS_THRESHOLD, config_reg_contents[47]);
        end

        //discard buffers
        rbuffer.delete();

        $display ("  Configuration register(s) check ... %s", errors !== 0 ? "FAILED" : "PASSED");
    end


    //check if other registers are zero
    rbuffer = new[1];
    rbuffer[0] = new[1];

    for (r=0; r < TOTAL_REGS; r++)
      if ( register_function(r) !== CONFIG) // && register_function(r) !== IP_IACK)
      begin
          $write ("  Checking [0x%4x] %s ... ", r*HDATA_SIZE/8, register_function_name( register_function(r) ));
          ahb_mst_bfm.read (r*HDATA_SIZE/8,
                            rbuffer[0],
                            HDATA_SIZE == 32 ? HSIZE_WORD : HSIZE_DWORD,
                            HBURST_SINGLE);
          ahb_mst_bfm.idle(); //Idle the AHB bus
          wait fork;          //Wait for all transactions to finish

          if (rbuffer[0][0] !== {HDATA_SIZE{1'b0}})
          begin
              $display ("FAILED");
              errors++;
              $error ("%s is not zero", register_function_name( register_function(r) ));
          end
          else
          begin
              $display ("PASSED");
          end
      end

    //discard buffers
    rbuffer.delete();
  endtask : test_reset_register_values


  /* Perform bit tests on EL register
   * This tests dynamic register read/write capabilities
   *  and configuration of EL
   */
  task test_el;
    int r, i;
    int base_address;
    int hsize, hburst, error, tsize;

    logic [HDATA_SIZE-1:0] rbuffer[][], wbuffer[][];

    //create buffers
    wbuffer = new[EDGE_LEVEL_REGS];
    rbuffer = new[EDGE_LEVEL_REGS];

    base_address = CONFIG_REGS; //EL starts after CONFIG

    $display("Testing register access ... ");

    for (hsize =  (HDATA_SIZE == 64) ? HSIZE_DWORD : HSIZE_WORD;
         hsize >= 0;
         hsize--)
    begin
        error = 0;

        case (hsize)
          HSIZE_DWORD: begin
                           hburst = HBURST_SINGLE;
                           tsize  = 64;
                           $write("  Testing dword (64bit) accesses ... ");
                       end
          HSIZE_WORD : begin
                           hburst = HBURST_SINGLE;
                           tsize  = 32;
                           $write("  Testing word (32bit) accesses ... ");
                       end
          HSIZE_HWORD: begin
                           hburst = (HDATA_SIZE == 64) ? HBURST_INCR4 : HBURST_SINGLE;
                           tsize  = 16;
                           $write("  Testing hword (16bit) accesses ... ");
                       end
          HSIZE_BYTE : begin
                           hburst = (HDATA_SIZE == 64) ? HBURST_INCR8 : HBURST_INCR4;
                           tsize  = 8;
                           $write("  Testing byte burst (8bit) accesses ... ");
                       end
        endcase


        //Write test values
        for (r=0; r<EDGE_LEVEL_REGS; r++)
        begin
            wbuffer[r] = new[HDATA_SIZE / tsize];
            rbuffer[r] = new[HDATA_SIZE / tsize];

            for (i=0; i<HDATA_SIZE/tsize; i++)
            begin
                wbuffer[r][i] = $random;

                case (hsize)
                  HSIZE_BYTE : wbuffer[r][i] &= 'hff;
                  HSIZE_HWORD: wbuffer[r][i] &= 'hffff;
                  HSIZE_WORD : wbuffer[r][i] &= 'hffff_ffff;
                endcase
            end //next i
          end //next r

        for (r=0; r<EDGE_LEVEL_REGS; r++)
          if (hburst == HBURST_SINGLE)
          begin
              logic [HDATA_SIZE-1:0] tmp[];    //local storage
              tmp = new[1];

              for (i=0; i<HDATA_SIZE/tsize; i++)
              begin
                  tmp[0] = wbuffer[r][i];
                  ahb_mst_bfm.write( ((base_address + r) * HDATA_SIZE/8) + (i * tsize/8),
                                      tmp,
                                      hsize,
                                      hburst); //write register
              end

              tmp.delete();
          end
          else
          begin
              ahb_mst_bfm.write( (base_address + r) * HDATA_SIZE/8,
                                  wbuffer[r],
                                  hsize,
                                  hburst);     //write register
          end
        ahb_mst_bfm.idle();                    //wait for HWDATA


        //Read test values
        for (r=0; r<EDGE_LEVEL_REGS; r++)
          if (hburst == HBURST_SINGLE)
          begin
              logic [HDATA_SIZE-1:0] tmp[][];  //local storage
              tmp = new[HDATA_SIZE/tsize];

              for (i=0; i<HDATA_SIZE/tsize; i++)
              begin
                  tmp[i] = new[1];
                  ahb_mst_bfm.read ( ((base_address + r) * HDATA_SIZE/8) + (i*tsize/8),
                                     tmp[i],
                                     hsize,
                                     hburst);  //read register
                  rbuffer[r][i] = tmp[i][0];
              end

              wait fork;

              for (i=0; i<HDATA_SIZE/tsize; i++)
                  rbuffer[r][i] = tmp[i][0];

              tmp.delete();
          end
          else
          begin
              ahb_mst_bfm.read ( (base_address + r) * HDATA_SIZE/8,
                                 rbuffer[r],
                                 hsize,
                                 hburst);      //read register
          end
        ahb_mst_bfm.idle();                    //Idle bus
        wait fork;                             //wait for all threads to complete

        for (r=0; r<EDGE_LEVEL_REGS; r++)
          for (int beat=0; beat<rbuffer[r].size(); beat++)
          begin
              //mask byte ...
              case (hsize)
                HSIZE_BYTE : rbuffer[r][beat] &= 'hff;
                HSIZE_HWORD: rbuffer[r][beat] &= 'hffff;
                HSIZE_WORD : rbuffer[r][beat] &= 'hffff_ffff;
              endcase

              //exception if register is not fully used
              if (SOURCES < (r+1)*HDATA_SIZE)
              begin
                  if      ( (SOURCES % HDATA_SIZE) / ((beat+1)*tsize) )
                    ;                                                //do nothing
                  else if ( (SOURCES % HDATA_SIZE) < ( beat   *tsize) )
                    wbuffer[r][beat] = 'h0;                          //always read '0'
                   else
                    wbuffer[r][beat] &= (1 << (SOURCES % tsize)) -1; //partial byte
              end

              if (rbuffer[r][beat] !== wbuffer[r][beat])
              begin
                  error = 1;
                  errors++;
                  $error ("%0d,%0d: got %x, expected %x", r, beat, rbuffer[r][beat], wbuffer[r][beat]);
              end
          end

        if (error) $display("FAILED");
        else       $display("OK");
    end


    //reset registers to all '0'
    wbuffer[0][0] = 0;
    for (r=0; r<EDGE_LEVEL_REGS; r++)
      ahb_mst_bfm.write( (base_address + r) * HDATA_SIZE/8,
                          wbuffer[0],
                          HDATA_SIZE == 64 ? HSIZE_DWORD : HSIZE_WORD,
                          HBURST_SINGLE); //write register
    ahb_mst_bfm.idle(); //Idle the AHB bus
    wait fork;          //Wait for all transactions to finish

    //discard buffers
    rbuffer.delete();
    wbuffer.delete();
  endtask : test_el


  /** Test a single Interrupt Source
   */
  task test_single();
    //clear all IE, except one
    int r, s, t;
    int el_base_address, //Edge/Level registers base address
        pr_base_address, //Priority registers base address
        ie_base_address, //Interrupt Enable registers base address
        th_base_address, //Threshold register base address
        id_base_address; //ID registers base address
    logic [HDATA_SIZE-1:0] rbuffer[], wbuffer[];

    //Set base register addresses ...
    el_base_address = CONFIG_REGS;
    pr_base_address = el_base_address + EDGE_LEVEL_REGS;
    ie_base_address = pr_base_address + PRIORITY_REGS;
    th_base_address = ie_base_address + IE_REGS;
    id_base_address = th_base_address + PTHRESHOLD_REGS;

    $display("Testing single interrupt ... ");

    //create buffers
    wbuffer = new[1];
    rbuffer = new[1];

    //clear all IE
    wbuffer[0] = 0;
    for (r=0; r < IE_REGS; r++)
      ahb_mst_bfm.write ( (ie_base_address + r) * HDATA_SIZE/8,
                          wbuffer,
                          HDATA_SIZE == 64 ? HSIZE_DWORD : HSIZE_WORD,
                          HBURST_SINGLE);

    //clear all EL
    for (r=0; r < EDGE_LEVEL_REGS; r++)
      ahb_mst_bfm.write ( (el_base_address + r) * HDATA_SIZE/8,
                          wbuffer,
                          HDATA_SIZE == 64 ? HSIZE_DWORD : HSIZE_WORD,
                          HBURST_SINGLE);

    //set all threshold to '0'
    for (r=0; r < PTHRESHOLD_REGS; r++)
      ahb_mst_bfm.write ( (th_base_address + r) * HDATA_SIZE/8,
                          wbuffer,
                          HDATA_SIZE == 64 ? HSIZE_DWORD : HSIZE_WORD,
                          HBURST_SINGLE);

    //set priority for all sources to '1'; '0' means 'never interrupt'
    wbuffer[0] = {PRIORITY_FIELDS_PER_REG { {PRIORITY_NIBBLES{4'h0}} | 4'h1} };
    for (r=0; r < PRIORITY_REGS; r++)
      ahb_mst_bfm.write ( (pr_base_address + r) * HDATA_SIZE/8,
                          wbuffer,
                          HDATA_SIZE == 64 ? HSIZE_DWORD : HSIZE_WORD,
                          HBURST_SINGLE);


    t = 0;
    s = 0;
    for (t=0; t < TARGETS; t++)
    for (s=0; s < SOURCES; s++)
    begin
        //check if there are any interrupts pending
        if (irq) $display ("Interrupts pending");

        //assert SRC[0]
        src[s] = 1'b1;

        //check if there are any interrupts pending
        if (irq)
        begin
            $error ("IRQ asserted (%b) while all IE disabled @%0t", irq, $time);
            errors++;
        end


        //enable interrupt
        //EDGE_LEVEL_REGS is used, as it holds the amount of IE-registers per target
        wbuffer[0] = 1 << (s % HDATA_SIZE);
        ahb_mst_bfm.write ( (ie_base_address + (t * EDGE_LEVEL_REGS) + (s / HDATA_SIZE)) * HDATA_SIZE/8,
                            wbuffer,
                            HDATA_SIZE == 64 ? HSIZE_DWORD : HSIZE_WORD,
                            HBURST_SINGLE);

        ahb_mst_bfm.idle(); //Idle the AHB bus
        wait fork; 

        //it takes 2 cycles for the interrupt to propagate
        repeat (3) @(posedge HCLK);

        //check if interrupt shows up at the expected target
        $write ("  Checking Source[%0d] -> IRQ[%0t]...", s, t);
        if (irq == 1 << t)
        begin
            $display ("PASSED");
        end
        else
        begin
            $display ("FAILED");
            $error ("Expected IRQ=%0x, received %h @%0t", 1 << t, irq, $time);
            errors++;
        end

        //check if ID is correct >> claims interrupt <<
        ahb_mst_bfm.read ( (id_base_address + t) * HDATA_SIZE/8,
                           rbuffer,
                           HDATA_SIZE == 32 ? HSIZE_WORD : HSIZE_DWORD,
                           HBURST_SINGLE);
        ahb_mst_bfm.idle(); //Idle the AHB bus
        wait fork;          //Wait for all transactions to finish

        $write ("  Checking ID/Claim Interrupt ...");
        if (rbuffer[0] == s+1)
        begin
            $display ("PASSED");
        end
        else
        begin
            $display ("FAILED");
            $error ("Expected ID=%0d, received %h @%0t", s+1, rbuffer[0], $time);
            errors++;
        end

        //clear source
        src[s] = 1'b0;
        @(posedge HCLK);

        //complete interrupt -- dummy write to ID
        $display ("  Sending Interrupt Complete");
        ahb_mst_bfm.write ( (id_base_address +t) * HDATA_SIZE/8,
                             wbuffer,
                             HDATA_SIZE == 64 ? HSIZE_DWORD : HSIZE_WORD,
                             HBURST_SINGLE);

        $write ("  Checking IRQ cleared ...");
        if (irq == 0)
        begin
            $display ("PASSED");
        end
        else
        begin
            $display ("FAILED");
            $error ("Expected IRQ=0, received %d @%0t", irq, $time);
            errors++;
        end

        //disable interrupt
        wbuffer[0] = 0;
        ahb_mst_bfm.write ( (ie_base_address + (t * EDGE_LEVEL_REGS) + (s / HDATA_SIZE)) * HDATA_SIZE/8,
                            wbuffer,
                            HDATA_SIZE == 64 ? HSIZE_DWORD : HSIZE_WORD,
                            HBURST_SINGLE);

    end //next s/t

    ahb_mst_bfm.idle(); //Idle the AHB bus
    wait fork;          //Wait for all transactions to finish
  endtask : test_single

endmodule : test
