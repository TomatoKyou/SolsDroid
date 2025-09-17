#!/data/data/com.termux/files/usr/bin/python3
import os
import subprocess
import requests
import json
import sys

print("=== logwatch.py (完全版: 状態管理 + Embed改良) start ===")

WEBHOOK_FILE = "./webhook.txt"
SERVER_FILE = "./server.txt"

# txt ファイルが無い or 空ならエラーで停止
if not os.path.isfile(WEBHOOK_FILE) or os.path.getsize(WEBHOOK_FILE) == 0:
    print("❌ webhook.txt が存在しないか中身が空です。")
    print("   先に settings.sh を実行して設定してください。")
    sys.exit(1)
else:
    with open(WEBHOOK_FILE, "r") as f:
        WEBHOOK_URL = f.read().strip()

if not os.path.isfile(SERVER_FILE) or os.path.getsize(SERVER_FILE) == 0:
    print("❌ server.txt が存在しないか中身が空です。")
    print("   先に settings.sh を実行して設定してください。")
    sys.exit(1)
else:
    with open(SERVER_FILE, "r") as f:
        PRIVATE_SERVER_URL = f.read().strip()

print(f"[INFO] あなたの現在のWebhookURL: {WEBHOOK_URL}")
print(f"[INFO] あなたの現在のPSURL: {PRIVATE_SERVER_URL}")

# adb logcat
adb_cmd = ["adb", "logcat", "-v", "brief"]
print(f"[INFO] ADBコマンドを実行しています: {' '.join(adb_cmd)}")

try:
    process = subprocess.Popen(adb_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
except Exception as e:
    print(f"[ERROR] ADBを開始するのに失敗しました！setup.shは実行しましたか？: {e}")
    exit(1)

last_state = None
last_biome = None

def send_webhook(payload):
    try:
        response = requests.post(WEBHOOK_URL, json=payload)
        print(f"[INFO] Webhookが応答しました: {response.status_code}")
    except Exception as e:
        print(f"[ERROR] Webhookの送信に失敗しました: {e}")

try:
    for raw_line in process.stdout:
        try:
            line = raw_line.decode("utf-8", errors="replace").strip()
        except Exception as e:
            print(f"[ERROR] 行をデコードするのに失敗しました、このエラーが発生した場合Discordで開発者に連絡してください: {e}")
            continue

        if not line or "[BloxstrapRPC]" not in line:
            continue

        print(f"[LOG] {line}")

        try:
            json_start = line.index("{")
            json_str = line[json_start:]
            data = json.loads(json_str)
            data_field = data.get("data") or {}

            state = data_field.get("state", "")
            large_image = data_field.get("largeImage") or {}
            biome = large_image.get("hoverText", "")

            # オーラ装備通知
            if state != last_state:
                payload = {
                    "embeds": [{
                        "title": "Aura equipped",
                        "fields": [
                            {"name": "Equipped Aura", "value": state, "inline": False}
                        ],
                        "footer": {"text": "SolsDroid made by TomatoKurui"}
                    }]
                }
                # 特定バイオームで @everyone
                if biome in ["GLITCHED", "DREAMSPACE"]:
                    payload["content"] = "@everyone"
                send_webhook(payload)
                last_state = state

            # バイオーム終了通知
            if biome != last_biome:
                if last_biome:
                    payload_end = {
                        "embeds": [{
                            "title": "Biome ended",
                            "fields": [
                                {"name": "Ended Biome", "value": last_biome, "inline": False}
                            ],
                            "footer": {"text": "SolsDroid made by TomatoKurui"}
                        }]
                    }
                    send_webhook(payload_end)

                # バイオーム開始通知
                payload_start = {
                    "embeds": [{
                        "title": "New biome started",
                        "fields": [
                            {"name": "New Biome", "value": biome, "inline": False},
                            {"name": "Private Server", "value": PRIVATE_SERVER_URL, "inline": False}
                        ],
                        "footer": {"text": "SolsDroid made by TomatoKurui"}
                    }]
                }
                send_webhook(payload_start)
                last_biome = biome

        except Exception as e:
            print(f"[ERROR] JSONコンテンツを見つけられませんでした: {e}")

except KeyboardInterrupt:
    print("\n[INFO] SolsDroidはユーザーによって終了されました")
    process.terminate()
except Exception as e:
    print(f"[ERROR] 重大なエラーが発生しました: {e}")
    process.terminate()
