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
// FILE NAME      : plic_dynamic_registers.sv
// DEPARTMENT     :
// AUTHOR         : rherveille
// AUTHOR'S EMAIL :
// ------------------------------------------------------------------
// RELEASE HISTORY
// VERSION DATE        AUTHOR      DESCRIPTION
// 1.0     2017-07-18  rherveille  initial release
//         2017-09-13  rherveille  Added 'claim' and 'complete'
// ------------------------------------------------------------------
// KEYWORDS : RISC-V PLATFORM LEVEL INTERRUPT CONTROLLER - PLIC
// ------------------------------------------------------------------
// PURPOSE  : Dynamic Register generation for PLIC
// ------------------------------------------------------------------
// PARAMETERS
//  PARAM NAME        RANGE   DESCRIPTION              DEFAULT UNITS
//  ADDR_SIZE         [32,64] read/write address width 32
//  DATA_SIZE         [32,64] read/write data width    32
//  SOURCES           1+      No. of interupt sources  8
//  TARGETS           1+      No. of interrupt targets 1
//  PRIORITIES        1+      No. of priority levels   8
//  MAX_PENDING_COUNT 0+      Max. pending interrupts  4
//  HAS_THRESHOLD     [0,1]   Is 'threshold' impl.?    1
//  HAS_CONFIG_REG    [0,1]   Is 'config' implemented? 1
// ------------------------------------------------------------------
// REUSE ISSUES 
//   Reset Strategy      : external asynchronous active low; rst_n
//   Clock Domains       : 1, clk, rising edge
//   Critical Timing     : na
//   Test Features       : na
//   Asynchronous I/F    : no
//   Scan Methodology    : na
//   Instantiations      : none
//   Synthesizable (y/n) : Yes
//   Other               :                                         
// -FHDR-------------------------------------------------------------

module plic_dynamic_registers #(
  //Bus Interface Parameters
  parameter ADDR_SIZE = 32,
  parameter DATA_SIZE = 32,

  //PLIC Parameters
  parameter SOURCES           = 8,   //Number of interrupt sources
  parameter TARGETS           = 1,   //Number of interrupt targets
  parameter PRIORITIES        = 8,   //Number of Priority levels
  parameter MAX_PENDING_COUNT = 4,   //
  parameter HAS_THRESHOLD     = 1,   //Is 'threshold' implemented?
  parameter HAS_CONFIG_REG    = 1,   //Is 'config' implemented?

  //These should be 'localparam', but that's not supported by all tools yet
  parameter BE_SIZE          = (DATA_SIZE+7)/8,
  parameter SOURCES_BITS     = $clog2(SOURCES+1),  //0=reserved
  parameter PRIORITY_BITS    = $clog2(PRIORITIES)
)
(
  input                          rst_n,        //Active low asynchronous reset
                                 clk,          //System clock

  input                          we,           //write enable
                                 re,           //read enable
  input      [BE_SIZE      -1:0] be,           //byte enable (writes only)
  input      [ADDR_SIZE    -1:0] waddr,        //write address
                                 raddr,        //read address
  input      [DATA_SIZE    -1:0] wdata,        //write data
  output reg [DATA_SIZE    -1:0] rdata,        //read data

  output     [SOURCES      -1:0] el,           //Edge/Level sensitive for each source
  input      [SOURCES      -1:0] ip,           //Interrupt Pending for each source

  output     [SOURCES      -1:0] ie[TARGETS],  //Interrupt enable per source, for each target
  output reg [PRIORITY_BITS-1:0] p [SOURCES],  //Priority for each source
  output reg [PRIORITY_BITS-1:0] th[TARGETS],  //Priority Threshold for each target

  input      [SOURCES_BITS -1:0] id[TARGETS],  //Interrupt ID for each target
  output reg [TARGETS      -1:0] claim,        //Interrupt Claim
  output reg [TARGETS      -1:0] complete      //Interrupt Complete
);

  //////////////////////////////////////////////////////////////////
  //
  // Constants
  //
  localparam DATA_BYTES    = BE_SIZE;            //number of bytes in DATA



/** Address map
 * Configuration
 * GateWay control
 *   [SOURCES      -1:0] el
 *   [PRIORITY_BITS-1:0] priority  [SOURCES]
 *
 * PLIC-Core
 *   [SOURCES      -1:0] ie        [TARGETS]
 *   [PRIORITY_BITS-1:0] threshold [TARGETS]
 *   [SOURCES_BITS -1:0] ID        [TARGETS
 */

  /** Calculate Register amount/offset
   *  Each register is DATA_SIZE wide
   */
  typedef enum {CONFIG, EL, IE, PRIORITY, THRESHOLD, ID} register_types;

  //Configuration Bits
  localparam MAX_SOURCES_BITS   = 16;
  localparam MAX_TARGETS_BITS   = 16;
  localparam MAX_PRIORITY_BITS  = MAX_SOURCES_BITS;
  localparam HAS_THRESHOLD_BITS = 1;

  //How many CONFIG registers are there (only 1)
  localparam CONFIG_REGS    = HAS_CONFIG_REG == 0 ? 0 : (MAX_SOURCES_BITS + MAX_TARGETS_BITS + MAX_PRIORITY_BITS + HAS_THRESHOLD_BITS + DATA_SIZE -1) / DATA_SIZE;

  //How many Edge/Level registers are there?
  localparam EL_REGS        = (SOURCES + DATA_SIZE -1) / DATA_SIZE;

  //How many IE registers are there?
  localparam IE_REGS        = EL_REGS * TARGETS;

  //How many nibbles are there in 'PRIORITY_BITS' ?
  //Each PRIORITY starts at a new nibble boundary
  localparam PRIORITY_NIBBLES = (PRIORITY_BITS +3 -1) / 4;

  //How many PRIORITY fields fit in 1 register?
  localparam PRIORITY_FIELDS_PER_REG = DATA_SIZE / (PRIORITY_NIBBLES*4); 

  //How many Priority registers are there?
  localparam PRIORITY_REGS  = (SOURCES + PRIORITY_FIELDS_PER_REG -1) / PRIORITY_FIELDS_PER_REG;

  //How many Threshold registers are there?
//  localparam THRESHOLD_REGS = HAS_THRESHOLD == 0 ? 0 : (TARGETS + PRIORITY_FIELDS_PER_REG -1) / PRIORITY_FIELDS_PER_REG;
  localparam THRESHOLD_REGS = HAS_THRESHOLD == 0 ? 0 : TARGETS;

  //How many ID register are there?
  localparam ID_REGS = TARGETS;

  //How many registers in total?
  localparam TOTAL_REGS = CONFIG_REGS + EL_REGS + IE_REGS + PRIORITY_REGS + THRESHOLD_REGS + ID_REGS;


  //////////////////////////////////////////////////////////////////
  //
  // Variables
  //

  //Read Variables
  int read_register,
      read_register_idx;
  int write_register;

  //Registers
  logic [DATA_SIZE   -1:0] registers [TOTAL_REGS];


  //////////////////////////////////////////////////////////////////
  //
  // Functions
  //
  function logic [DATA_SIZE-1:0] gen_wval;
    //Returns the new value for a register
    // if be[n] == '1' then gen_val[byte_n] = new_val[byte_n]
    // else                 gen_val[byte_n] = old_val[byte_n]
    input [DATA_SIZE-1:0] old_val,
                           new_val;
    input [BE_SIZE   -1:0] be;

    for (int n=0; n < BE_SIZE; n++)
      gen_wval[n*8 +: 8] = be[n] ? new_val[n*8 +: 8] : old_val[n*8 +: 8];
  endfunction : gen_wval


  /** Register Access calculation
   *  Registers are created dynamically, access is determined by the
   *  parameter settings
   */
  function automatic register_types register_function;
    //return register-type for specified register
    input int r;

    int idx;
    idx = r;

    //1. Configuration Register
    if (idx < CONFIG_REGS  ) return CONFIG;
    idx -= CONFIG_REGS;

    //2. Gateway control registers
    //  Edge/Level
    if (idx < EL_REGS      ) return EL;
    idx -= EL_REGS;

    //3. PLIC Core fabric registers
    if (idx < PRIORITY_REGS) return PRIORITY;
    idx -= PRIORITY_REGS;
    if (idx < IE_REGS      ) return IE;
    idx -= IE_REGS;

    //4. Target registers
    if (idx < THRESHOLD_REGS) return THRESHOLD;
    return ID;
  endfunction : register_function


  function automatic int register_idx;
    //return offset in register-type
    input int r;

    int idx;
    idx = r;

    //1. Configuration registers
    if (idx < CONFIG_REGS  ) return idx;
    idx -= CONFIG_REGS;

    //2. first Gateway control registers
    //  Edge/Level
    //  Interrupt Pending/Acknowledge
    if (idx < EL_REGS      ) return idx;
    idx -= EL_REGS;

    //3. PLIC Core fabric registers
    if (idx < PRIORITY_REGS) return idx;
    idx -= PRIORITY_REGS;
    if (idx < IE_REGS      ) return idx;
    idx -= IE_REGS;

    //4. Target registers
    if (idx < THRESHOLD_REGS) return idx;
    idx -= THRESHOLD_REGS;
    return idx;
  endfunction : register_idx


  function automatic int address2register;
    //Translate 'address' into register number
    input [ADDR_SIZE-1:0] address;

    return address / DATA_BYTES;
  endfunction : address2register


  function automatic [TARGETS-1:0] gen_claim;
    //generate internal 'claim' signal
    input                  re;
    input [ADDR_SIZE-1:0] address;

    int r, idx;

    r   = address2register(address);
    idx = register_idx(r);

    if (register_function(r) == ID && re)
      return (1 << idx);
    else
      return {TARGETS{1'b0}};
  endfunction : gen_claim


  function automatic [SOURCES-1:0] gen_complete;
    //generate internal 'complete' signal
    input                  we;
    input [ADDR_SIZE-1:0] address;

    int r, idx;

    r   = address2register(address);
    idx = register_idx(r);

    if (register_function(r) == ID && we)
      return (1 << idx);
    else
      return {TARGETS{1'b0}};
  endfunction : gen_complete


  function automatic [DATA_SIZE-1:0] encode_config;
    //encode 'rdata' when reading from CONFIG
    input int r; //which register

    logic [MAX_SOURCES_BITS -1:0] sources_bits;
    logic [MAX_TARGETS_BITS -1:0] targets_bits;
    logic [MAX_PRIORITY_BITS-1:0] priority_bits;
    logic                         has_th_bit;

    sources_bits  = SOURCES;
    targets_bits  = TARGETS;
    priority_bits = PRIORITIES;
    has_th_bit    = HAS_THRESHOLD ? 1'b1 : 1'b0;

    if (CONFIG_REGS == 1)
      return {15'h0,has_th_bit,priority_bits,targets_bits,sources_bits};
    else
      if (r == 0)
        return {targets_bits,sources_bits};
      else
        return {15'h0,has_th_bit,priority_bits};
  endfunction : encode_config


  function automatic [DATA_SIZE-1:0] encode_p;
    //encode 'rdata' when reading from PRIORITY
    input int r;  //which register

    //clear all bits
    encode_p = {DATA_SIZE{1'b0}};

    //move PRIORITY fields into bit-positions
    if ((r+1)*PRIORITY_FIELDS_PER_REG <= SOURCES)
      for (int n=0; n < PRIORITY_FIELDS_PER_REG; n++)
        encode_p |= p[r*PRIORITY_FIELDS_PER_REG +n] << (n * PRIORITY_NIBBLES*4);
    else
      for (int n=0; n < SOURCES % PRIORITY_FIELDS_PER_REG; n++)
        encode_p |= p[r*PRIORITY_FIELDS_PER_REG +n] << (n * PRIORITY_NIBBLES*4);
  endfunction : encode_p


  function automatic [PRIORITY_BITS-1:0] decode_p;
    //extract/decode 'priority' fields from PRIORITY-register
    input int r;  //which register
    input int s;  //which field (source)

    logic [DATA_SIZE-1:0] tmp;
    int                   field;

    field = s % PRIORITY_FIELDS_PER_REG;
    tmp   = registers[r];
    tmp   = tmp >> (field * PRIORITY_NIBBLES * 4);
    return tmp[PRIORITY_BITS-1:0];
  endfunction : decode_p


  function automatic [DATA_SIZE-1:0] encode_th;
    //encode 'rdata' when reading from THRESHOLD
    input int r;  //which register

    //clear all bits
    encode_th = {DATA_SIZE{1'b0}};

    //move THRESHOLD fields into bit-positions
    if ((r+1)*PRIORITY_FIELDS_PER_REG <= TARGETS)
      for (int n=0; n < PRIORITY_FIELDS_PER_REG; n++)
        encode_th |= p[r*PRIORITY_FIELDS_PER_REG +n] << (n * PRIORITY_NIBBLES*4);
    else
      for (int n=0; n < TARGETS % PRIORITY_FIELDS_PER_REG; n++)
        encode_th |= p[r*PRIORITY_FIELDS_PER_REG +n] << (n * PRIORITY_NIBBLES*4);
  endfunction : encode_th


  /** Display Register layout/map
   */
  //synopsys translate_off
  function string register_function_name;
    //returns the 'string' name associated with a register type
    input register_types function_number;

    string name_array[register_types];
    name_array[CONFIG   ] = "Configuration";
    name_array[EL       ] = "Edge/Level";
    name_array[IE       ] = "Interrupt Enable";
    name_array[PRIORITY ] = "Interrupt Priority";
    name_array[THRESHOLD] = "Priority Threshold";
    name_array[ID       ] = "ID";

    return name_array[function_number];
  endfunction : register_function_name


  //Display IP configuration; register map
  task display_configuration;
    $display ("------------------------------------------------------------");
    $display (" ,------.                    ,--.                ,--.       ");
    $display (" |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---. ");
    $display (" |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--' ");
    $display (" |  |\\  \\ ' '-' '\\ '-'  |    |  '--.' '-' ' '-' ||  |\\ `--. ");
    $display (" `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---' ");
    $display ("                                           `---'            ");
    $display (" RISC-V Platform Level Interrupt Controller                 ");

    $display ("- Configuration Report -------------------------------------");
    $display (" Sources | Targets | Priority-lvl | Threshold? | Event-Cnt  ");
      $write ("  %4d   |", SOURCES);
      $write ("  %3d    |", TARGETS);
      $write ("  %5d       |", PRIORITIES);
      $write ("  %5s     |", HAS_THRESHOLD ? "YES" : "NO");
     $display("  %3d    ", MAX_PENDING_COUNT);

    $display ("- Register Map ---------------------------------------------");
    display_register_map();

    $display ("- End Configuration Report ---------------------------------");
  endtask : display_configuration

  task display_register_map;
    int address;

    $display (" Address  Function               Mapping");
    for (int r=0; r < TOTAL_REGS; r++)
    begin
        //display address + function
        address = r * (DATA_SIZE / 8);
        $write (" 0x%04x   %-23s", address, register_function_name(register_function(r)));

        //display register mapping
        case ( register_function(r) )
          CONFIG   : display_config_map   ( register_idx(r) );
          EL       : display_el_map       ( register_idx(r) );
          PRIORITY : display_priority_map ( register_idx(r) );
          IE       : display_ie_map       ( register_idx(r) );
          THRESHOLD: display_threshold_map( register_idx(r) );
          ID       : display_id_map       ( register_idx(r) );
          default  : $display("");
        endcase
    end
  endtask : display_register_map

  task display_config_map;
    input int r;

    if (CONFIG_REGS == 1)
      $display ("15'h0,TH,PRIORITES,TARGETS,SOURCES");
    else
      if (r == 0)
        $display ("TARGETS,SOURCES");
      else
        $display ("15'h0,TH,PRIORITIES"); 
  endtask : display_config_map

  task display_el_map;
    input int r;

    if ((r+1)*DATA_SIZE <= SOURCES)
      $display ("EL[%0d:%0d]", (r+1)*DATA_SIZE -1, r*DATA_SIZE);
    else
      $display ("%0d'h0, EL[%0d:%0d]", (r+1)*DATA_SIZE-SOURCES, SOURCES-1, r*DATA_SIZE);
  endtask : display_el_map

  task display_ie_map;
    input int ri;

    int target, r;

    target = ri / EL_REGS;
    r = ri % EL_REGS;

    if ((r+1)*DATA_SIZE <= SOURCES)
      $display ("IE[%0d][%0d:%0d]", target, (r+1)*DATA_SIZE -1, r*DATA_SIZE);
    else
      $display ("%0d'h0, IE[%0d][%0d:%0d]", (r+1)*DATA_SIZE-SOURCES, target, SOURCES-1, r*DATA_SIZE);
  endtask : display_ie_map

  task display_priority_map;
    input int r;

    if ((r+1)*PRIORITY_FIELDS_PER_REG <= SOURCES)
    begin
        for (int s=(r+1)*PRIORITY_FIELDS_PER_REG -1; s >= r*PRIORITY_FIELDS_PER_REG; s--)
        begin
            if (PRIORITY_BITS % 4) $write("%0d'b0,", 4- (PRIORITY_BITS % 4));
            $write ("P[%0d][%0d:%0d]", s, PRIORITY_BITS -1, 0);
            if (s != r*PRIORITY_FIELDS_PER_REG) $write(",");
        end
    end
    else
    begin
        $write ("%0d'h0,", DATA_SIZE - (SOURCES-r*PRIORITY_FIELDS_PER_REG) * PRIORITY_NIBBLES*4);

        for (int s=SOURCES-1; s >= r*PRIORITY_FIELDS_PER_REG; s--)
        begin
            if (PRIORITY_BITS % 4) $write("%0d'b0,", 4- (PRIORITY_BITS % 4));
            $write ("P[%0d][%0d:%0d]", s, PRIORITY_BITS -1, 0);
            if (s != r*PRIORITY_FIELDS_PER_REG) $write(",");
        end
    end

    $display("");
  endtask : display_priority_map

/*
  task display_threshold_map;
    input int r;

    if ((r+1)*PRIORITY_FIELDS_PER_REG <= TARGETS)
    begin
        for (int t=(r+1)*PRIORITY_FIELDS_PER_REG -1; t >= r*PRIORITY_FIELDS_PER_REG; t--)
        begin
            if (PRIORITY_BITS % 4) $write("%0d'b0,", 4- (PRIORITY_BITS % 4));
            $write ("Th[%0d][%0d:%0d]", t, PRIORITY_BITS -1, 0);
            if (t != r*PRIORITY_FIELDS_PER_REG) $write(",");
        end
    end
    else
    begin
        $write ("%0d'h0,", DATA_SIZE - (TARGETS-r*PRIORITY_FIELDS_PER_REG) * PRIORITY_NIBBLES*4);

        for (int t=TARGETS-1; t >= r*PRIORITY_FIELDS_PER_REG; t--)
        begin
            if (PRIORITY_BITS % 4) $write("%0d'b0,", 4- (PRIORITY_BITS % 4));
            $write ("Th[%0d][%0d:%0d]", t, PRIORITY_BITS -1, 0);
            if (t != r*PRIORITY_FIELDS_PER_REG) $write(",");
        end
    end

    $display("");
  endtask : display_threshold_map
*/

  task display_threshold_map;
    input int r;

    $display ("%0d'h0, Th[%0d][%0d:%0d]", DATA_SIZE-PRIORITY_BITS, r, PRIORITY_BITS-1, 0);
  endtask : display_threshold_map


  task display_id_map;
    input int r;

    $display ("%0d'h0, ID[%0d][%0d:%0d]", DATA_SIZE-SOURCES_BITS, r, SOURCES_BITS-1, 0);
  endtask : display_id_map

  //synopsys translate_on


  //////////////////////////////////////////////////////////////////
  //
  // Module Body
  //
  //synopsys translate_off
  initial display_configuration();
  //synopsys translate_on


  /** Write Registers
   *
   * This core has a dynamic array of registers, depending on the
   *  parameter settings
   * Writing to the ID register generates a strobe
   */
  assign write_register = address2register(waddr);

  always @(posedge clk,negedge rst_n)
    if (!rst_n)
      for (int n=0; n < TOTAL_REGS; n++)
        registers[n] <= 'h0;
    else if (we)
      case (register_function(write_register))
        ID     : ; //A write to ID generates a strobe signal
        default: registers[write_register] <= gen_wval( registers[write_register], wdata, be);
      endcase


  /** Claim / Complete
   *  Special cases for Claim / Complete
   *  A read generates a claim strobe
   *  A write doesn't access the register, but generates a complete strobe instead
   */
  always @(posedge clk, negedge rst_n)
    if (!rst_n) claim <= 0;
    else        claim <= gen_claim(re, raddr);

  always @(posedge clk, negedge rst_n)
    if (!rst_n) complete <= 0;
    else        complete <= gen_complete(we, waddr);


  /** Decode registers
   */
generate
  genvar r, t, s;

  for (r=0; r < TOTAL_REGS; r++)
  begin : decode_registers
      case ( register_function(r) )
          //Decode EL register(s)
          // There are SOURCES EL-bits, spread out over
          //  DATA_SIZE wide registers
          EL       : begin
                         if ( (register_idx(r)+1) * DATA_SIZE <= SOURCES )
                           assign el[register_idx(r) * DATA_SIZE +: DATA_SIZE] = registers[r];
                         else
                           assign el[SOURCES-1:register_idx(r) * DATA_SIZE] = registers[r];
                     end
 
          //Decode PRIORITY register(s)
          // There are SOURCES priority-fields, each PRIORITY_BITS
          //  wide, spread out over DATA_SIZE wide registers,
          //  with each field starting at a nibble boundary
          // Need to use always_comb, because we're not assigning a fixed value
          PRIORITY : begin
                         if ( (register_idx(r)+1) * PRIORITY_FIELDS_PER_REG <= SOURCES )
                           for (s =  register_idx(r)    * PRIORITY_FIELDS_PER_REG;
                                s < (register_idx(r)+1) * PRIORITY_FIELDS_PER_REG;
                                s++)
                           begin : decode_p0
                               always_comb p[s] = decode_p(r,s);
                           end
                         else
                           for (s = register_idx(r) * PRIORITY_FIELDS_PER_REG;
                                s < SOURCES;
                                s++)
                           begin : decode_p1
                               always_comb p[s] = decode_p(r,s);
                           end
                     end

          //Decode IE register(s)
          // For each TARGET there's SOURCES IE-fields
          // Layout is the same as for the EL-registers, with each
          //  TARGET starting at a new register
          IE       : begin
                         if ( ((register_idx(r) % EL_REGS)+1) * DATA_SIZE <= SOURCES )
                           assign ie[register_idx(r) / EL_REGS][(register_idx(r) % EL_REGS) * DATA_SIZE +: DATA_SIZE] = registers[r];
                         else
                           assign ie[register_idx(r) / EL_REGS][SOURCES-1 : (register_idx(r) % EL_REGS) * DATA_SIZE] = registers[r];
                     end

/*
          //Decode THRESHOLD register(s)
          // There are TARGETS threshold-fields, each PRIORITY_BITS
          //  wide, spread out over DATA_SIZE wide registers,
          //  with each field starting at a nibble boundary
          THRESHOLD: if (HAS_THRESHOLD)
                     begin
                         if ( (register_idx(r)+1) * PRIORITY_FIELDS_PER_REG <= TARGETS )
                           for (t =  register_idx(r)    * PRIORITY_FIELDS_PER_REG;
                                t < (register_idx(r)+1) * PRIORITY_FIELDS_PER_REG;
                                t++)
                           begin : decode_th0
                               always_comb
                               begin
                                   logic [DATA_SIZE-1:0] tmp;  //local variable
                                   tmp   = registers[r];
                                   tmp   = tmp >> (t * PRIORITY_NIBBLES);
                                   th[t] = tmp[PRIORITY_BITS-1:0];
                               end
                           end
                         else
                           for (t = register_idx(r) * PRIORITY_FIELDS_PER_REG;
                                t < TARGETS;
                                t++)
                           begin : decode_th1
                               always_comb
                               begin
                                   logic [DATA_SIZE-1:0] tmp;  //local variable
                                   tmp   = registers[r];
                                   tmp   = tmp >> (t * PRIORITY_NIBBLES);
                                   th[t] = tmp[PRIORITY_BITS-1:0];
                               end
                           end
                     end
*/

          THRESHOLD: if (HAS_THRESHOLD)
                     begin
                         assign th[register_idx(r)] = registers[r][PRIORITY_BITS-1:0];
                     end
       endcase
  end
endgenerate


  /** Read Registers
   */
  assign read_register     = address2register(raddr);
  assign read_register_idx = register_idx(read_register);

  always @(posedge clk, negedge rst_n)
    if (!rst_n) rdata <= {$bits(rdata){1'b0}};
    else if (re)
      case ( register_function(read_register) )
        CONFIG   : if (HAS_CONFIG_REG) rdata <= encode_config(read_register_idx);
        EL       : rdata <= el >> (read_register_idx * DATA_SIZE);
        PRIORITY : rdata <= encode_p(read_register_idx);
        IE       : rdata <= ie[read_register_idx / EL_REGS] >> ((read_register_idx % EL_REGS) * DATA_SIZE);
//      THRESHOLD: if (HAS_THRESHOLD) rdata <= encode_th(read_register_idx);
        THRESHOLD: if (HAS_THRESHOLD) rdata <= th[read_register_idx];
	ID       : rdata <= id[read_register_idx];
      endcase

endmodule : plic_dynamic_registers

