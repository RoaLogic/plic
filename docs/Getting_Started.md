# Getting Started

## Deliverables

All IP is delivered as a zipped tarball, which can be unzipped with all common compression tools (like unzip, winrar, tar, …).

The tarball contains a directory structure as outlined below:

![](../assets/graphics/Folders.png)

The *doc* directory contains relevant documents like user guides, application notes, and datasheets.

The *rtl* directory contains the actual IP design files. Depending on the license agreement the AHB-Lite PLIC is delivered as either encrypted Verilog-HDL or as plain SystemVerilog source files. Encrypted files have the extension “.enc.sv”, plain source files have the extension “.sv”. The files are encryption according to the IEEE-P1735 encryption standard. Encryption keys for Mentor Graphics (Modelsim, Questasim, Precision), Synplicity (Synplify, Synplify-Pro), and Aldec (Active-HDL, Riviera-Pro) are provided. As such there should be no issue targeting any existing FPGA technology.

If any other synthesis or analysis tool is used then a plain source RTL delivery may be needed. A separate license agreement and NDA is required for such a delivery.

The *bench* directory contains the (encrypted) source files for the testbench.

The *sim* directory contains the files/structure to run the simulations. Section ''[Running the testbench](#running-the-testbench)'' provides for instructions on how to use the makefile.

## Running the testbench

The IP comes with a dedicated testbench that tests all features of the design and finally runs a full random test. The testbench is started from a Makefile that is provided with the IP.

The Makefile is located in the &lt;*install\_dir*&gt;/sim/rtlsim/run directory. The Makefile supports most commonly used simulators; Modelsim/Questasim, Cadence ncsim, Aldec Riviera, and Synopsys VCS.

To start the simulation, enter the &lt;*install\_dir*&gt;/sim/rtlsim/run directory and type: **make &lt;*simulator*&gt;**. Where simulator is any of: msim (for modelsim/questasim), ncsim (for Cadence ncsim), riviera (for Aldec Riviera-Pro), or vcs (for Synopsys VCS). For example type **make msim** to start the testbench in Modelsim/Questasim.

### Self-checking testbench

The testbenches is a self-checking testbench intended to be executed from the command line. There is no need for a GUI or a waveform viewer. Once the testbench completes it displays a summary and closes the simulator.

### Makefile setup

The simulator is executed in its associated directory. Inside this directory is another Makefile that contains simulator specific commands to start and execute the simulation. The &lt;*install\_dir*&gt;/sim/rtlsim/run/Makefile enters the correct directory and calls the simulator specific Makefile.

For example modelsim is executed in the &lt;*install\_dir*&gt;/sim/rtlsim/run/msim directory. Typing **make msim** loads the main Makefile, which then enters the msim sub-directory and calls its Makefile. This Makefile contains commands to compile the RTL and testbench sources with Modelsim, start the Modelsim simulator, and run the simulation.

### Makefile backup

The &lt;*install\_dir*&gt;/sim/rtlsim/bin directory contains backups of the original Makefiles. It may be desirable to modify or extend the Makefiles or to completely clean the run directory. Use the backups to restore the original setup.

### No Makefile

For users unfamiliar with Makefiles or those on systems that do not natively support make (e.g. Windows) a run.do file is provided that can be used with Modelsim/Questasim and Riviera-Pro.