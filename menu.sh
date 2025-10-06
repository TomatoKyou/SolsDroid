#!/bin/bash

PYTHON_SCRIPT="main.py"  # または main.py に変更可

check_adb_connection() {
  local devices_out
  devices_out=$(adb devices)
  if echo "$devices_out" | grep -q "emulator-5554"; then
    echo "接続状況：接続中"
  else
    echo "接続状況：未接続"
  fi
}

main_menu() {
  while :; do
    clear
    echo "=== SolsDroid メニュー ==="
    check_adb_connection
    echo "1. マクロを実行"
    echo "2. 設定"
    echo "3. セットアップ"
    echo "4. 終了"
    read -p "番号を選んでください: " sel
    case "$sel" in
      1)
        python3 "$PYTHON_SCRIPT"
        ;;
      2)
        ;;
      3)
        ;;
      4)
        echo "終了します"
        exit 0
        ;;
      *)
        echo "無効な選択です"
        sleep 1
        ;;
    esac
  done
}

main_menu
