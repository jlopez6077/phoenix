#!/bin/bash
# phoneix/docs/work.sh
#   - Configures FPGA Workflow

FILE_DIR="$(dirname "$(readlink -f "$0")")"                   # Script Directory File Path
LIB_DIR="$FILE_DIR/lib"                                       # lib/ File Path
REPO_ROOT=$(readlink -m "$LIB_DIR/$(cat "$LIB_DIR/phoenix")") # Repository File Path

CONFIG_FILE="$FILE_DIR/pkg.ini" # Package List File Path

source "$REPO_ROOT/functions.sh"

set -e

# --- Project Installion ---
log_script_start

echo "--- 1. Extracting data from $CONFIG_FILE ---"
echo
SIM_PKG=$(get_ini_value "$CONFIG_FILE" "Packages" "Simulation")
RECOMMONDED=$(get_ini_value "$CONFIG_FILE" "Packages" "Recommonded")

string_to_array "$SIM_PKG" "sim_pkg"
string_to_array "$RECOMMONDED" "recommonded_pkg"

# echo packages
declare -p sim_pkg
read -n1 -rep "Do you want to install the Simulator and Waveform Viewer? (Y,n): " SIM
echo

declare -p recommonded_pkg
read -n1 -rep "Do you want to install the recommonded packages above? (Y,n): " EXTRA
echo

echo "--- 2. Installation ---"
if [[ "$SIM" == "y" || "$SIM" == "Y" ]]; then
  install_pkgs "$PACKAGE_MANAGER" sim_pkg
fi
if [[ "$EXTRA" == "y" || "$EXTRA" == "Y" ]]; then
  install_pkgs "$PACKAGE_MANAGER" recommonded_pkg
fi

log_script_end
