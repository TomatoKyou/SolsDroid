#!/bin/bash

echo "Enter your adb wireless debug port (from Android settings):"
read PORT

echo "[Macro Setup] Connecting to localhost:$PORT..."
adb connect localhost:$PORT

echo "[Macro Setup] Switching to TCP 5555..."
adb tcpip 5555
adb connect localhost:5555
adb disconnect localhost:$PORT

echo "[Macro Setup] Restarting adb server..."
adb kill-server
adb start-server

echo "[Macro Setup] Setup completed successfully."

