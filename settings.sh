#!/bin/bash

WEBHOOK_FILE="./webhook.txt"
SERVER_FILE="./server.txt"
CONFIG_FILE="./config.json"

# JSON設定の読み込み関数
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        NOTIFY_ONLY_SPECIAL_BIOME=$(jq -r '.notify_only_special_biome' "$CONFIG_FILE")
        AURA_MIN_COUNT=$(jq -r '.aura_min_count' "$CONFIG_FILE")
    else
        NOTIFY_ONLY_SPECIAL_BIOME=false
        AURA_MIN_COUNT=0
    fi
}

# JSON設定の保存関数
save_config() {
    cat > "$CONFIG_FILE" <<EOF
{
    "notify_only_special_biome": $NOTIFY_ONLY_SPECIAL_BIOME,
    "aura_min_count": $AURA_MIN_COUNT
}
EOF
}

# Webhook / Server URL 設定
url_settings() {
    while true; do
        echo "=== URL環境設定 ==="
        echo "1) Discord Webhook URL 設定"
        echo "2) Roblox Private Server URL 設定"
        echo "3) 戻る"
        read -p "選択: " choice
        case $choice in
            1)
                if [ -f "$WEBHOOK_FILE" ]; then
                    current=$(cat "$WEBHOOK_FILE")
                    echo "現在の Discord Webhook URL: $current"
                    read -p "変更しますか？(y/n) " yn
                    if [[ $yn =~ ^[Yy]$ ]]; then
                        read -p "新しい Webhook URL を入力: " new
                        echo "$new" > "$WEBHOOK_FILE"
                    fi
                else
                    read -p "Discord Webhook URL を入力: " new
                    echo "$new" > "$WEBHOOK_FILE"
                fi
                ;;
            2)
                if [ -f "$SERVER_FILE" ]; then
                    current=$(cat "$SERVER_FILE")
                    echo "現在の Private Server URL: $current"
                    read -p "変更しますか？(y/n) " yn
                    if [[ $yn =~ ^[Yy]$ ]]; then
                        read -p "新しい Private Server URL を入力: " new
                        echo "$new" > "$SERVER_FILE"
                    fi
                else
                    read -p "Private Server URL を入力: " new
                    echo "$new" > "$SERVER_FILE"
                fi
                ;;
            3)
                return
                ;;
            *)
                echo "無効な選択です"
                ;;
        esac
    done
}

# Discord通知設定
discord_settings() {
    load_config
    while true; do
        echo "=== Discord通知設定 ==="
        echo "1) オーラメンションの最小値（未実装）"
        echo "2) 限定バイオーム以外の通知を無効化"
        echo "3) 戻る"
        read -p "選択: " choice
        case $choice in
            1)
                echo "未実装です。スキップします。"
                ;;
            2)
                echo "現在の設定: $NOTIFY_ONLY_SPECIAL_BIOME"
                read -p "変更しますか？(y/n) " yn
                if [[ $yn =~ ^[Yy]$ ]]; then
                    read -p "無効化しますか？(y/n) " yn2
                    if [[ $yn2 =~ ^[Yy]$ ]]; then
                        NOTIFY_ONLY_SPECIAL_BIOME=true
                    else
                        NOTIFY_ONLY_SPECIAL_BIOME=false
                    fi
                    save_config
                fi
                ;;
            3)
                return
                ;;
            *)
                echo "無効な選択です"
                ;;
        esac
    done
}

# 現在の設定を確認
show_settings() {
    echo "=== 現在の設定 ==="
    echo "Discord Webhook URL: $(cat "$WEBHOOK_FILE" 2>/dev/null || echo '未設定')"
    echo "Private Server URL: $(cat "$SERVER_FILE" 2>/dev/null || echo '未設定')"
    load_config
    echo "限定バイオーム以外の通知を無効化: $NOTIFY_ONLY_SPECIAL_BIOME"
    echo "オーラメンションの最小値: $AURA_MIN_COUNT"
    echo "======================="
}

# メインメニュー
while true; do
    echo "=== 設定メニュー ==="
    echo "1) URL環境設定"
    echo "2) Discord通知設定"
    echo "3) 現在の設定をすべて確認"
    echo "4) 終了"
    read -p "選択: " choice
    case $choice in
        1) url_settings ;;
        2) discord_settings ;;
        3) show_settings ;;
        4) exit ;;
        *) echo "無効な選択です" ;;
    esac
done
