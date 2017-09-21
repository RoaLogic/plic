# Platform Level Interrupt Controller
Fully Parameterized and Programmable Interrupt Controller
Compliant to the RISC-V Privilegel Level 1.9, 1.9.1, 1.10 specifications

##Supported Interfaces:
- AHB3 Lite
- Wishbone

##AHB3 Lite Parameters
- HADDR_SIZE       : AHB Bus Address Size
- HDATA_SIZE       : AHB Bus Data Size
- SOURCES          : Number of Interrupt Sources
- TARGETS          : Number of Interrupt Targets
- PRIORITIES       : Number of Interrupt Priority Levels
- MAX_PENDING_COUNT: Maximum Number of Pending Edge-Triggered Interrupts
- HAS_THRESHOLD    : Implement the Interrupt Priority Threshold Registers?
- HAS_CONFIG_REG   : Implement a register containing the IP configuration?


