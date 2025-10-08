#!/data/data/com.termux/files/usr/bin/python3
import os
import subprocess
import requests
import json
import sys
import time

print("===SolsDroid Beta1.1.0を開始しました！===")

# 初回入力をチェック
CONFIG_FILE = "./config.txt"
BIOME_FILE = "./biome.json"
AURA_FILE = "./auras.json"

def load_config():
    config = {}
    if not os.path.isfile(CONFIG_FILE):
        print("[ERROR] config.txt が存在しません。setup.shを実行しましたか？")
        time.sleep(3)
        exit(1)

    with open(CONFIG_FILE, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, value = line.split("=", 1)
                config[key.strip()] = value.strip().strip('"')
    return config

def save_config(config):
    with open(CONFIG_FILE, "w", encoding="utf-8") as f:
        for key, value in config.items():
            f.write(f'{key}="{value}"\n')
    print("[INFO] config.txt を更新しました。")

def ensure_config_values(config):
    updated = False

    if config.get("WEBHOOK_URL") == "unconfigured":
        config["WEBHOOK_URL"] = input("Discord Webhook URLを入力してください: ").strip()
        updated = True

    if config.get("PRIVATE_SERVER_URL") == "unconfigured":
        config["PRIVATE_SERVER_URL"] = input("Private Server URLを入力してください: ").strip()
        updated = True

    if config.get("DISCORD_USER_ID") == "unconfigured":
        config["DISCORD_USER_ID"] = input("あなたのDiscordユーザーIDを入力してください: ").strip()
        updated = True

    if updated:
        save_config(config)

    return config
    
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

# adb logcat
adb_cmd = ["adb", "logcat", "-v", "brief"]
print(f"[INFO] ADBコマンドを実行しています: {' '.join(adb_cmd)}")

config = load_config()
config = ensure_config_values(config)

WEBHOOK_URL = config.get("WEBHOOK_URL")
PRIVATE_SERVER_URL = config.get("PRIVATE_SERVER_URL")
DISCORD_USER_ID = config.get("DISCORD_USER_ID")
MIN_NOTIFY_RARITY = int(config.get("MIN_NOTIFY_RARITY", 0))
DONT_NOTIFY_BIOME_WITHOUT_LIMITED = config.get("DONT_NOTIFY_BIOME_WITHOUT_LIMITED", "false").lower() == "true"

print(f"[INFO] 使用中のDiscordWebhookURL: {WEBHOOK_URL}")
print(f"[INFO] 使用中のプライベートサーバーURL: {PRIVATE_SERVER_URL}")

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
                if rarity >= MIN_NOTIFY_RARITY:
                    payload_aura["content"] = f"<@{DISCORD_USER_ID}>"                
                    
                send_webhook(payload_aura)
                last_state = state
            # バイオーム終了通知 ＆ 開始通知
            if biome != last_biome:
                if DONT_NOTIFY_BIOME_WITHOUT_LIMITED:
                    if biome not in ("GLITCHED", "DREAMSPACE"):
                        last_biome = biome
                        continue
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
