#!/data/data/com.termux/files/usr/bin/python3
import os
import subprocess
import requests
import json

print("===SolsDroid Beta1.0.0を開始しました！===")

# 初回入力をチェック
WEBHOOK_FILE = "./webhook.txt"
SERVER_FILE = "./server.txt"

if os.path.isfile(WEBHOOK_FILE):
    with open(WEBHOOK_FILE, "r") as f:
        WEBHOOK_URL = f.read().strip()
else:
    WEBHOOK_URL = input("Enter Discord Webhook URL: ").strip()
    with open(WEBHOOK_FILE, "w") as f:
        f.write(WEBHOOK_URL)

if os.path.isfile(SERVER_FILE):
    with open(SERVER_FILE, "r") as f:
        PRIVATE_SERVER_URL = f.read().strip()
else:
    PRIVATE_SERVER_URL = input("Enter Private Server URL: ").strip()
    with open(SERVER_FILE, "w") as f:
        f.write(PRIVATE_SERVER_URL)

print(f"[INFO] 使用中のDiscordWebhookURL: {WEBHOOK_URL}")
print(f"[INFO] 使用中のプライベートサーバーURL: {PRIVATE_SERVER_URL}")

# adb logcat
adb_cmd = ["adb", "logcat", "-v", "brief"]
print(f"[INFO] ADBコマンドを実行しています: {' '.join(adb_cmd)}")

try:
    process = subprocess.Popen(adb_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
except Exception as e:
    print(f"[INFO] ADBの開始に失敗しました、setup.shは実行しましたか？: {e}")
    exit(1)

last_state = None
last_biome = None

def send_webhook(payload):
    try:
        response = requests.post(WEBHOOK_URL, json=payload)
        print(f"[DEBUG] Webhookが応答しました: {response.status_code}")
    except Exception as e:
        print(f"[ERROR] Webhookの送信に失敗しました: {e}")

try:
    for raw_line in process.stdout:
        try:
            line = raw_line.decode("utf-8", errors="replace").strip()
        except Exception as e:
            print(f"[ERROR] 行のデコードに失敗しました: {e}")
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
            print(f"[ERROR] JSONの読み取りに失敗しました: {e}")

except KeyboardInterrupt:
    print("\n[INFO] logwatch.pyはユーザーによって終了されました")
    process.terminate()
except Exception as e:
    print(f"[ERROR] Unexpected error: {e}")
    process.terminate()

