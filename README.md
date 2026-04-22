```
mkdir -p /opt/v && cd /opt/v && \
echo "V_API_KEY=XXXXXXXXXXXXX" > .env && \
apt update && apt install -y python3 python3-pip python3-venv && \
python3 -m venv venv && source venv/bin/activate && \
pip install --upgrade pip requests python-dotenv prompt_toolkit && \
cat > v.py << 'EOF'
import os, sys, json, requests
from datetime import datetime
from dotenv import load_dotenv
from prompt_toolkit import PromptSession

load_dotenv()
A = os.getenv("V_API_KEY", "").strip()
M = "kimi-k2.5"
U = "https://api.moonshot.ai/v1/chat/completions"
session = PromptSession()

VERSION = "⁰³"
THINKING = "disabled"
MEMORY = "off"
HISTORY = []

def header():
    time_str = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    print("\033cV " + VERSION + " | " + M + " (Moonshot) | thinking: " + THINKING + " | memory: " + MEMORY + " | " + time_str + "\n")

def chat(p):
    global HISTORY
    h = {"Authorization": f"Bearer {A}"}
    msgs = HISTORY + [{"role": "user", "content": p}] if MEMORY == "on" else [{"role": "user", "content": p}]
    d = {"model": M, "messages": msgs, "stream": True, "thinking": {"type": THINKING}}
    try:
        with requests.post(U, headers=h, json=d, stream=True) as r:
            r.raise_for_status()
            print("\n~ ", end="", flush=True)
            full = ""
            for l in r.iter_lines():
                if l:
                    try: l = l.decode('utf-8')
                    except: l = l.decode('utf-8', errors='replace')
                if l and l.startswith("data: "):
                    data = l[6:]
                    if data == "[DONE]": break
                    try:
                        c = json.loads(data).get("choices", [{}])[0].get("delta", {}).get("content", "")
                        if c:
                            print(c, end="", flush=True)
                            full += c
                    except: continue
            print("\n")
            if MEMORY == "on":
                HISTORY.append({"role": "user", "content": p})
                HISTORY.append({"role": "assistant", "content": full})
    except Exception as e:
        print(f"[error] {e}\n")

header()
while True:
    try:
        u = session.prompt("> ")
    except (EOFError, KeyboardInterrupt):
        break
    u = u.strip()
    if not u: continue
    if u == "/t":
        THINKING = "enabled" if THINKING == "disabled" else "disabled"
        header()
        print("~ thinking: " + THINKING + "\n")
    elif u == "/m":
        MEMORY = "on" if MEMORY == "off" else "off"
        if MEMORY == "off": HISTORY = []
        header()
        print("~ memory: " + MEMORY + (" (cleared)" if MEMORY == "off" else "") + "\n")
    elif u == "/c":
        header()
    elif u in ["/exit", "/q"]:
        break
    else:
        chat(u)
EOF
echo "alias v='cd /opt/v && source venv/bin/activate && python v.py'" >> ~/.bashrc && \
source ~/.bashrc && \
python v.py
```


>    Commands

-  /t — thinking: enabled / disabled
-  /m — toggle memory: on / off 
-  /c — clear

