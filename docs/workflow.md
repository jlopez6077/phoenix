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


