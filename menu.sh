#!/bin/bash

PYTHON_SCRIPT="main.py"
CONFIG_FILE="config.txt"

format_value() {
  local val="$1"
  case "$val" in
    unconfigured)
      echo "Not set"
      ;;
    true)
      echo "Enabled"
      ;;
    false)
      echo "Disabled"
      ;;
    *)
      echo "$val"
      ;;
  esac
}

config_init() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "config.txt not found. Creating a new one..."
    {
      printf "WEBHOOK_URL = unconfigured\n"
      printf "PRIVATE_SERVER_URL = unconfigured\n"
      printf "DISCORD_USER_ID = unconfigured\n"
      printf "MIN_NOTIFY_RARITY = 100000000\n"
      printf "DONT_NOTIFY_BIOME_WITHOUT_LIMITED = false\n"
    } > "$CONFIG_FILE"
  fi
}

check_adb_connection() {
  local devices_out
  devices_out=$(adb devices)
  if echo "$devices_out" | grep -q "emulator-5554"; then
    echo "Connection Status: Connected"
    return 0
  else
    echo "Connection Status: Not connected"
    return 1
  fi
}

setup_func() {
  if adb devices | grep -q "emulator-5554"; then
    echo "Setup has already been completed."
    read -p "Press Enter to return to the menu." dummy
    return
  fi

  echo "Enter the port number for wireless debugging (found in Developer Options):"
  read PORT

  echo "[Macro Setup] Connecting to localhost:$PORT..."
  OUTPUT=$(adb connect localhost:$PORT 2>&1)

  if echo "$OUTPUT" | grep -q "Connection refused"; then
      echo "ADB setup failed D: Please turn off wireless debugging, then on again, and retry with a new port."
      read -p "Press Enter to return to the menu." dummy
      return
  fi

  echo "[Macro Setup] Switching connection to TCP:5555..."
  adb tcpip 5555

  echo "[Macro Setup] Restarting ADB server..."
  adb kill-server
  adb start-server

  DEVICES=$(adb devices)
  if ! echo "$DEVICES" | grep -q "emulator-5554"; then
      echo "[Macro Setup] Initial setup failed. Please restart wireless debugging and try again."
  else
      echo "[Macro Setup] Initial setup completed successfully."
  fi
  read -p "Press Enter to return to the menu." dummy
}

main_menu() {
  while :; do
    clear
    echo "=== SolsDroid Menu ==="
    check_adb_connection
    echo "1. Run Macro"
    echo "2. Settings"
    echo "3. Setup"
    echo "4. First-time Pairing"
    echo "5. Update"
    echo "6. Exit"
    read -p "Select a number: " sel
    case "$sel" in
      1)
        if ! adb devices | grep -q "emulator-5554"; then
          echo "ADB is not connected. Please run setup first."
          read -p "Press Enter to return to the menu." dummy
        else
          python3 "$PYTHON_SCRIPT"
        fi
        ;;
      2)
        settings_menu
        ;;
      3)
        setup_func
        ;;
      4)
        adb_pairing
        ;;
      5)
        branch_output=$(git branch --show-current)
        if [ -z "$branch_output" ]; then
          echo "Failed to get current branch."
          exit 1
        fi
        git pull origin "$branch_output"
        echo "SolsDroid is now up to date!"
        ;;
      6)
        echo "Exiting..."
        exit 0
        ;;
      *)
        echo "Invalid selection."
        sleep 1
        ;;
    esac
  done
}
