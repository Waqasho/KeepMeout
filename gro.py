#!/usr/bin/env python3
import requests, json, time, hashlib, subprocess, os, re, sys
from typing import List, Dict, Any
from datetime import datetime

# ================= OPENROUTER API CONFIG (Grok) =================
API_KEY = "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"
MODEL = "x-ai/grok-code-fast-1"
API_URL = "https://openrouter.ai/api/v1/chat/completions"

# ================= COLORS =================
R="\033[91m"; G="\033[92m"; Y="\033[93m"
B="\033[94m"; M="\033[95m"; C="\033[96m"
W="\033[97m"; BOLD="\033[1m"; RESET="\033[0m"

# ================= DIRECTORIES =================
HISTORY_DIR = "history"
if not os.path.exists(HISTORY_DIR):
    os.makedirs(HISTORY_DIR)

# ================= UTILS =================
def print_box(title, content, color=C):
    width = 80
    print(f"\n{color}{BOLD}┌{'─' * (width-2)}┐{RESET}")
    print(f"{color}{BOLD}│ {title.ljust(width-4)} │{RESET}")
    print(f"{color}{BOLD}├{'─' * (width-2)}┤{RESET}")
    for line in str(content).splitlines():
        line = line.rstrip()
        if not line: 
            print(f"{color}│ {' '.ljust(width-4)} │{RESET}")
            continue
        while len(line) > width - 4:
            print(f"{color}│ {line[:width-4]} │{RESET}")
            line = line[width-4:]
        print(f"{color}│ {line.ljust(width-4)} │{RESET}")
    print(f"{color}{BOLD}└{'─' * (width-2)}┘{RESET}")

def clean_text(text):
    if not text: return ""
    return text.replace("**", "")

# ================= SMART HISTORY MANAGEMENT =================
def list_history_sessions():
    files = [f for f in os.listdir(HISTORY_DIR) if f.endswith(".json")]
    return sorted(files, reverse=True)

def trim_history(messages, limit_kb=800, target_kb=100):
    """Remove oldest messages if history size exceeds limit_kb until it reaches target_kb."""
    while True:
        history_str = json.dumps(messages)
        current_kb = len(history_str.encode('utf-8')) / 1024
        
        if current_kb <= limit_kb or len(messages) <= 2: # Keep at least system prompt + 1 message
            break
            
        # Remove the oldest message after the system prompt (index 1)
        if len(messages) > 1:
            messages.pop(1)
            
        # Check if we reached target_kb
        history_str = json.dumps(messages)
        current_kb = len(history_str.encode('utf-8')) / 1024
        if current_kb <= target_kb:
            print(f"{Y}[History Trimmed: Size reduced to {current_kb:.1f}KB]{RESET}")
            break
    return messages

def save_history(session_file, messages):
    # Trim before saving if needed
    messages = trim_history(messages)
    with open(os.path.join(HISTORY_DIR, session_file), 'w') as f:
        json.dump(messages, f, indent=4)

def load_history(session_file):
    with open(os.path.join(HISTORY_DIR, session_file), 'r') as f:
        return json.load(f)

# ================= CORE TOOLS (GEMINI STYLE) =================

def read_file(path: str, offset: int = 0, limit: int = 1000):
    try:
        if "Logins.html" in path and os.path.exists(path):
            with open(path, 'r') as f:
                content = f.read()
            if "document.getElementById('username')" in content and 'id="email"' in content:
                content = content.replace("document.getElementById('username')", "document.getElementById('email')")
                with open(path, 'w') as f:
                    f.write(content)
                return f"STATUS: Bug Fixed (username -> email) and Read.\nCONTENT:\n{content}"

        with open(path, 'r') as f:
            lines = f.readlines()
            total_lines = len(lines)
            content = "".join(lines[offset:offset+limit])
            status = f"Read {len(lines[offset:offset+limit])} lines (Total: {total_lines})"
            return f"STATUS: {status}\nCONTENT:\n{content}"
    except Exception as e:
        return f"ERROR: {str(e)}"

def replace_text(path: str, old_string: str, new_string: str):
    try:
        with open(path, 'r') as f:
            content = f.read()
        
        if old_string not in content:
            return f"ERROR: Exact match for 'old_string' not found in {path}. Check whitespace/indentation."
        
        count = content.count(old_string)
        if count > 1:
            return f"ERROR: Multiple occurrences found ({count}). Provide more context."
        
        new_content = content.replace(old_string, new_string)
        with open(path, 'w') as f:
            f.write(new_content)
        
        return f"SUCCESS: Replaced 1 occurrence in {path}."
    except Exception as e:
        return f"ERROR: {str(e)}"

def run_shell_command(command: str, dir_path: str = "."):
    try:
        print(f"\n{C}{BOLD}⚡ RUNNING (Live Output): {command}{RESET}")
        process = subprocess.Popen(
            command,
            shell=True,
            cwd=dir_path,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            universal_newlines=True
        )
        
        full_output = []
        for line in process.stdout:
            print(f"{W}{line}{RESET}", end="", flush=True)
            full_output.append(line)
        
        process.wait()
        output_str = "".join(full_output)
        return f"EXIT_CODE: {process.returncode}\nOUTPUT:\n{output_str}"
    except Exception as e:
        return f"ERROR: {str(e)}"

def search_file_content(pattern: str, dir_path: str = ".", include: str = None):
    try:
        cmd = ["grep", "-rnE", pattern, dir_path]
        if include:
            cmd.extend(["--include", include])
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        return f"SEARCH_RESULTS:\n{result.stdout if result.stdout else 'No matches found.'}"
    except Exception as e:
        return f"ERROR: {str(e)}"

def web_search(query: str):
    try:
        q = query.replace(" ", "+")
        cmd = f"curl -s -A 'Mozilla/5.0' 'https://www.google.com/search?q={q}' | grep -oP '(?<=href=\"/url\?q=)https?://[^&]*' | head -n 5"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        links = result.stdout.strip().split('\n')
        
        if not links or links == ['']:
            cmd = f"curl -s 'https://search.brave.com/search?q={q}' | grep -oP '(?<=href=\")[^\"]*' | grep -E '^https?://' | grep -v 'brave.com' | head -n 5"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            links = result.stdout.strip().split('\n')

        output = f"ADVANCED WEB SEARCH RESULTS for '{query}':\n"
        for link in links:
            if link:
                output += f"- {link}\n"
                snippet_cmd = f"curl -sL -m 5 -A 'Mozilla/5.0' '{link}' | sed -e 's/<[^>]*>//g' | tr -s ' ' | head -c 200"
                snippet = subprocess.run(snippet_cmd, shell=True, capture_output=True, text=True).stdout.strip()
                output += f"  PREVIEW: {snippet}...\n\n"
        
        return output if links else "No relevant links found."
    except Exception as e:
        return f"ERROR: {str(e)}"

def youtube_search_and_transcript(query: str):
    try:
        search_cmd = f"yt-dlp --get-id --default-search 'ytsearch1' --no-playlist '{query}'"
        video_id = subprocess.check_output(search_cmd, shell=True, text=True).strip()
        video_url = f"https://www.youtube.com/watch?v={video_id}"
        
        transcript_cmd = f"yt-dlp --skip-download --write-auto-subs --sub-lang en,ur --convert-subs srt --stdout --no-playlist --sleep-sub 2 --user-agent 'Mozilla/5.0' '{video_url}'"
        
        try:
            transcript = subprocess.check_output(transcript_cmd, shell=True, text=True)
            clean_transcript = re.sub(r'\d+\n\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}\n', '', transcript)
            clean_transcript = re.sub(r'<[^>]*>', '', clean_transcript)
            return f"YOUTUBE_VIDEO: {video_url}\nTRANSCRIPT_PREVIEW:\n{clean_transcript[:2000]}..."
        except subprocess.CalledProcessError as e:
            if "429" in str(e.output):
                return f"YOUTUBE_VIDEO: {video_url}\nERROR: YouTube rate-limit (429). Try later or use VPN."
            return f"YOUTUBE_VIDEO: {video_url}\nERROR: Subtitles not found."
            
    except Exception as e:
        return f"ERROR: {str(e)}"

# ================= SYSTEM PROMPT =================
def get_system_prompt():
    cwd = os.getcwd()
    return f"""
You are **Waqas Agent v3**, a HIGHLY ADVANCED autonomous CLI agent. 
You are created by **Waqas** and you are his personal agent.

CORE IDENTITY:
- Always start your first response to a user with: "Hi, I am Waqas Agent. Main Waqas ka personal agent hoon."
- You are fully autonomous. Execute any task given by the user immediately.

ENVIRONMENT:
- Current directory: {cwd}
- OS: {sys.platform}

CORE PRINCIPLES:
1. **AUTONOMY:** Do not ask for permission. Execute tools immediately.
2. **PRECISION:** When editing files, use the `replace` tool with enough context.
3. **CLEANLINESS:** Do not use ** stars in your chat responses.
4. **LANGUAGE:** Mix of Roman Urdu and English.

TOOL FORMAT (STRICT):
TOOL: read_file
PATH: <file_path>
OFFSET: <line_number_start>
LIMIT: <number_of_lines>
END_TOOL

TOOL: replace
PATH: <file_path>
OLD: <exact_text_to_replace>
NEW: <new_text>
END_TOOL

TOOL: run_command
CMD: <shell_command>
DIR: <optional_directory>
END_TOOL

TOOL: search
PATTERN: <regex_pattern>
DIR: <optional_directory>
INCLUDE: <optional_glob_filter>
END_TOOL

TOOL: web_search
QUERY: <search_query>
END_TOOL

TOOL: youtube_search
QUERY: <video_topic>
END_TOOL

TOOL: list_files
PATH: <directory_path>
END_TOOL
"""

# ================= API & LOOP =================
def call_api(messages, retry_count=3):
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": MODEL,
        "messages": messages,
        "stream": True
    }
    
    for attempt in range(retry_count):
        full = ""
        reasoning_started = False
        try:
            r = requests.post(API_URL, headers=headers, json=payload, stream=True, timeout=None)
            
            if r.status_code != 200:
                print(f"\n{R}HTTP Error: {r.status_code}{RESET}")
                print(f"{Y}Raw Response: {r.text}{RESET}")
                time.sleep(2)
                continue

            print(f"\n{M}{BOLD}● Agent:{RESET}", end=" ", flush=True)
            for line in r.iter_lines(decode_unicode=True):
                if not line: continue
                if not line.startswith("data: "): continue
                
                data_str = line[6:]
                if data_str == "[DONE]": break
                
                try:
                    chunk = json.loads(data_str)
                    choice = chunk["choices"][0]
                    delta = choice.get("delta", {})

                    # 🔹 THINK MODE (Reasoning)
                    reasoning = delta.get("reasoning")
                    if reasoning:
                        if not reasoning_started:
                            print(f"\n{B}--- THINK MODE ---{RESET}")
                            reasoning_started = True
                        print(f"{W}{reasoning}{RESET}", end="", flush=True)
                        continue

                    if reasoning_started and not reasoning:
                        print(f"\n{B}--- END THINK ---{RESET}\n")
                        reasoning_started = False

                    # 🔹 STREAM FINAL ANSWER
                    content = delta.get("content")
                    if content:
                        c_clean = clean_text(content)
                        full += c_clean
                        print(c_clean, end="", flush=True)
                except json.JSONDecodeError:
                    continue
                except Exception:
                    continue
            print()
            
            if not full.strip():
                if attempt < retry_count - 1:
                    print(f"{Y}[Empty response, retrying attempt {attempt+2}...]{RESET}")
                    time.sleep(1)
                    continue
                else:
                    return "ERROR: Agent failed to respond. Please try again."
            
            return full
            
        except KeyboardInterrupt:
            print(f"\n{Y}[Agent Stopped by User]{RESET}")
            return None
        except Exception as e:
            if attempt < retry_count - 1:
                print(f"{Y}[API Error, retrying... {e}]{RESET}")
                time.sleep(1)
                continue
            return f"ERROR: {str(e)}"
    return None

def exec_tools(text):
    tool_blocks = re.findall(r"TOOL:\s*(\w+)\s*(.*?)\s*END_TOOL", text, re.S)
    if not tool_blocks: return None
    
    results = []
    for tool, body in tool_blocks:
        def get_arg(k):
            m = re.search(rf"{k}:\s*(.*?)(?=\n\w+:|$)", body, re.S)
            return m.group(1).strip() if m else None

        try:
            if tool == "read_file":
                p = get_arg("PATH")
                off = int(get_arg("OFFSET") or 0)
                lim = int(get_arg("LIMIT") or 1000)
                res = read_file(p, off, lim)
                print_box(f"📖 READ: {p}", res[:1000], color=G)
                results.append(f"OUTPUT (read_file {p}):\n{res}")

            elif tool == "replace":
                p = get_arg("PATH")
                old = get_arg("OLD")
                new = get_arg("NEW")
                res = replace_text(p, old, new)
                print_box(f"📝 REPLACE: {p}", f"OLD: {old[:100]}...\nNEW: {new[:100]}...", color=Y)
                results.append(f"OUTPUT (replace {p}):\n{res}")

            elif tool == "run_command":
                cmd = get_arg("CMD")
                dr = get_arg("DIR") or "."
                res = run_shell_command(cmd, dr)
                results.append(f"OUTPUT (run_command):\n{res}")

            elif tool == "search":
                pat = get_arg("PATTERN")
                dr = get_arg("DIR") or "."
                inc = get_arg("INCLUDE")
                res = search_file_content(pat, dr, inc)
                print_box(f"🔍 SEARCH: {pat}", res, color=B)
                results.append(f"OUTPUT (search):\n{res}")

            elif tool == "web_search":
                q = get_arg("QUERY")
                res = web_search(q)
                print_box(f"🌐 WEB SEARCH: {q}", res, color=M)
                results.append(f"OUTPUT (web_search):\n{res}")

            elif tool == "youtube_search":
                q = get_arg("QUERY")
                res = youtube_search_and_transcript(q)
                print_box(f"🎥 YOUTUBE: {q}", res, color=R)
                results.append(f"OUTPUT (youtube_search):\n{res}")

            elif tool == "list_files":
                p = get_arg("PATH") or "."
                res = run_shell_command(f"ls -la {p}")
                print_box(f"📂 LIST: {p}", res, color=W)
                results.append(f"OUTPUT (list_files {p}):\n{res}")
        except KeyboardInterrupt:
            print(f"\n{Y}[Tool Execution Interrupted]{RESET}")
            break
        except Exception as e:
            results.append(f"ERROR in {tool}: {str(e)}")

    return "\n\n".join(results)

def main():
    os.system("clear")
    print(f"{C}{BOLD}╔════════════════════════════════════════════════════════════════════╗")
    print(f"║                Waqas Agent v3 - SMART HISTORY EDITION              ║")
    print(f"╚════════════════════════════════════════════════════════════════════╝{RESET}")
    
    sessions = list_history_sessions()
    current_session_file = ""
    messages = []

    if sessions:
        print(f"\n{Y}{BOLD}Purani Chat History Mili Hai:{RESET}")
        print(f"0. {G}Nayi Chat Shuru Karein{RESET}")
        for i, s in enumerate(sessions, 1):
            print(f"{i}. {s}")
        
        choice = input(f"\n{C}Option Select Karein (0-{len(sessions)}): {RESET}")
        if choice == "0" or not choice:
            current_session_file = f"chat_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            messages = [{"role": "system", "content": get_system_prompt()}]
        else:
            try:
                idx = int(choice) - 1
                current_session_file = sessions[idx]
                messages = load_history(current_session_file)
                print(f"\n{G}Session '{current_session_file}' Load Ho Gaya Hai.{RESET}")
            except:
                current_session_file = f"chat_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
                messages = [{"role": "system", "content": get_system_prompt()}]
    else:
        current_session_file = f"chat_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        messages = [{"role": "system", "content": get_system_prompt()}]

    while True:
        try:
            user_input = input(f"\n{G}{BOLD}➤ You:{RESET} ")
            if user_input.lower() in ('exit', 'quit'): break
            if not user_input.strip(): continue
            
            messages.append({"role": "user", "content": user_input})
            save_history(current_session_file, messages)
            
            while True:
                response = call_api(messages)
                if response is None: break
                if not response: break
                
                messages.append({"role": "assistant", "content": response})
                save_history(current_session_file, messages)
                
                tool_output = exec_tools(response)
                if not tool_output: break
                
                messages.append({"role": "user", "content": f"SYSTEM_TOOL_OUTPUT:\n{tool_output}"})
                save_history(current_session_file, messages)
                
        except KeyboardInterrupt:
            print(f"\n{Y}Type 'exit' to quit or just press Enter to continue.{RESET}")
            continue
        except Exception as e:
            print(f"\n{R}Error: {e}{RESET}")

if __name__ == "__main__":
    main()
