#!/bin/bash
set -e
[ "$EUID" -ne 0 ]&&echo "Error: root"&&exit 1
[ -z "$1" ]&&echo "Usage: ... | bash -s -- KEY"&&exit 1
apt update&&apt install -y python3 python3-pip python3-venv
mkdir -p /opt/v&&cd /opt/v
echo "V_API_KEY=$1">.env&&chmod 600 .env
python3 -m venv venv&&source venv/bin/activate
pip install --upgrade pip requests python-dotenv
cat>v.py<<'EOF'
import os,sys,json,requests
from dotenv import load_dotenv
load_dotenv()
A=os.getenv("V_API_KEY","").strip()
M="kimi-k2.5"
U="https://api.moonshot.ai/v1/chat/completions"
L="/opt/v/v.log"
def log(c):
 with open(L,'a',encoding='utf-8')as f:f.write(f"{c}\n***\n")
def chat(p):
 h={"Authorization":f"Bearer {A}"}
 d={"model":M,"messages":[{"role":"user","content":p}],"stream":True}
 try:
  with requests.post(U,headers=h,json=d,stream=True)as r:
   r.raise_for_status()
   full=""
   for l in r.iter_lines():
    if l:
     try:l=l.decode('utf-8')
     except:l=l.decode('cp1251',errors='replace')
    if l and l.startswith("data: "):
     data=l[6:]
     if data=="[DONE]":break
     try:
      c=json.loads(data).get("choices",[{}])[0].get("delta",{}).get("content","")
      if c:print(c,end="",flush=True);full+=c
     except:continue
   log(full)
   print("\n")
 except Exception as e:print(f"[error] {e}");log(f"[error] {e}")
print("\nV. /exit.\n")
while True:
 try:u=input("> ")
 except:break
 if u.lower()in["/exit","/q"]:break
 if not u.strip():continue
 log(u);chat(u)
EOF
chmod +x v.py
echo "alias v='clear && cd /opt/v && source venv/bin/activate && python v.py'" >> /etc/bash.bashrc
echo -e "\n✅ V installed. Type 'v' to enter VOID.\n"
