#!/data/data/com.termux/files/usr/bin/python3
import os
import subprocess
import requests
import json
import sys

print("=== logwatch.py (完全版: 状態管理 + Embed改良 + 通知制御) start ===")

WEBHOOK_FILE = "./webhook.txt"
SERVER_FILE = "./server.txt"
CONFIG_FILE = "./config.json"

# txt ファイルが無い or 空ならエラーで停止
if not os.path.isfile(WEBHOOK_FILE) or os.path.getsize(WEBHOOK_FILE) == 0:
    print("[ERROR] webhook.txt が存在しないか中身が空です。")
    print("   先に settings.sh を実行して設定してください。")
    sys.exit(1)
else:
    with open(WEBHOOK_FILE, "r") as f:
        WEBHOOK_URL = f.read().strip()

if not os.path.isfile(SERVER_FILE) or os.path.getsize(SERVER_FILE) == 0:
    print("[ERROR] server.txt が存在しないか中身が空です。")
    print("   先に settings.sh を実行して設定してください。")
    sys.exit(1)
else:
    with open(SERVER_FILE, "r") as f:
        PRIVATE_SERVER_URL = f.read().strip()

print(f"[INFO] あなたの現在のWebhookURL: {WEBHOOK_URL}")
print(f"[INFO] あなたの現在のPSURL: {PRIVATE_SERVER_URL}")

# config.json 読み込み（無ければデフォルト値）
if os.path.isfile(CONFIG_FILE):
    try:
        with open(CONFIG_FILE, "r") as f:
            config = json.load(f)
    except Exception:
        config = {}
else:
    config = {}

NOTIFY_ONLY_SPECIAL_BIOME = config.get("notify_only_special_biome", False)
AURA_MIN_COUNT = config.get("aura_min_count", 0)  # 今後使用予定

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

            # -----------------------------
            # Aura equipped 通知（常に送信）
            # -----------------------------
            if state != last_state:
                payload = {
                    "embeds": [{
                        "title": "Aura equipped",
                        "fields": [{"name": "Equipped Aura", "value": state, "inline": False}],
                        "footer": {"text": "SolsDroid made by TomatoKurui"}
                    }]
                }
                # GLITCHED / DREAMSPACE の場合のみ @everyone
                if biome in ["GLITCHED", "DREAMSPACE"]:
                    payload["content"] = "@everyone"
                send_webhook(payload)
                last_state = state

            # -----------------------------
            # バイオーム通知制御
            # -----------------------------
            if NOTIFY_ONLY_SPECIAL_BIOME and biome not in ["GLITCHED", "DREAMSPACE"]:
                continue  # GLITCHED / DREAMSPACE 以外は通知スキップ

            if biome != last_biome:
                # バイオーム終了通知
                if last_biome:
                    payload_end = {
                        "embeds": [{
                            "title": "Biome ended",
                            "fields": [{"name": "Ended Biome", "value": last_biome, "inline": False}],
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
