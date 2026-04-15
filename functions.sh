# --- Functions ---

#  @param $1: .ini file path
#  @param $2: section name
#  @param $3: key name
get_ini_value() {
  local file_path="$1"
  local section="$2"
  local key="$3"
  local value=$(sed -n "/^\[$section\]/,/^\s*\[/p" "$file_path" | grep "^$key" | cut -d '=' -f 2 | tr -d '[:space:]')

  echo "$value"
}

# param $1: The comma-separated string to be converted.
# param $2: The name of the global array variable to store the result
string_to_array() {
  local input_string="$1"
  local array_name="$2"
  IFS=',' read -r -a "$array_name" <<<"$input_string"
  declare -g -a "$array_name"
}

# param $1: Command used for installing packages
# param $2: Name of the array of packages
install_pkgs() {
  local manager_cmd="$1"
  local array_name="$2"
  local -n pkgs="$array_name"

  echo "Installing $array_name"
  for pkg in "${pkgs[@]}"; do
    $manager_cmd "$pkg"
  done
  echo
}

log_script_start() {
  local script_name="${BASH_SOURCE[1]}"
  echo
  echo "================================================================================"
  echo "  STARTING SCRIPT: $script_name"
  echo "================================================================================"
  echo
}

log_script_end() {
  local script_name="${BASH_SOURCE[1]}"
  echo
  echo "================================================================================"
  echo "  ENDING SCRIPT: $script_name"
  echo "================================================================================"
  echo
}
