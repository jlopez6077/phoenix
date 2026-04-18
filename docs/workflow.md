This is what this file needs to cover in no particular order:
require software
Reposority format
Repo_name/
  AUTHORS
  docs/
  .git
  .gitignore
  LICEASE
  README.md
  src/
    lib/
    rtl/
    tb/

addition files 
you should store your vitis source files in src/software.
you should track your xdc file in src/xdc/
you should store your vivado and vitis projects here but include them in .gitignore so they're not tracked
you should generate and track your vivado tcl script.
.gitignore should be used for documenation that is not project specific.

## Verification
My primary simulator should be verilator. If it passess in verilaotr, it will almost certianly pass in vivado. the reverse is not always true. Its incredibly fast because it compiles sv into C++. Cocotb allows me to write testbenches in python which i excellent for rapid prototyping and data-heavy verificaiton (like DSP or image processing). Cocotb is the framework that i will be using because it makes my project accessible to a wide audience. 
There is a place for vivado and xsim. despite using vivado, i shouldn't build my entire project around it. but i should develop scripts that allow me to verify complex timing or xilinx-specific primitives. 
by targeting verilator, i ensure my code is high-quality and accessible. by keeping XSim copatibile i ensure my designs actually help me at my 9-to-5. 


Recommonded Software
git:
  the fast distributed version control system
tmux:
  Terminal multiplexer
neovim:
  Fork of Vim aiming to improve user experience, plugins, and GUIs
obsidian: 
  A powerful knowledge base that works on top of a local folder of plain text Markdown files
tcpdump:
  Powerful command-line packet analyzer
phxCLI:
  Custom command-line interface for fpga automation


