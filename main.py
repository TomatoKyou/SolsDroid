#!/data/data/com.termux/files/usr/bin/python3
import os
import subprocess
import requests
import json
import sys

print("===SolsDroid Beta1.1.0を開始しました！===")

# 初回入力をチェック
WEBHOOK_FILE = "./webhook.txt"
SERVER_FILE = "./server.txt"
BIOME_FILE = "./biome.json"
AURA_FILE = "./auras.json"

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

# biome.json 読み込み
if os.path.isfile(BIOME_FILE):
    with open(BIOME_FILE, "r", encoding="utf-8") as f:
        BIOME_DATA = json.load(f)
else:
    BIOME_DATA = {}
    print("[WARN] biome.json が見つかりませんでした")

# auras.json 読み込み
if os.path.isfile(AURA_FILE):
    with open(AURA_FILE, "r", encoding="utf-8") as f:
        AURA_DATA = json.load(f)
else:
    AURA_DATA = {}
    print("[WARN] auras.json が見つかりませんでした")

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

def get_aura_colour(rarity: int) -> int:
    if rarity >= 100_000_000:
        return int("ff0000", 16)  # 赤
    elif rarity >= 10_000_000:
        return int("8000ff", 16)  # 紫と青の中間
    elif rarity >= 1_000_000:
        return int("ff69b4", 16)  # ピンク
    else:
        return int("ffffff", 16)  # 白

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

            raw_state = data_field.get("state", "")
            
            if raw_state.startswith("Equipped "):
                state = raw_state[len("Equipped "):].strip('"')
            else:
                state = raw_state
                
            large_image = data_field.get("largeImage") or {}
            biome = large_image.get("hoverText", "")

            # オーラ装備通知
            if state and state != last_state:
                aura_info = AURA_DATA.get(state, {})
                rarity = aura_info.get("rarity", 0)
                formatted_rarity = f"{rarity:,}"
                embed_colour = get_aura_colour(rarity)
                if formatted_rarity == "0":
                    formatted_rarity = "Unknown"

                payload_aura = {
                    "embeds": [{
                        "title": f"Aura Equipped - {state}",
                        "fields": [
                            {"name": "Rarity:", "value": f"1 in {formatted_rarity}", "inline": True},
                        ],
                        "color": embed_colour,
                        "footer": {"text": "SolsDroid | Beta v1.1.0"}
                    }]
                }
                send_webhook(payload_aura)
                last_state = state
            # バイオーム終了通知 ＆ 開始通知
            if biome != last_biome:
                if last_biome:
                    # Biome Ended
                    biome_info_end = BIOME_DATA.get(last_biome, {})
                    embed_colour_end = int(biome_info_end.get("colour", "#ffffff").replace("#", ""), 16)

                    payload_end = {
                        "embeds": [{
                            "title": f"Biome Ended - {last_biome}",
                            "footer": {"text": "SolsDroid | Beta v1.1.0"},
                            "color": embed_colour_end
                        }]
                    }
                    send_webhook(payload_end)

                # Biome Started
                biome_info_start = BIOME_DATA.get(biome, {})
                embed_colour_start = int(biome_info_start.get("colour", "#ffffff").replace("#", ""), 16)
                embed_img_start = biome_info_start.get("img_url", None)

                payload_start = {
                    "embeds": [{
                        "title": f"Biome Started - {biome}",
                        "fields": [
                            {"name": "Private Server", "value": PRIVATE_SERVER_URL, "inline": False}
                        ],
                        "footer": {"text": "SolsDroid | Beta v1.1.0"},
                        "color": embed_colour_start
                    }]
                }
                if embed_img_start:
                    payload_start["embeds"][0]["thumbnail"] = {"url": embed_img_start}

                send_webhook(payload_start)
                last_biome = biome

        except Exception as e:
            print(f"[ERROR] JSONの読み取りに失敗しました: {e}")

except KeyboardInterrupt:
    print("\n[INFO] Ctrl+Cによって終了されました")
    process.terminate()
    process.wait()
except Exception as e:
    print(f"[ERROR] Unexpected error: {e}")
    process.terminate()
    process.wait()
