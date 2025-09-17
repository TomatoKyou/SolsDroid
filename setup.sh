#!/bin/bash

echo "ワイヤレスデバッグ接続用ポート番号を入力してください(開発者向けオプションにあります)"
read PORT

echo "[Macro Setup] localhost:$PORTにアクセスしています..."
OUTPUT=$(adb connect localhost:$PORT 2>&1)

if echo "$OUTPUT" | grep -q "Connection refused"; then
    echo "❌ adbのセットアップに失敗しましたD: ワイヤレスデバッグを一度OFF、再度ONにしたあと、新しいポート番号でやり直してください。"
    exit 1
fi

echo "[Macro Setup] 接続をTCP:5555に変更しています..."
adb tcpip 5555

echo "[Macro Setup] adbサーバーを再起動しています..."
adb kill-server
adb start-server

echo "[Macro Setup] 起動時セットアップが正常に完了しました"

DEVICES=$(adb devices)
if ! echo "$DEVICES" | grep -q "emulator-5554"; then
    echo "注意:emulator-5554が接続されていません。マクロが正常動作しなかった場合Discordでサポートを受けてください。"
fi
