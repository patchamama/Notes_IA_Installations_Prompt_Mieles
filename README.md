# AI Tools & Installations

## Installation

### Requeriments

```sh
# MacOSX
brew install nvm
nvm install --lts
```

### Ollama

```sh
# MacOSX
brew install ollama
ollama

# Install glm-4.7 flash model
ollama pull hf.co/unsloth/GLM-4.7-Flash-GGUF:UD-Q4_K_XL

# Install `quen3.6` with Ollama accelerates (ollama > 0.19), need minimum 32 GB RAM
# See models updated: https://ollama.com/library/qwen3.6
ollama run qwen3.6:27b-coding-nvfp4
ollama launch claude --model qwen3.6:27b-coding-nvfp4  # ollama with claude

ollama run qwen3.6:35b-a3b-coding-nvfp4
ollama launch claude --model qwen3.6:35b-a3b-coding-nvfp4  # ollama with claude

# Launch opencode with Ollama integration
ollama launch opencode --config

# Launch claude with Ollama integration
ollama launch claude --config
```

> [!NOTE]
> This preview release 0.19 of Ollama accelerates the new `Qwen3.5-35B-A3B model`, with sampling parameters tuned for coding tasks.
> Please make sure you have a Mac with more than 32GB of unified memory.

- Activate free/paid model support at <https://opencode.ai/zen> to use `opencode Go`

### LLamaCPP (pendiente)

- Fuente: https://github.com/ggml-org/llama.cpp

### Claude Code

```sh
# Linux & MacOSX
curl -fsSL https://claude.ai/install.sh | bash

# Windows CMD

curl.exe -fsSL https://claude.ai/install.cmd -o install.cmd && call install.cmd && del install.cmd
$env:Path += ";$env:USERPROFILE\.local\bin"

# Windows PS
winget install --id Git.Git -e --source winget

# Or download and install: https://github.com/git-for-windows/git/releases/download/v2.53.0.windows.3/Git-2.53.0.3-64-bit.exe
  [System.Environment]::SetEnvironmentVariable(
  "CLAUDE_CODE_GIT_BASH_PATH",
  "~\AppData\Local\Programs\Git\bin\bash.exe",
  "User"
  )
# or 
$env:CLAUDE_CODE_GIT_BASH_PATH="C:\Program Files\Git\bin\bash.exe"
# or
$env:CLAUDE_CODE_GIT_BASH_PATH="~\AppData\Local\Programs\Git\bin\bash.exe"
echo $env:CLAUDE_CODE_GIT_BASH_PATH
irm https://claude.ai/install.ps1 | iex
~\.local\bin\claude.exe


# Agregar Git al PATH del sistema (requiere PowerShell como Administrador)
$old = [System.Environment]::GetEnvironmentVariable("PATH","Machine")
[System.Environment]::SetEnvironmentVariable("PATH", $old + ";C:\Program Files\Git\cmd", "Machine")

# Agregar Claude al PATH del usuario
$old = [System.Environment]::GetEnvironmentVariable("PATH","User")
[System.Environment]::SetEnvironmentVariable("PATH", $old + ";C:\Users\Administrator\.local\bin", "User")

# Refrescar PATH en la sesión actual
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
[System.Environment]::GetEnvironmentVariable("PATH","User")

# Verificar que funcionan
git --version
claude --version
```

### OpenCode


- MacOSX

```sh
brew install opencode
opencode
```

- Linux/MacOSX/Windows

```sh
curl -fsSL https://opencode.ai/install | bash
```

### Gemini

```sh
# Global
npm install -g @google/gemini-cli # gemini

# MacOSX
brew install gemini-cli # gemini
```

### Codex

https://developers.openai.com/codex/cli

```sh
# Windows
powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 | iex"

# Linux 
curl -fsSL https://chatgpt.com/codex/install.sh | sh
# npm install -g @openai/codex

# WSL Ubuntu
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
source ~/.bashrc
nvm install 22
nvm use 22
nvm alias default 22
npm install -g @openai/codex@latest


sudo apt update
sudo apt install -y bubblewrap ca-certificates
curl -fsSL https://chatgpt.com/codex/install.sh | sh
# Reiniciar el terminal
codex login --device-auth


# MacOSx Brew
brew install --cask codex

codex
```

[See Tokens](https://platform.openai.com/api-keys) | [Codex Cloud](https://chatgpt.com/codex/cloud) | [Models Pricing](https://openai.com/es-ES/api/pricing/)


### Install agents (gentle-ai agents and settings) See: https://github.com/Gentleman-Programming/gentle-ai

#### Windows CMD

```sh
winget install --id GoLang.Go --exact
go install github.com/gentleman-programming/gentle-ai/v2/cmd/gentle-ai@latest
``` 

#### Linux / MacOSx

```sh
curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash
```

- Upgrade

```sh
brew trust --formula gentleman-programming/tap/gentle-ai
brew upgrade gentle-ai
brew upgrade engram
gentle-ai sync

engram setup opencode
engram setup claude-code
engram setup codex
```

---

### iOS/Android App — Local Model Testing

- **Google AI Edge Gallery** — run Google's local models (e.g. Gemma 4) directly on mobile.

---

### AI Stack (SDD)

- [AI Gentle Stack](https://github.com/Gentleman-Programming/gentle-ai)

```sh
curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash
```

---

### Token-Saving Mode


#### [Headroom: The context compression layer for AI agents](https://github.com/chopratejas/headroom)

Para usarlo con Claude Code:

```sh
# 1 — Install
pip install "headroom-ai[all]"          # Python
npm install headroom-ai                 # Node / TypeScript

# 2 — Pick your mode
headroom wrap claude                    # wrap a coding agent
headroom proxy --port 8787              # drop-in proxy, zero code changes
# or: from headroom import compress      # inline library

# 3 — See the savings
headroom perfroom perf

# 4 - mines field sessions, writes corrections to CLAUDE.md / AGENTS.md

headromm learn
```

#### [Caveman: why use many tokens when few do trick](https://github.com/patchamama/caveman)

```sh
claude plugin marketplace add JuliusBrussee/caveman && claude plugin install caveman@caveman
```

**Trigger with:**

```text
/caveman  or  Codex $caveman
"talk like caveman"
"caveman mode"
"less tokens please"
```

**Stop with:** `"stop caveman"` or `"normal mode"`

### tmux multilínea

```sh
sudo apt install tmux
set -g mouse on
set -g history-limit 50000
tmux source-file ~/.tmux.conf
tmux

tmux new-session -d -s claude 'claude remote-control'
tmux kill-session -t claude

>  Ctrl+b c     nueva pestaña
>  Ctrl+b %     dividir vertical
>  Ctrl+b "     dividir horizontal
>    Ctrl+b  ← |  Ctrl+b  → | Ctrl+b  ↑ |  Ctrl+b  ↓
>    Ctrl+b q (Ctrl+b #)
>  Ctrl+b n     siguiente pestaña
>  Ctrl+b d     desconectar sesión
>  Ctrl+b [     Modo scroll/copy ("q" sale del modo scroll)
>  Ctrl+b d     Salir en modo detached (persistente), manteniéndose la sesión abierta
>  tmux attach  volver a conectarte

# listar sesiones
tmux ls
# tmux attach -t <sesion-name>
```

### Configuración de `tmux`

```bash
cat > ~/.tmux.conf << 'EOF'
# Increase scrollback buffer (default is 2000 lines)
set -g history-limit 50000

# Enable mouse support for scrolling and pane selection
set -g mouse on

# Start window numbering at 1
set -g base-index 1

# Reduce escape time for faster key response
set -sg escape-time 10

# Status bar with session name and time
set -g status-right '%H:%M %d-%b'

# Keep sessions alive if the shell exits unexpectedly
set -g remain-on-exit on
EOF
```

---

### Agent Assistants

- [Portable AI agent skills. One CLI. Every coding assistant.](https://www.npmjs.com/package/@skilly-hand/skilly-hand)

| Command                     | Description                                              |
|-----------------------------|----------------------------------------------------------|
| `npx skilly-hand install`   | Install skills into the current project                  |
| `npx skilly-hand detect`    | Auto-detect project stack and suggest skills             |
| `npx skilly-hand list`      | List all available skills in the catalog                 |
| `npx skilly-hand doctor`    | Diagnose installation and configuration issues           |
| `npx skilly-hand uninstall` | Remove installed skills                                  |

---

### Markdown for Agents

https://markdown.new/

---

### Semantic Search for Documents

- [mgrep: A calm, CLI-native way to semantically grep everything — code, images, PDFs and more.](https://github.com/mixedbread-ai/mgrep)


### Prompting Guide

<details>
  <summary>Prompting Guide</summary>

Definition: A prompt is an instruction given by a person to a language model or computer program to generate a specific response, answer, or action.

What makes a prompt successful?


1. Clarity and precision

A good prompt should be clearly worded.

- Vague: "Analyze the document."
- More precise: "Analyze the document for contractual risks and summarize them."

2. Context

- The more context a prompt provides, the better the AI can respond. Specify what type of document it is, the expected structure, and what your objective is.
- "The document is a delivery note in PDF format. Check the document for the vendor number, delivery date, and recipient's address."

3. Roles and perspectives

- AI can be assigned specific roles to control the tone or depth of the response.
- "You are a DMS expert. Explain to a new user how to archive a document in line with legal requirements."

4. Format specifications

- Specify the format in which you expect the response.
- "Summarize the document's metadata in a table with the following columns: Field name, Value, and Source."

5. Iteration

A prompt can be improved iteratively or through repetition.

6. Prompt formula

[Role] + [Task] + [Context] + [Objective] + [Format] + [Tone]

Example:

- Role: You are an experienced data analyst.
- Task: Analyze the following sales figures and identify the trends.
- Objective: Identify patterns and provide well-supported conclusions to inform management decisions.

Format:

- Numbered list of analysis steps
- Final summary (max. 5 sentences)

Quality criteria:

- Only data-based statements
- Clear distinction between observation and interpretation
- Concise and precise wording

Limitations:

- No assumptions without a data basis
- No speculation about external factors
</details>

### Docker Ollama with SSL Support (Reverse SSL Proxy)

<details>
  <summary>Automatic Installation Script — HyperV Windows Server VM (2022/2025) + WSL + Docker</summary>

- [Script that automates the full installation interactively](./deploy-ollama-docker.ps1)

> [!NOTE]
> To allow PowerShell script execution, run this command first:
> ```ps
> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
> ```
</details>

<details>
  <summary>Manual Installation — HyperV Windows Server VM (2022/2025) + WSL + Docker</summary>

#### HyperV Windows Server VM (2022/2025) + WSL + Docker

**Problem:** Docker cannot be installed without `Nested Virtualization` enabled.

```ps
# Shut down the VM completely from the Host
Stop-VM "VM_Name"

# Run on the Host — enable nested virtualization
Set-VMProcessor -VMName "VM_Name" -ExposeVirtualizationExtensions $true

# Start VM completely from the Host
Start-VM "VM_Name"

# Restart the VM, then enable the required features inside the VM Powershell:
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Stop-VM "VM_Name"
Start-VM "VM_Name"
dism /online /enable-feature /featurename:VirtualMachinePlatform /all
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all

# Download and install WSL2 Kernel update:  https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
wsl --update
wsl --set-default-version 2
```

#### Install and Configure Docker ([Docker Desktop Windows Download](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe))

Once Docker Desktop is installed and running, it will:

- Create the `docker-desktop` WSL distro
- Create the `docker-desktop-data` WSL distro
- Use WSL2 internally

Verify with:

```ps
wsl -l -v
```

Expected output:

```text
NAME                   STATE           VERSION
docker-desktop         Running         2
```

Final test:

```ps
docker run hello-world
```

If it works:

- Docker OK
- WSL2 OK
- Ready for Ollama

---

#### Deploy Ollama with Docker

```ps
mkdir C:\ollama-ssl
cd C:\ollama-ssl
```

#### Create `docker-compose.yml`

```ps
notepad docker-compose.yml
```

Paste:

```yaml
services:
  ollama:
    image: ollama/ollama
    container_name: ollama
    restart: always
    volumes:
      - ollama_data:/root/.ollama

  caddy:
    image: caddy:latest
    container_name: caddy
    restart: always
    ports:
      - "11443:11434"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
    depends_on:
      - ollama

volumes:
  ollama_data:
  caddy_data:
```

#### Create `Caddyfile`

```ps
notepad Caddyfile
```

> [!NOTE]
> Make sure the file is named `Caddyfile` with no extension — Notepad often adds `.txt` by default.
> Verify with `dir c:\ollama-ssl`. If only `Caddyfile.txt` exists, rename it: `rename Caddyfile.txt Caddyfile`

Paste:

```text
{
    admin off
}

https://127.0.0.1:11434, https://localhost:11434 {
    reverse_proxy ollama:11434
    tls internal
}
```

Or use PowerShell to avoid UTF-8 encoding issues:

```ps
@"
{
    admin off
}

https://127.0.0.1:11434, https://localhost:11434 {
    reverse_proxy ollama:11434
    tls internal
}
"@ | Out-File -Encoding utf8 Caddyfile
```

#### Start Containers and Verify

```ps
# Start containers
docker compose down
docker compose up -d

# Verify running containers
docker ps

# Pull a lightweight model
docker exec -it ollama ollama pull deepseek-r1:1.5b

# Export and install the SSL certificate (required for HTTPS clients)
docker exec caddy cat /data/caddy/pki/authorities/local/root.crt > root.crt
certutil -addstore -f "ROOT" root.crt

# Quick test — should return JSON with HTTP 200
curl https://localhost/api/tags
```

Final configuration for your AI client:

```text
Provider:    Ollama
API Key:     ollama
Model Name:  deepseek-r1:1.5b
API Endpoint: https://localhost
```

---

#### Troubleshooting

**Client cannot connect:**

Try replacing `localhost` with `127.0.0.1` and update `Caddyfile`:

```text
https://127.0.0.1 {
    reverse_proxy ollama:11434
    tls internal
}
```

**Optional next steps:**

- Share the Host GPU with the VM
- Install `llama3:8b`
- Expose Ollama Docker on the local network

#### References

- https://learn.microsoft.com/en-us/windows/wsl/install-manual#step-4---download-the-linux-kernel-update-package

</details>


### TODO

- Docker + SSL con llamaCPP optimizado para versión de linux con soporte de GPU Nvidia y otros.
- See model OpenAI Privacy Filter to remove Privacy data before process (It is opensource)

## References

-  [Programar con IA sin Gastar una Fortuna: Minimax M2.7 + OpenCode](https://www.youtube.com/watch?v=Pwp_F8zQbMM)
-  [Qwen3-Coder-Next: The Complete 2026 Guide to Running Powerful AI Coding Agents Locally](https://dev.to/sienna/qwen3-coder-next-the-complete-2026-guide-to-running-powerful-ai-coding-agents-locally-1k95)
-  [Ollama is now powered by MLX on Apple Silicon in preview](https://ollama.com/blog/mlx)   
