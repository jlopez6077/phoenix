#!/bin/bash
# phoneix/cli/config.sh
#   - Configures Python Workflow

FILE_DIR="$(dirname "$(readlink -f "$0")")"                   # Script Directory File Path
LIB_DIR="$FILE_DIR/lib"                                       # lib/ File Path
REPO_ROOT=$(readlink -m "$LIB_DIR/$(cat "$LIB_DIR/phoenix")") # Repository File Path

CONFIG_FILE="$FILE_DIR/python_config.ini" # Configuration File Path

source "$REPO_ROOT/functions.sh"

set -e

log_script_start

echo "--- 1. Extracting data from $CONFIG_FILE ---"
SYSTEM_PACKAGES=$(get_ini_value "$CONFIG_FILE" "ProjectSetup" "system_packages")
PYTHON_VERSION=$(get_ini_value "$CONFIG_FILE" "ProjectSetup" "python_version")
VENV_NAME=$(get_ini_value "$CONFIG_FILE" "ProjectSetup" "venv_name")
COCOTB_REQUIREMENTS=$(get_ini_value "$CONFIG_FILE" "ProjectSetup" "cocotb_requirements")
PHOENIXCLI_REQUIREMENTS=$(get_ini_value "$CONFIG_FILE" "ProjectSetup" "phoenixCLI_requirements")

string_to_array "$SYSTEM_PACKAGES" "sys_pkgs"
echo

read -n1 -rep "Did you want to install and setup the Python Virtual Enviroment (Y,n): " SETUP
if [[ $SETUP == "Y" || $SETUP == "y" ]]; then

  echo "--- 2. Installs packages using package Manager ---"
  declare -p sys_pkgs
  echo "Installing the packages above"
  install_pkgs "$PACKAGE_MANAGER" sys_pkgs
  echo

  echo "--- 3. Initializing Pyenv ---"
  # TODO: Add this to your .bashrc file -----
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  # -----------------------------------------
  echo

  echo "--- 4. Python Version Installion ---"
  if pyenv versions --bare | grep -qx "$PYTHON_VERSION"; then
    echo "Python $PYTHON_VERSION is already installed."
  else
    echo "Installing Python Version: $PYTHON_VERSION"
    pyenv install "$PYTHON_VERSION"
  fi
  echo

  echo "--- 5. Setting local application-specific Python Version ---"
  (cd "$REPO_ROOT" && pyenv local "$PYTHON_VERSION")

  REPO_PY_VERSION=$(cd "$REPO_ROOT" && python --version)
  if [[ $REPO_PY_VERSION != "Python $PYTHON_VERSION" ]]; then
    echo "Error: $REPO_PY_VERSION does not meet the required Python version: $PYTHON_VERSION"
    return 1
  else
    echo "Success: $REPO_PY_VERSION meets the required Python version $PYTHON_VERSION"
  fi
  echo

  echo "--- 6. Creating Virtual Enviroment: $REPO_ROOT/$VENV_NAME  ---"
  python -m venv $REPO_ROOT/$VENV_NAME
  echo
fi

echo "--- 7. Installing Python Packages  ---"
echo

source $REPO_ROOT/"$VENV_NAME"/bin/activate

REPO_PY_VERSION=$(cd "$REPO_ROOT" && python --version)
if [[ $REPO_PY_VERSION != "Python $PYTHON_VERSION" ]]; then
  echo "Error: $REPO_PY_VERSION does not meet the required Python version: $PYTHON_VERSION"
  return 1
fi

cat $FILE_DIR/"$COCOTB_REQUIREMENTS"
echo
read -n1 -rep 'Do you want to install the required packages for Cocotb? (Y,n): ' COCOTB
if [[ $COCOTB == "Y" || $COCOTB == "y" ]]; then
  pip install -r $FILE_DIR/$COCOTB_REQUIREMENTS
fi
echo

cat $FILE_DIR/$PHOENIXCLI_REQUIREMENTS
echo
read -n1 -rep 'Do you want to install required packages for PhoenixCLI? (Y,n): ' PHXCLI
if [[ $PHXCLI == "Y" || $PHXCLI == "y" ]]; then
  pip install -r $FILE_DIR/$PHOENIXCLI_REQUIREMENTS
fi
echo

log_script_end
