#!/bin/bash

WEBHOOK_FILE="./webhook.txt"
SERVER_FILE="./server.txt"
CONFIG_FILE="./config.txt"

# デフォルト値
notify_only_special_biome=false
aura_min_count=0

# 既存の config.txt があれば読み込む
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

function set_webhook() {
    current=$(cat "$WEBHOOK_FILE" 2>/dev/null || echo "")
    echo "現在のDiscord Webhook URL: $current"
    read -p "変更しますか？(y/n): " ans
    if [[ "$ans" == "y" ]]; then
        read -p "新しいDiscord Webhook URL: " url
        echo "$url" > "$WEBHOOK_FILE"
        echo "保存しました。"
    fi
}

function set_private_server() {
    current=$(cat "$SERVER_FILE" 2>/dev/null || echo "")
    echo "現在のPrivate Server URL: $current"
    read -p "変更しますか？(y/n): " ans
    if [[ "$ans" == "y" ]]; then
        read -p "新しいPrivate Server URL: " url
        echo "$url" > "$SERVER_FILE"
        echo "保存しました。"
    fi
}

function set_discord_notify() {
    echo "現在の設定:"
    echo "  notify_only_special_biome=$notify_only_special_biome"
    echo "  aura_min_count=$aura_min_count"
    echo
    read -p "限定バイオーム以外の通知を無効化しますか？(true/false): " val
    notify_only_special_biome=$val
    # aura_min_count は今後使用予定
    read -p "オーラメンションの最小値（今は未使用）: " val2
    aura_min_count=$val2
}

function show_all_settings() {
    echo "=== 現在の設定 ==="
    echo "Discord Webhook URL: $(cat "$WEBHOOK_FILE" 2>/dev/null || echo "未設定")"
    echo "Private Server URL: $(cat "$SERVER_FILE" 2>/dev/null || echo "未設定")"
    echo "通知設定:"
    echo "  notify_only_special_biome=$notify_only_special_biome"
    echo "  aura_min_count=$aura_min_count"
    echo "=================="
}

function save_config() {
    echo "notify_only_special_biome=$notify_only_special_biome" > "$CONFIG_FILE"
    echo "aura_min_count=$aura_min_count" >> "$CONFIG_FILE"
}

# メインメニュー
while true; do
    echo
    echo "=== 設定メニュー ==="
    echo "1) URL環境設定"
    echo "2) Discord通知設定"
    echo "3) 現在の設定をすべて確認"
    echo "4) 終了"
    read -p "選択してください: " choice

    case $choice in
        1)
            echo "=== URL環境設定 ==="
            echo "1) Discord Webhook URL 設定"
            echo "2) Roblox Private Server URL 設定"
            echo "3) 戻る"
            read -p "選択してください: " sub
            case $sub in
                1) set_webhook ;;
                2) set_private_server ;;
            esac
            ;;
        2)
            set_discord_notify
            ;;
        3)
            show_all_settings
            ;;
        4)
            save_config
            echo "設定を保存して終了します。"
            exit 0
            ;;
        *)
            echo "無効な選択です"
            ;;
    esac
done
