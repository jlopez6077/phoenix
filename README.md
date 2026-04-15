# Phoenix Basic Library
Phoenix Basic Library is a vendor-neutral collection of reusable, parameterizable SystemVerilog modules built from first principles. This project serves as a foundational library for larger FPGA designs, a documented hardware workflow, and a sandbox for developing the PhoenixCLI automation toolchain.
## Overview
The goal of this repository is to standardize FPGA project structures to make development seamless across different projects. It integrates hardware design with a Python-based automation layer to handle environment setup and project templating.
## Hardware
The library currently includes the following parameterizable SystemVerilog modules:

APB (Advanced Peripheral Bus)
* SystemVerilog Interface: Standardized APB bus definition.
* General Purpose I/O (GPIO): APB-compatible GPIO controller.
Common
* Bypass: Parameterizable bypass logic.
* Debouncer: Input signal debouncing for physical switches or noisy signals.
* Delay Line: Configurable hardware delay elements.

## Testing
Testbenches are either using the Cocotb Framework or SystemVerilog. Simulation software is either Vivado's xsim or an open-source toolchain. More information in [[docs/workflow]]
Open-Source Toolchain:
* verilator
* gtkwave
* cocotb
* cocotbext-axi
* cocotbext-eth
* cocotbext-uart
* cocotbext-pcie
## Workflow
The project follows a modular organization to separate source code, testbenches, and automation scripts. For more information [[workflow/workflow.md]]
## PhoenixCLI
A custom command line interface designed to automate repetitive tasks and accelerate development. For more information [[cli/phxCLI.md]].
## Setup & Installation
The library uses a tiered installation process managed by install.sh. In install.sh PACKAGE_MANAGER needs to change depending on the Linux Distribution.
1. Bash Scripts
  * install.sh - Executes all Bash Scripts
  * functions.sh - Script Functions
  * workflow/work.sh - Installs FPGA Toolchain
  * cli/config.sh - Installs Python Workflow
2. Initialization files
	* workflow/pkg.ini - Simulation & Recommended Toolchain
	* cli/python_config.ini - Python Installation Configuration
## License
This project is licensed under the MIT License. For the full legal text, please refer to [[License]]
