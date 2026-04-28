# 🦅 Phoenix Basic Library
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Language: SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-orange.svg)
![Status: Active](https://img.shields.io/badge/Status-Active-brightgreen.svg)

A vendor-neutral collection of reusable, parameterizable SystemVerilog modules built from first principles. Phoenix serves as a foundational library for high-performance FPGA designs and provides a documented, modern hardware workflow.

---

## Project Goals
The mission of this repository is to **standardize FPGA project structures** and provide a modular hardware foundation. 
- **Portability**: Code is written to be vendor-neutral, ensuring compatibility across Xilinx, Intel, and open-source toolchains.
- **Verification-First**: Every module is designed with testability in mind, supporting both Cocotb and standard SystemVerilog testbenches.
- **Scalability**: Parameterized modules allow for seamless integration into various design requirements.

## Repository Structure
```text
phoenix/
├── docs/               # Documentation and setup scripts
├── lib/                # Library dependencies
├── src/                # Source code
│   ├── apb/            # Bus infrastructure (Bridges, Fabrics, Interfaces)
│   ├── common/         # Bus-less primitives (Delays, CDC, Logic)
│   ├── math/           # Parameterizable math operators
│   ├── memory/         # RAM/FIFO and memory controllers
│   └── peripherals/    # Bus-attached peripherals (GPIO, UART, PWM)
├── functions.sh        # Shell utility functions
├── install.sh          # Main installation entry point
└── README.md           # This file
```

## Hardware Modules
The library is organized into logical groups of parameterizable components:

* **Bus Infrastructure** (`src/apb/`)
	* **APB Interface**: Standardized SystemVerilog interface for the Advanced Peripheral Bus.

* **Peripherals** (`src/peripherals/`)
	* **phx_apb_gpio**: An APB-compatible General Purpose I/O controller with configurable width.

* **Common Logic** (`src/common/`)
	* **phx_bypass**: Simple parameterizable bypass logic for pipeline management.
	* **phx_debouncer**: Glitch filter for physical switches or noisy asynchronous signals.
	* **phx_delay_line**: Configurable hardware delay elements for signal alignment.


## Testing & Verification
I prioritize open-source verification tools to ensure accessibility and speed.

| Tool            | Purpose                                           |
| :-------------- | :------------------------------------------------ |
| **Verilator**   | Primary high-performance simulator (SV to C++)    |
| **Cocotb**      | Python-based verification framework               |
| **GTKWave**     | Waveform visualization                            |
| **Vivado XSim** | Vendor-specific timing and primitive verification |

### Key Cocotb Extensions Used:
- `cocotbext-axi`, `cocotbext-eth`, `cocotbext-uart`, `cocotbext-pcie`

For more details on the verification methodology, see [**docs/workflow.md**](docs/workflow.md).

## Setup & Installation
The library uses a tiered installation process to handle system dependencies and Python environments.

### 1. Prerequisites
Ensure your `PACKAGE_MANAGER` is correctly set in `install.sh` (e.g., `pacman`, `apt`, `dnf`).

### 2. Installation
Run the main install script from the repository root:
```bash
./install.sh
```

This will automatically trigger:
- `docs/work.sh`: Installs the FPGA simulation toolchain (Verilator, etc.).
- `docs/pyinstall.sh`: Configures the Python environment and installs Cocotb dependencies.

## License
This project is licensed under the **MIT License**. For the full legal text, please refer to the [LICENSE](LICENSE) file.
---
