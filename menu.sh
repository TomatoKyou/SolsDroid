#!/bin/bash

PYTHON_SCRIPT="main.py"  # または main.py
CONFIG_FILE="config.txt"

format_value() {
  local val="$1"
  case "$val" in
    unconfigured)
      echo "未設定"
      ;;
    true)
      echo "有効"
      ;;
    false)
      echo "無効"
      ;;
    *)
      echo "$val"
      ;;
  esac
}

load_config() {
  # config.txt を読み込んで環境変数に設定
  while IFS='= ' read -r key value; do
    # 空行やコメント行をスキップ
    [ -z "$key" ] && continue
    [[ "$key" =~ ^# ]] && continue

    # 余分な空白を削除して変数に代入
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    eval "${key}=\"${value}\""
  done < "$CONFIG_FILE"
}


config_init() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "config.txt が存在しません。新規作成します..."
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

settings_menu() {
  while :; do
    clear
    echo "=== 設定メニュー ==="
    echo "1. 通知設定"
    echo "2. 環境設定"
    echo "3. 戻る"
    read -p "番号を選んでください: " ssel
    case "$ssel" in
      1)
        notify_settings_menu
        ;;
      2)
        env_settings_menu
        ;;
      3)
        return
        ;;
      *)
        echo "無効な選択です"
        sleep 1
        ;;
    esac
  done
}

env_settings_menu() {
  load_config
  while :; do
    clear
    echo "=== 環境設定 ==="
    echo "1. DiscordWebhookURL：$(format_value "$WEBHOOK_URL")"
    echo "2. PrivateServerURL：$(format_value "$PRIVATE_SERVER_URL")"
    echo "3. あなたのユーザーID：$(format_value "$DISCORD_USER_ID")"
    echo "4. 戻る"
    read -p "番号を選んでください: " esel
    case "$esel" in
      1)
        webhook_url_setting
        ;;
      2)
        ps_url_setting
        ;;
      3)
        user_id_setting
        ;;
      4)
        return
        ;;
      *)
        echo "無効な選択です"
        sleep 1
        ;;
    esac
  done
}

notify_settings_menu() {
  load_config
  while :; do
    clear
    echo "=== 通知設定 ==="
    echo "1. 最低通知レア度：$(format_value "$MIN_NOTIFY_RARITY")"
    echo "2. 限定バイオーム以外を通知しない：$(format_value "$DONT_NOTIFY_BIOME_WITHOUT_LIMITED")"
    echo "3. 戻る"
    read -p "番号を選んでください： " nsel
    case "$nsel" in
      1)
        min_notify_setting
        ;;
      2)
        biome_notify_setting
        ;;
      3)
        return
        ;;
      *)
        echo "無効な選択です"
        sleep 1
        ;;
    esac
  done
}

adb_pairing() {
    echo "=== ADB ペアリング ==="
    read -p "ペアリング用ポート番号を入力してください (例: 37451): " pair_port
    if [[ -z "$pair_port" ]]; then
        echo "ポート番号が入力されませんでした。キャンセルします。"
        sleep 1
        return
    fi
    
    adb pair localhost:$pair_port

    echo "[INFO] ペアリング処理が終了しました。メニューに戻ります..."
    sleep 1
}

main_menu() {
  while :; do
    clear
    echo "=== SolsDroid メニュー ==="
    check_adb_connection
    echo "1. マクロを実行"
    echo "2. 設定"
    echo "3. セットアップ"
    echo "4. 初回ペアリング"
    echo "5. アップデート"
    echo "6. 終了"
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
          echo "現在のブランチを取得できませんでした。"
          exit 1
        fi
        git pull origin $branch_output
        echo "SolsDroidは最新状態になりました！"
        ;;
      6)
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

ps_url_setting() {
    while :; do
        read -p "新しいPrivateServerURLを入力してください（exitを入力してキャンセル）: " new_psurl
        if [[ "$new_psurl" == "exit" ]]; then
            echo "変更をキャンセルしました"
            sleep 1
            return
        fi
        # 空入力は無視する場合
        if [[ -z "$new_psurl" ]]; then
            echo "入力が空です。再入力してください"
            continue
        fi
        PRIVATE_SERVER_URL="$new_psurl"
        save_config
        echo "変更を保存しました"
        sleep 1
        return
    done
}

webhook_url_setting() {
    while :; do
        read -p "新しいDiscordWebhookURLを入力してください（exitを入力してキャンセル）: " new_webhookurl
        if [[ "$new_webhookurl" == "exit" ]]; then
            echo "変更をキャンセルしました"
            sleep 1
            return
        fi
        # 空入力は無視する場合
        if [[ -z "$new_webhookurl" ]]; then
            echo "入力が空です。再入力してください"
            continue
        fi
        WEBHOOK_URL="$new_webhookurl"
        save_config
        echo "変更を保存しました"
        sleep 1
        return
    done
}

user_id_setting() {
    while :; do
        read -p "新しいDiscordUserIDを入力してください（exitを入力してキャンセル）: " new_userid
        if [[ "$new_userid" == "exit" ]]; then
            echo "変更をキャンセルしました"
            sleep 1
            return
        fi
        # 空入力は無視する場合
        if [[ -z "$new_userid" ]]; then
            echo "入力が空です。再入力してください"
            continue
        fi
        DISCORD_USER_ID="$new_userid"
        save_config
        echo "変更を保存しました"
        sleep 1
        return
    done
}

min_notify_setting() {
    while :; do
        read -p "オーラ装備通知を送信するオーラの最低値を入力してください。（exitでキャンセル）: " new_auramin
        if [[ "$new_auramin" == "exit" ]]; then
            echo "変更をキャンセルしました"
            sleep 1
            return
        fi
        if [[ -z "$new_auramin" ]]; then
            echo "入力が空です。再入力してください"
            continue
        fi
        if ! [[ "$new_auramin" =~ ^[0-9]+$ ]]; then
            echo "数字のみを入力してください"
            continue
        fi
        MIN_NOTIFY_RARITY="$new_auramin"
        save_config
        echo "変更を保存しました"
        sleep 1
        return
    done
}

biome_notify_setting() {
    while :; do
        clear
        echo "1. 有効化"
        echo "2. 無効化"
        echo "3. キャンセル"
        read -p "番号を選んでください: " sel
        case "$sel" in
            1)
                DONT_NOTIFY_BIOME_WITHOUT_LIMITED=true
                save_config
                echo "変更を保存しました: 有効"
                sleep 1
                return
                ;;
            2)
                DONT_NOTIFY_BIOME_WITHOUT_LIMITED=false
                save_config
                echo "変更を保存しました: 無効"
                sleep 1
                return
                ;;
            3)
                echo "変更をキャンセルしました"
                sleep 1
                return
                ;;
            *)
                echo "無効な選択です。再入力してください。"
                sleep 1
                ;;
        esac
    done
}
config_init
main_menu
