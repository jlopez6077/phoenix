#!/bin/bash
# phoenix/install.sh
#   - Main script for installing software and configurations

FILE_DIR="$(dirname "$(readlink -f "$0")")" # Script Directory File Path
REPO_ROOT=$FILE_DIR

source "$REPO_ROOT/functions.sh"

set -e

# TODO: Change for other Linux Distributions
# "sudo pacman -Sy --noconfirm "
# "sudo dnf install -y "
# "sudo apt-get install -y "
export PACKAGE_MANAGER="pacman -Si " # Current value for testing

log_script_start
echo "install.sh script Package Manager execution: $PACKAGE_MANAGER"
$REPO_ROOT/docs/work.sh
$REPO_ROOT/cli/config.sh
log_script_end
