#!/usr/bin/env python3

import sys
from pathlib import Path
from datetime import datetime

AUTHOR = "Juan Lopez"
PROJECT = "Phoenix Basic Library"

BASE_DIR = Path(__file__).resolve().parent
TEMPLATE_DIR = BASE_DIR / "templates"

# ----------------------------------------------------------- 
# Helper Functions
# ----------------------------------------------------------- 

def load_template(template_name: str) -> str:
    template_path = TEMPLATE_DIR / template_name
    if not template_path.exists():
        print(f"Template not found: {template_path}")
        sys.exit(1)
    return template_path.read_text()

def write_file(filename: Path, content: str):
    if filename.exists():
        print(f"Error: File {filename} already exists")
    with open(filename, "w") as f:
        f.write(content)
    print(f"Created {filename}")

# ----------------------------------------------------------- 
# Generation Functions
# ----------------------------------------------------------- 
def create_sv_module(module_name: str):
    today = datetime.now().strftime("%Y-%m-%d")

    header_template = load_template("header.txt")
    module_template = load_template("module.txt")

    header = header_template.format(
        module_name=module_name,
        project=PROJECT,
        author=AUTHOR,
        date=today,
        module_type="TODO: Add module type (MATH, INTERFACE, COMMON, MEMORY"
        description="TODO: Add module description."
    )
    module_body = module_template.format(module_name=module_name)
    
    full_content = header + "\n" + module_body
    file_path = Path(f"{module_name}.sv")
    write_file(file_path, full_content)

def create_sv_testbench():
    today = datetime.now().strftime("%Y-%m-%d")
    # TODO :    read .sv module
#               create testbench w/ sv_tb_template & .sv module parameters
    
# ---------------------------------------------------------------------------
# Entry Point
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) != 3:
        print("Usage: python create.py <type> <name>")
        print("Types: module | tb")
        sys.exit(1)

    create_type = sys.argv[1]
    name = sys.argv[2]

    if create_type == "module":
        create_sv_module(name)
    elif create_type == "tb":
        create_sv_testbench(name)
    else:
        print(f"Unknown type: {create_type}")
        print("Valid types: module | tb")
        sys.exit(1)


if __name__ == "__main__":
    main()
