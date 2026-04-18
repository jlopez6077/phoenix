#!/bin/bash
# phoenix/install.sh
#   - Main script for installing software and configurations

FILE_DIR="$(dirname "$(readlink -f "$0")")"                   # Script Directory File Path
LIB_DIR="$FILE_DIR/lib"                                       # lib/ File Path
REPO_ROOT=$(readlink -m "$LIB_DIR/$(cat "$LIB_DIR/phoenix")") # Repository File Path

source "$REPO_ROOT/functions.sh"

set -e

# TODO: Change for other Linux Distributions
# "sudo pacman -Sy --noconfirm "
# "sudo dnf install -y "
# "sudo apt-get install -y "
export PACKAGE_MANAGER="pacman -Si " # Current value for testing

log_script_start
echo
echo "install.sh script Package Manager execution: $PACKAGE_MANAGER"
echo
$REPO_ROOT/docs/work.sh
$REPO_ROOT/docs/pyinstall.sh
log_script_end
