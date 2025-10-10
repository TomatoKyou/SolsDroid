#!/data/data/com.termux/files/usr/bin/python3
import os
import subprocess
import requests
import json
import sys
import time

print("=== Starting SolsDroid Beta 1.0.0 ===")

# Initial input check
CONFIG_FILE = "./config.txt"
BIOME_FILE = "./biome.json"
AURA_FILE = "./auras.json"

def load_config():
    config = {}
    if not os.path.isfile(CONFIG_FILE):
        print("[ERROR] config.txt not found. Did you run setup.sh?")
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
    print("[INFO] config.txt has been updated.")

def ensure_config_values(config):
    updated = False

    if config.get("WEBHOOK_URL") == "unconfigured":
        config["WEBHOOK_URL"] = input("Enter your Discord Webhook URL: ").strip()
        updated = True

    if config.get("PRIVATE_SERVER_URL") == "unconfigured":
        config["PRIVATE_SERVER_URL"] = input("Enter your Private Server URL: ").strip()
        updated = True

    if config.get("DISCORD_USER_ID") == "unconfigured":
        config["DISCORD_USER_ID"] = input("Enter your Discord User ID: ").strip()
        updated = True

    if updated:
        save_config(config)

    return config
    
# Load biome.json
if os.path.isfile(BIOME_FILE):
    with open(BIOME_FILE, "r", encoding="utf-8") as f:
        BIOME_DATA = json.load(f)
else:
    BIOME_DATA = {}
    print("[WARN] biome.json not found.")

# Load auras.json
if os.path.isfile(AURA_FILE):
    with open(AURA_FILE, "r", encoding="utf-8") as f:
        AURA_DATA = json.load(f)
else:
    AURA_DATA = {}
    print("[WARN] auras.json not found.")

# adb logcat
adb_cmd = ["adb", "logcat", "-v", "brief"]
print(f"[INFO] Running ADB command: {' '.join(adb_cmd)}")

config = load_config()
config = ensure_config_values(config)

WEBHOOK_URL = config.get("WEBHOOK_URL")
PRIVATE_SERVER_URL = config.get("PRIVATE_SERVER_URL")
DISCORD_USER_ID = config.get("DISCORD_USER_ID")
MIN_NOTIFY_RARITY = int(config.get("MIN_NOTIFY_RARITY", 0))
DONT_NOTIFY_BIOME_WITHOUT_LIMITED = config.get("DONT_NOTIFY_BIOME_WITHOUT_LIMITED", "false").lower() == "true"

print(f"[INFO] Using Discord Webhook URL: {WEBHOOK_URL}")
print(f"[INFO] Using Private Server URL: {PRIVATE_SERVER_URL}")

try:
    process = subprocess.Popen(adb_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
except Exception as e:
    print(f"[ERROR] Failed to start ADB. Did you run setup.sh? Details: {e}")
    exit(1)

last_state = None
last_biome = None

def send_webhook(payload):
    try:
        response = requests.post(WEBHOOK_URL, json=payload)
    except Exception as e:
        print(f"[ERROR] Failed to send webhook: {e}")

def get_aura_colour(rarity: int) -> int:
    if rarity >= 100_000_000:
        return int("ff0000", 16)  # Red
    elif rarity >= 10_000_000:
        return int("8000ff", 16)  # Purple-blue
    elif rarity >= 1_000_000:
        return int("ff69b4", 16)  # Pink
    else:
        return int("ffffff", 16)  # White

try:
    for raw_line in process.stdout:
        try:
            line = raw_line.decode("utf-8", errors="replace").strip()
        except Exception as e:
            print(f"[ERROR] Failed to decode line: {e}")
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

            # Aura equipped notification
            if state and state != last_state:
                state_lower = state.lower()
                aura_info = AURA_DATA.get(state_lower, {})
                rarity = int(aura_info.get("rarity", 0))
                aura_thumbnail = aura_info.get("img_url")
                formatted_rarity = f"{rarity:,}"
                embed_colour = get_aura_colour(rarity)
                if formatted_rarity == "0":
                    formatted_rarity = "Unknown"

                payload_aura = {
                    "embeds": [{
                        "title": f"Aura Equipped - {state}",
                        "thumbnail": {"url": aura_thumbnail},
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

            # Biome end & start notifications
            if biome != last_biome:
                if DONT_NOTIFY_BIOME_WITHOUT_LIMITED:
                    if biome not in ("GLITCHED", "DREAMSPACE"):
                        last_biome = biome
                        continue
                # Biome Ended
                biome_info_end = BIOME_DATA.get(last_biome, {})
                embed_colour_end = int(biome_info_end.get("colour", "#ffffff").replace("#", ""), 16)
                biome_end_time = int(time.time())

                payload_end = {
                    "embeds": [{
                        "title": f"Biome Ended - {last_biome}",
                        "description": f"**<t:{biome_end_time}:T>** (**<t:{biome_end_time}:R>**)",
                        "footer": {"text": "SolsDroid | Beta v1.1.0"},
                        "color": embed_colour_end
                    }]
                }
                send_webhook(payload_end)

                # Biome Started
                biome_info_start = BIOME_DATA.get(biome, {})
                embed_colour_start = int(biome_info_start.get("colour", "#ffffff").replace("#", ""), 16)
                embed_img_start = biome_info_start.get("img_url", None)
                biome_start_time = int(time.time())

                payload_start = {
                    "embeds": [{
                        "title": f"Biome Started - {biome}",
                        "description": f"**<t:{biome_start_time}:T>** (**<t:{biome_start_time}:R>**)",
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
            print(f"[ERROR] Failed to parse JSON: {e}")

except KeyboardInterrupt:
    print("\n[INFO] Exiting due to Ctrl+C")
    process.terminate()
    process.wait()
except Exception as e:
    print(f"[ERROR] Unexpected error: {e}")
    process.terminate()
    process.wait()
