#!/usr/bin/env python3

import sys
from pathlib import Path
from datetime import datetime

AUTHOR = "Juan Lopez"
PROJECT = "Phoenix Basic Library"

BASE_DIR = Path(__file__).resolve().parent
TEMPLATE_DIR = BASE_DIR / "templates"


def load_template(template_name: str) -> str:
    template_path = TEMPLATE_DIR / template_name
    if not template_path.exists():
        print(f"Template not found: {template_path}")
        sys.exit(1)
    return template_path.read_text()


def generate_module(module_name: str):
    today = datetime.now().strftime("%Y-%m-%d")

    file_path = Path(f"{module_name}.sv")

    if file_path.exists():
        print(f"Error: File {file_path} already exists.")
        return

    header_template = load_template("header.txt")
    module_template = load_template("module.txt")

    header = header_template.format(
        module_name=module_name,
        project=PROJECT,
        author=AUTHOR,
        date=today,
        description="TODO: Add module description."
    )

    module_body = module_template.format(module_name=module_name)

    with open(file_path, "w") as f:
        f.write(header)
        f.write("\n")
        f.write(module_body)

    print(f"✓ Created {file_path}")


def main():
    if len(sys.argv) != 2:
        print("Usage: python create_module.py <module_name>")
        sys.exit(1)

    module_name = sys.argv[1]
    generate_module(module_name)


if __name__ == "__main__":
    main()

