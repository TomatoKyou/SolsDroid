#!/bin/bash

PYTHON_SCRIPT="main.py"  # または main.py

check_adb_connection() {
  local devices_out
  devices_out=$(adb devices)
  if echo "$devices_out" | grep -q "emulator-5554"; then
    echo "接続状況：接続中"
    return 0
  else
    echo "接続状況：未接続"
    return 1
  fi
}

setup_func() {
  # すでに接続されていたら警告
  if adb devices | grep -q "emulator-5554"; then
    echo "すでにセットアップ済みです。"
    read -p "Enterでメニューに戻ります。" dummy
    return
  fi

  echo "ワイヤレスデバッグ接続用ポート番号を入力してください(開発者向けオプションにあります)"
  read PORT

  echo "[Macro Setup] localhost:$PORTにアクセスしています..."
  OUTPUT=$(adb connect localhost:$PORT 2>&1)

  if echo "$OUTPUT" | grep -q "Connection refused"; then
      echo "adbのセットアップに失敗しましたD: ワイヤレスデバッグを一度OFF、再度ONにしたあと、新しいポート番号でやり直してください。"
      read -p "Enterでメニューに戻ります。" dummy
      return
  fi

  echo "[Macro Setup] 接続をTCP:5555に変更しています..."
  adb tcpip 5555

  echo "[Macro Setup] adbサーバーを再起動しています..."
  adb kill-server
  adb start-server

  DEVICES=$(adb devices)
  if ! echo "$DEVICES" | grep -q "emulator-5554"; then
      echo "[Macro Setup] 起動時セットアップに失敗しました。ワイヤレスデバッグを再起動してもう1度やりなおしてください。"
  else
      echo "[Macro Setup] 起動時セットアップが正常に完了しました"
  fi
  read -p "Enterでメニューに戻ります。" dummy
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
        if ! adb devices | grep -q "emulator-5554"; then
          echo "adbが接続されていません。先にセットアップを実行してください。"
          read -p "Enterでメニューに戻ります。" dummy
        else
          python3 "$PYTHON_SCRIPT"
        fi
        ;;
      2)
        ;;
      3)
        setup_func
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
