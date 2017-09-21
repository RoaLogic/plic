# Platform Level Interrupt Controller
Fully Parameterized and Programmable Interrupt Controller
Compliant to the RISC-V Privilegel Level 1.9, 1.9.1, 1.10 specifications

## Dynamic Registers
The PLIC core uses Dynamic Registers, which means that the register definition and the register address mapping are automatically generated based on the parameters provided to the core.
The core prints the register mapping during simulation (and for some tools during synthesis).



## Supported Interfaces:
- AHB3 Lite
- Wishbone

## AHB3 Lite Parameters
| **PARAMETER**     | **DESCRIPTION**                                        |
|:------------------|:-------------------------------------------------------|
| HADDR_SIZE        | AHB Bus Address Size                                   |
| HDATA_SIZE        | AHB Bus Data Size                                      |
| SOURCES           | Number of Interrupt Sources                            |
| TARGETS           | Number of Interrupt Targets                            |
| PRIORITIES        | Number of Interrupt Priority Levels                    |
| MAX_PENDING_COUNT | Maximum Number of Pending Edge-Triggered Interrupts    |
| HAS_THRESHOLD     | Implement the Interrupt Priority Threshold Registers?  |
| HAS_CONFIG_REG    | Implement a register containing the IP configuration?  |


## Dynamic Register Examples
Example 1.
Parameters:
 HDATA_SIZE=32
 SOURCE=16
 TARGETS=2
 PRIORITIES=7
 HAS_THRESHOLD=1
 HAS_CONFIG_REG=0
 ------------------------------------------------------------
  ,------.                    ,--.                ,--.       
  |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---. 
  |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--' 
  |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--. 
  `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---' 
                                            `---'            
  RISC-V Platform Level Interrupt Controller                 
 - Configuration Report -------------------------------------
  Sources | Targets | Priority-lvl | Threshold? | Event-Cnt  
     16   |    2    |      7       |    YES     |    8    
 - Register Map ---------------------------------------------
  Address  Function               Mapping
  0x0000   Edge/Level             16'h0, EL[15:0]
  0x0004   Interrupt Priority     1'b0,P[7][2:0],1'b0,P[6][2:0],1'b0,P[5][2:0],1'b0,P[4][2:0],1'b0,P[3][2:0],1'b0,P[2][2:0],1'b0,P[1][2:0],1'b0,P[0][2:0]
  0x0008   Interrupt Priority     1'b0,P[15][2:0],1'b0,P[14][2:0],1'b0,P[13][2:0],1'b0,P[12][2:0],1'b0,P[11][2:0],1'b0,P[10][2:0],1'b0,P[9][2:0],1'b0,P[8][2:0]
  0x000c   Interrupt Enable       16'h0, IE[0][15:0]
  0x0010   Interrupt Enable       16'h0, IE[1][15:0]
  0x0014   Priority Threshold     29'h0, Th[0][2:0]
  0x0018   Priority Threshold     29'h0, Th[1][2:0]
  0x001c   ID                     27'h0, ID[0][4:0]
  0x0020   ID                     27'h0, ID[1][4:0]
 - End Configuration Report ---------------------------------



Example 2.
Parameters:
 HDATA_SIZE=64
 SOURCE=64
 TARGETS=4
 PRIORITIES=15
 HAS_THRESHOLD=1
 HAS_CONFIG_REG=1
 ------------------------------------------------------------
  ,------.                    ,--.                ,--.       
  |  .--. ' ,---.  ,--,--.    |  |    ,---. ,---. `--' ,---. 
  |  '--'.'| .-. |' ,-.  |    |  |   | .-. | .-. |,--.| .--' 
  |  |\  \ ' '-' '\ '-'  |    |  '--.' '-' ' '-' ||  |\ `--. 
  `--' '--' `---'  `--`--'    `-----' `---' `-   /`--' `---' 
                                            `---'            
  RISC-V Platform Level Interrupt Controller                 
 - Configuration Report -------------------------------------
  Sources | Targets | Priority-lvl | Threshold? | Event-Cnt  
     64   |    4    |     15       |    YES     |    8    
 - Register Map ---------------------------------------------
  Address  Function               Mapping
  0x0000   Configuration          15'h0,TH,PRIORITES,TARGETS,SOURCES
  0x0008   Edge/Level             EL[63:0]
  0x0010   Interrupt Priority     P[15][3:0],P[14][3:0],P[13][3:0],P[12][3:0],P[11][3:0],P[10][3:0],P[9][3:0],P[8][3:0],P[7][3:0],P[6][3:0],P[5][3:0],P[4][3:0],P[3][3:0],P[2][3:0],P[1][3:0],P[0][3:0]
  0x0018   Interrupt Priority     P[31][3:0],P[30][3:0],P[29][3:0],P[28][3:0],P[27][3:0],P[26][3:0],P[25][3:0],P[24][3:0],P[23][3:0],P[22][3:0],P[21][3:0],P[20][3:0],P[19][3:0],P[18][3:0],P[17][3:0],P[16][3:0]
  0x0020   Interrupt Priority     P[47][3:0],P[46][3:0],P[45][3:0],P[44][3:0],P[43][3:0],P[42][3:0],P[41][3:0],P[40][3:0],P[39][3:0],P[38][3:0],P[37][3:0],P[36][3:0],P[35][3:0],P[34][3:0],P[33][3:0],P[32][3:0]
  0x0028   Interrupt Priority     P[63][3:0],P[62][3:0],P[61][3:0],P[60][3:0],P[59][3:0],P[58][3:0],P[57][3:0],P[56][3:0],P[55][3:0],P[54][3:0],P[53][3:0],P[52][3:0],P[51][3:0],P[50][3:0],P[49][3:0],P[48][3:0]
  0x0030   Interrupt Enable       IE[0][63:0]
  0x0038   Interrupt Enable       IE[1][63:0]
  0x0040   Interrupt Enable       IE[2][63:0]
  0x0048   Interrupt Enable       IE[3][63:0]
  0x0050   Priority Threshold     60'h0, Th[0][3:0]
  0x0058   Priority Threshold     60'h0, Th[1][3:0]
  0x0060   Priority Threshold     60'h0, Th[2][3:0]
  0x0068   Priority Threshold     60'h0, Th[3][3:0]
  0x0070   ID                     57'h0, ID[0][6:0]
  0x0078   ID                     57'h0, ID[1][6:0]
  0x0080   ID                     57'h0, ID[2][6:0]
  0x0088   ID                     57'h0, ID[3][6:0]
 - End Configuration Report ---------------------------------


