# Platform Level Interrupt Controller

## Overview

Fully Parameterized & Programmable Platform Level Interrupt Controller (PLIC) for RISC-V based Processor Systems

## Documentation

- [Product Brief]()
- [RV12 Datasheet]()
- [User Guide]()

## Features


## Compatibility

Compliant to the RISC-V Privilege Level 1.9, 1.9.1, 1.10 specifications

## Interfaces

- AHB3 Lite
- Wishbone
- Dynamic Registers

The PLIC core implements Dynamic Registers, which means the registers and register mapping are automatically generated based on the parameters provided to the core. The core prints the register mapping during simulation (and for some tools during synthesis).


## Parameters
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

## Resources

Extract table from datasheet

## License

Released under the RoaLogic [Non-Commerical License](/LICENSE.md)

## Dependencies
Requires the Roa Logic [AHB3Lite Package](). This is are included as a submodule.
After cloning the RV12 git repository, perform a 'git submodule init' to download the submodule.
