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

load_config() {
  # Load settings from config.txt
  while IFS='= ' read -r key value; do
    [ -z "$key" ] && continue
    [[ "$key" =~ ^# ]] && continue

    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    eval "${key}=\"${value}\""
  done < "$CONFIG_FILE"
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

save_config() {
  {
    printf "WEBHOOK_URL=%s\n" "$WEBHOOK_URL"
    printf "PRIVATE_SERVER_URL=%s\n" "$PRIVATE_SERVER_URL"
    printf "DISCORD_USER_ID=%s\n" "$DISCORD_USER_ID"
    printf "MIN_NOTIFY_RARITY=%s\n" "$MIN_NOTIFY_RARITY"
    printf "DONT_NOTIFY_BIOME_WITHOUT_LIMITED=%s\n" "$DONT_NOTIFY_BIOME_WITHOUT_LIMITED"
  } > "$CONFIG_FILE"
}

check_adb_connection() {
  local devices_out
  devices_out=$(adb devices)
  if echo "$devices_out" | grep -q "emulator-5554"; then
    echo "Connection status: Connected"
    return 0
  else
    echo "Connection status: Not connected"
    return 1
  fi
}

setup_func() {
  if adb devices | grep -q "emulator-5554"; then
    echo "Already set up."
    read -p "Press Enter to return to the menu." dummy
    return
  fi

  echo "Enter the wireless debugging port number (found in Developer Options):"
  read PORT

  echo "[Macro Setup] Connecting to localhost:$PORT..."
  OUTPUT=$(adb connect localhost:$PORT 2>&1)

  if echo "$OUTPUT" | grep -q "Connection refused"; then
      echo "ADB setup failed. Try turning Wireless Debugging OFF and ON again, then use the new port."
      read -p "Press Enter to return to the menu." dummy
      return
  fi

  echo "[Macro Setup] Switching to TCP:5555..."
  adb tcpip 5555

  echo "[Macro Setup] Restarting ADB server..."
  adb kill-server
  adb start-server

  DEVICES=$(adb devices)
  if ! echo "$DEVICES" | grep -q "emulator-5554"; then
      echo "[Macro Setup] Setup failed. Please restart Wireless Debugging and try again."
  else
      echo "[Macro Setup] Setup completed successfully!"
  fi
  read -p "Press Enter to return to the menu." dummy
}

settings_menu() {
  while :; do
    clear
    echo "=== Settings Menu ==="
    echo "1. Notification Settings"
    echo "2. Environment Settings"
    echo "3. Back"
    read -p "Select an option: " ssel
    case "$ssel" in
      1) notify_settings_menu ;;
      2) env_settings_menu ;;
      3) return ;;
      *) echo "Invalid selection."; sleep 1 ;;
    esac
  done
}

env_settings_menu() {
  load_config
  while :; do
    clear
    echo "=== Environment Settings ==="
    echo "1. Discord Webhook URL: $(format_value "$WEBHOOK_URL")"
    echo "2. Private Server URL: $(format_value "$PRIVATE_SERVER_URL")"
    echo "3. Your Discord User ID: $(format_value "$DISCORD_USER_ID")"
    echo "4. Back"
    read -p "Select an option: " esel
    case "$esel" in
      1) webhook_url_setting ;;
      2) ps_url_setting ;;
      3) user_id_setting ;;
      4) return ;;
      *) echo "Invalid selection."; sleep 1 ;;
    esac
  done
}

notify_settings_menu() {
  load_config
  while :; do
    clear
    echo "=== Notification Settings ==="
    echo "1. Minimum Aura Rarity to Notify: $(format_value "$MIN_NOTIFY_RARITY")"
    echo "2. Disable Notifications for Non-Limited Biomes: $(format_value "$DONT_NOTIFY_BIOME_WITHOUT_LIMITED")"
    echo "3. Back"
    read -p "Select an option: " nsel
    case "$nsel" in
      1) min_notify_setting ;;
      2) biome_notify_setting ;;
      3) return ;;
      *) echo "Invalid selection."; sleep 1 ;;
    esac
  done
}

adb_pairing() {
    echo "=== ADB Pairing ==="
    read -p "Enter pairing port number (e.g. 37451): " pair_port
    if [[ -z "$pair_port" ]]; then
        echo "No port entered. Cancelling..."
        sleep 1
        return
    fi
    
    adb pair localhost:$pair_port

    echo "[INFO] Pairing process finished. Returning to menu..."
    sleep 1
}

main_menu() {
  while :; do
    clear
    echo "=== SolsDroid Main Menu ==="
    check_adb_connection
    echo "1. Run Macro"
    echo "2. Settings"
    echo "3. Setup"
    echo "4. Initial Pairing"
    echo "5. Update"
    echo "6. Exit"
    read -p "Select an option: " sel
    case "$sel" in
      1)
        if ! adb devices | grep -q "emulator-5554"; then
          echo "ADB not connected. Please run Setup first."
          read -p "Press Enter to return to the menu." dummy
        else
          python3 "$PYTHON_SCRIPT"
        fi
        ;;
      2) settings_menu ;;
      3) setup_func ;;
      4) adb_pairing ;;
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

ps_url_setting() {
    while :; do
        read -p "Enter new PrivateServerURL (or type 'exit' to cancel): " new_psurl
        if [[ "$new_psurl" == "exit" ]]; then
            echo "Cancelled."
            sleep 1
            return
        fi
        if [[ -z "$new_psurl" ]]; then
            echo "Input empty. Try again."
            continue
        fi
        PRIVATE_SERVER_URL="$new_psurl"
        save_config
        echo "Saved successfully."
        sleep 1
        return
    done
}

webhook_url_setting() {
    while :; do
        read -p "Enter new DiscordWebhookURL (or type 'exit' to cancel): " new_webhookurl
        if [[ "$new_webhookurl" == "exit" ]]; then
            echo "Cancelled."
            sleep 1
            return
        fi
        if [[ -z "$new_webhookurl" ]]; then
            echo "Input empty. Try again."
            continue
        fi
        WEBHOOK_URL="$new_webhookurl"
        save_config
        echo "Saved successfully."
        sleep 1
        return
    done
}

user_id_setting() {
    while :; do
        read -p "Enter new DiscordUserID (or type 'exit' to cancel): " new_userid
        if [[ "$new_userid" == "exit" ]]; then
            echo "Cancelled."
            sleep 1
            return
        fi
        if [[ -z "$new_userid" ]]; then
            echo "Input empty. Try again."
            continue
        fi
        DISCORD_USER_ID="$new_userid"
        save_config
        echo "Saved successfully."
        sleep 1
        return
    done
}

min_notify_setting() {
    while :; do
        read -p "Enter minimum Aura rarity to trigger notification (type 'exit' to cancel): " new_auramin
        if [[ "$new_auramin" == "exit" ]]; then
            echo "Cancelled."
            sleep 1
            return
        fi
        if [[ -z "$new_auramin" ]]; then
            echo "Input empty. Try again."
            continue
        fi
        if ! [[ "$new_auramin" =~ ^[0-9]+$ ]]; then
            echo "Please enter a numeric value."
            continue
        fi
        MIN_NOTIFY_RARITY="$new_auramin"
        save_config
        echo "Saved successfully."
        sleep 1
        return
    done
}

biome_notify_setting() {
    while :; do
        clear
        echo "1. Enable"
        echo "2. Disable"
        echo "3. Cancel"
        read -p "Select an option: " sel
        case "$sel" in
            1)
                DONT_NOTIFY_BIOME_WITHOUT_LIMITED=true
                save_config
                echo "Saved: Enabled"
                sleep 1
                return
                ;;
            2)
                DONT_NOTIFY_BIOME_WITHOUT_LIMITED=false
                save_config
                echo "Saved: Disabled"
                sleep 1
                return
                ;;
            3)
                echo "Cancelled."
                sleep 1
                return
                ;;
            *)
                echo "Invalid selection. Try again."
                sleep 1
                ;;
        esac
    done
}

config_init
main_menu
