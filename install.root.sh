#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then 
    echo "Run as root"
    exit 1
fi

KEY="$1"
if [ -z "$KEY" ]; then
    echo "Usage: curl -s URL | sudo bash -s -- \"sk-...\""
    exit 1
fi

mkdir -p /opt/v && cd /opt/v
echo "V_API_KEY=$KEY" > .env
apt update && apt install -y python3 python3-pip python3-venv
python3 -m venv venv && source venv/bin/activate
pip install --upgrade pip requests python-dotenv prompt_toolkit

cat > v.py << 'EOF'
import os, sys, json, requests, subprocess, re
from dotenv import load_dotenv
from prompt_toolkit import PromptSession
from prompt_toolkit.history import FileHistory

load_dotenv()
A = os.getenv("V_API_KEY", "").strip()
M = "kimi-k2.5"
U = "https://api.moonshot.ai/v1/chat/completions"
LOG_FILE = "/opt/v/v.log"

session = PromptSession(history=FileHistory('/opt/v/.v_history'))

def log(c):
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(f"{c}\n***\n")

def execute_command(cmd: str) -> str:
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30, cwd="/")
        output = result.stdout + result.stderr
        return output if output else "(no output)"
    except subprocess.TimeoutExpired:
        return "(timeout)"
    except Exception as e:
        return f"(error: {e})"

def parse_tools(content: str) -> str:
    def repl_cmd(m):
        cmd = m.group(1).strip()
        output = execute_command(cmd)
        return f"[executed: {cmd}]\n{output}"
    return re.sub(r'\[CMD\](.*?)\[/CMD\]', repl_cmd, content, flags=re.DOTALL)

def chat(p):
    h = {"Authorization": f"Bearer {A}"}
    d = {"model": M, "messages": [{"role": "user", "content": p}], "stream": True}
    try:
        with requests.post(U, headers=h, json=d, stream=True) as r:
            r.raise_for_status()
            print("\n~ ", end="")
            first_chunk = True
            full = ""
            for l in r.iter_lines():
                if l:
                    try:
                        l = l.decode('utf-8')
                    except:
                        l = l.decode('utf-8', errors='replace')
                if l and l.startswith("data: "):
                    data = l[6:]
                    if data == "[DONE]":
                        break
                    try:
                        c = json.loads(data).get("choices", [{}])[0].get("delta", {}).get("content", "")
                        if c:
                            if first_chunk:
                                print(c, end="", flush=True)
                                first_chunk = False
                            else:
                                if c == "\n":
                                    print("\n", end="", flush=True)
                                else:
                                    print(c, end="", flush=True)
                            full += c
                    except:
                        continue
            if '[CMD]' in full:
                full = parse_tools(full)
                print(f"\n{full}")
            log(full)
            print()
    except Exception as e:
        print(f"[error] {e}")
        log(f"[error] {e}")

print("\033cV ⁰³\n")
while True:
    try:
        u = session.prompt("> ")
    except (EOFError, KeyboardInterrupt):
        break

    if u.lower().strip() in ["/exit", "/q"]:
        break
    u = u.strip()
    if not u:
        continue

    if u.lower() in ["/paste", "/p"]:
        try:
            u = sys.stdin.read().strip()
        except:
            u = ""
        if not u:
            continue

    log(f"> {u}")
    chat(u)
EOF

echo "alias v='cd /opt/v && source venv/bin/activate && python v.py'" >> ~/.bashrc
source ~/.bashrc
python v.py
