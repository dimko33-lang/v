#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then 
    echo "Error: run as root"
    exit 1
fi

KEY="$1"
if [ -z "$KEY" ]; then
    echo "Usage: curl -s URL | sudo bash -s -- \"YOUR-KIMI-KEY\""
    exit 1
fi

# Dependencies
apt update
apt install -y python3 python3-pip python3-venv

# Directory
mkdir -p /opt/v
cd /opt/v

# API Key
echo "V_API_KEY=$KEY" > .env
chmod 600 .env

# Python env
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install requests python-dotenv

# === v.py: Терминальный VOID ===
cat > v.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
import json
import requests
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("V_API_KEY", "").strip()
MODEL = "kimi-k2.5"
URL = "https://api.moonshot.ai/v1/chat/completions"
LOG_FILE = "/opt/v/v.log"

def log(content):
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(f"{content}\n***\n")

def chat(prompt):
    headers = {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}
    payload = {"model": MODEL, "messages": [{"role": "user", "content": prompt}], "stream": True}
    
    print()
    try:
        with requests.post(URL, headers=headers, json=payload, stream=True) as r:
            r.raise_for_status()
            full_response = ""
            for line in r.iter_lines(decode_unicode=True):
                if line and line.startswith("data: "):
                    data = line[6:]
                    if data == "[DONE]":
                        break
                    try:
                        chunk = json.loads(data).get("choices", [{}])[0].get("delta", {}).get("content", "")
                        if chunk:
                            print(chunk, end="", flush=True)
                            full_response += chunk
                    except:
                        continue
            log(full_response)
            print("\n")
    except Exception as e:
        err = f"[error] {e}"
        print(err)
        log(err)

if __name__ == "__main__":
    print("\nV. Пустота. /exit для выхода.\n")
    while True:
        try:
            user_input = input("> ")
        except (EOFError, KeyboardInterrupt):
            print("\n")
            break
        
        if user_input.lower() in ["/exit", "/q"]:
            break
        
        if not user_input.strip():
            continue
        
        log(user_input)
        chat(user_input)
EOF

chmod +x v.py

echo ""
echo "✅ V установлен в /opt/v"
echo ""
echo "Запуск:"
echo "  cd /opt/v && source venv/bin/activate && python v.py"
echo ""
echo "Или одной командой:"
echo "  cd /opt/v && ./v.py"
