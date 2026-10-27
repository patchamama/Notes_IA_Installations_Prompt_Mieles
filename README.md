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

### Install PI

- Fuente: https://pi.dev/docs/latest/quickstart

```sh
curl -fsSL https://pi.dev/install.sh | sh
# npm install -g --ignore-scripts @earendil-works/pi-coding-agent
pi --version
```

### Claude Code

```sh
# Linux & MacOSX
curl -fsSL https://claude.ai/install.sh | bash

# Windows CMD

curl.exe -fsSL https://claude.ai/install.cmd -o install.cmd 
./install.cmd 
del install.cmd
$env:Path += ";$env:USERPROFILE\.local\bin"
%USERPROFILE%\.local\bin\claude.exe
# O claude.exe

# Agregar codex y claude al path
[Environment]::SetEnvironmentVariable('Path', ([Environment]::GetEnvironmentVariable('Path','User') + ';' +
  $env:USERPROFILE + '\.local\bin;' + $env:USERPROFILE + '\AppData\Local\Programs\OpenAI\Codex\bin'), 'User')

# Windows PS
winget install --id Git.Git -e --source winget
# ó
$ProgressPreference = 'SilentlyContinue'
$rel = Invoke-RestMethod https://api.github.com/repos/git-for-windows/git/releases/latest
$a   = $rel.assets | Where-Object name -match '^Git-.*-64-bit\.exe$' | Select-Object -First 1
$out = Join-Path $env:TEMP $a.name
Invoke-WebRequest $a.browser_download_url -OutFile $out
# Verificar firma (debe decir Valid)
(Get-AuthenticodeSignature $out).Status
Start-Process $out -Wait -ArgumentList '/VERYSILENT','/NORESTART','/NOCANCEL','/SP-','/ALLUSERS'

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

##### Agregar status en la barra de estado 

Para activarlo hay que añadir esto en ~/.claude/settings.json, justo antes de "outputStyle". Esa edición me la bloqueó el clasificador, así que tienes que pegarla tú:

<details>
  <summary>Activar status line</summary>

```json
"statusLine": {
  "type": "command",
  "command": "powershell -NoProfile -ExecutionPolicy Bypass -File C:/Users/eloadmin/.claude/statusline.ps1"
},
```

statusline.ps1

```ps1
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$raw = [Console]::In.ReadToEnd()
$j = $raw | ConvertFrom-Json

# ---- colours (ANSI) -------------------------------------------------------------------------------
$e = [char]27
$RESET = "$e[0m"
function C($code, $text) { return "$e[${code}m$text$RESET" }
$DIM = '2'; $BOLD = '1'
$GREEN = '38;5;78'; $YELLOW = '38;5;220'; $ORANGE = '38;5;208'; $RED = '38;5;203'
$CYAN = '38;5;81'; $BLUE = '38;5;75'; $MAGENTA = '38;5;176'; $GRAY = '38;5;244'
$FULL = [string][char]0x2588; $EMPTY = [string][char]0x2591; $SEP = " $(C $GRAY ([string][char]0x2502)) "

# Green below 50%, yellow below 75%, orange below 90%, red from there.
function LevelColor([double]$pct) {
  if ($pct -ge 90) { return $RED }
  if ($pct -ge 75) { return $ORANGE }
  if ($pct -ge 50) { return $YELLOW }
  return $GREEN
}

function Bar([double]$pct, [int]$width = 8) {
  $pct = [math]::Max(0, [math]::Min(100, $pct))
  $filled = [int][math]::Round($pct / 100 * $width)
  $color = LevelColor $pct
  return (C $color ($FULL * $filled)) + (C $GRAY ($EMPTY * ($width - $filled)))
}

function Meter($label, [double]$pct, $suffix = '') {
  $color = LevelColor $pct
  $text = "$(C $GRAY $label) $(Bar $pct) $(C $BOLD (C $color ('{0}%' -f [int]$pct)))"
  if ($suffix) { $text += ' ' + (C $GRAY $suffix) }
  return $text
}

function Remaining($epoch) {
  if (-not $epoch) { return '?' }
  $span = [DateTimeOffset]::FromUnixTimeSeconds([int64]$epoch) - [DateTimeOffset]::UtcNow
  if ($span.TotalSeconds -le 0) { return 'now' }
  if ($span.TotalHours -ge 24) { return ('{0}d{1}h' -f [int]$span.Days, $span.Hours) }
  if ($span.TotalHours -ge 1) { return ('{0}h{1:00}m' -f [int]$span.TotalHours, $span.Minutes) }
  return ('{0}m' -f [int][math]::Ceiling($span.TotalMinutes))
}

# ---- background tasks ----------------------------------------------------------------------------
# The status line input does not list them, so they are read from the tail of the session
# transcript: launches versus completion notifications.
function BackgroundTasks($path) {
  if (-not $path -or -not (Test-Path -LiteralPath $path)) { return $null }
  $fs = [System.IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
  try {
    $window = 800KB
    if ($fs.Length -gt $window) { $fs.Seek(-$window, 'End') | Out-Null }
    $text = (New-Object System.IO.StreamReader($fs, [Text.Encoding]::UTF8)).ReadToEnd()
  } finally { $fs.Dispose() }

  $started = [ordered]@{}
  foreach ($m in [regex]::Matches($text, 'running in background with ID: ([A-Za-z0-9_-]+)|agentId: ([A-Za-z0-9_-]+)')) {
    $id = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
    $started[$id] = $true
  }
  $done = @{}
  $last = $null
  foreach ($m in [regex]::Matches($text, 'task-id>([A-Za-z0-9_-]+)</task-id>.{0,600}?<status>(\w+)</status>(?:.{0,400}?<summary>(.*?)</summary>)?')) {
    $done[$m.Groups[1].Value] = $m.Groups[2].Value
    $last = @{ status = $m.Groups[2].Value; summary = $m.Groups[3].Value }
  }
  $running = @($started.Keys | Where-Object { -not $done.ContainsKey($_) }).Count

  $parts = @()
  if ($running -gt 0) { $parts += (C $MAGENTA ("bg {0} running" -f $running)) }
  if ($last) {
    $kind = if ($last.summary -match 'pytest|\btests?\b') { 'tests' } else { 'task' }
    $exit = if ($last.summary -match 'exit code (\d+)') { ' (exit ' + $Matches[1] + ')' } else { '' }
    $ok = $last.status -eq 'completed'
    $parts += (C ($(if ($ok) { $GREEN } else { $RED })) ("last {0}: {1}{2}" -f $kind, $(if ($ok) { 'OK' } else { $last.status.ToUpper() }), $exit))
  }
  if ($parts.Count -eq 0) { return $null }
  return ($parts -join (C $GRAY ', '))
}

# ---- pytest suite progress -----------------------------------------------------------------------
# The newest recently-written log in this session's scratchpad / background-task folders
# (cheap: two folders, recent files only).
function SuiteProgress($sessionId) {
  if (-not $sessionId) { return $null }
  $root = Join-Path $env:TEMP 'claude'
  if (-not (Test-Path $root)) { return $null }
  $cutoff = (Get-Date).AddMinutes(-30)
  $file = Get-ChildItem -Path (Join-Path $root "*\$sessionId\scratchpad\*.log"), (Join-Path $root "*\$sessionId\tasks\*.output") -File |
    Where-Object { $_.LastWriteTime -gt $cutoff } | Sort-Object LastWriteTime -Descending |
    Where-Object {
      $fs = [System.IO.File]::Open($_.FullName, 'Open', 'Read', 'ReadWrite')
      try { if ($fs.Length -gt 16384) { $fs.Seek(-16384, 'End') | Out-Null }
            $script:suiteTail = (New-Object System.IO.StreamReader($fs)).ReadToEnd() } finally { $fs.Dispose() }
      $script:suiteTail -match '(?m)^[\.FEsxX]{10,}' -or $script:suiteTail -match '\d+ (passed|failed|error)[^\r\n]* in [\d\.]+s'
    } | Select-Object -First 1
  if (-not $file) { return $null }
  $tail = $script:suiteTail
  if ($tail -match '(\d+) (passed|failed|error)[^\r\n]* in [\d\.]+s') {
    $failed = $tail -match '\d+ (failed|error)'
    $time = $Matches[0].Split(' in ')[-1]
    return (C ($(if ($failed) { $RED } else { $GREEN })) ("suite {0} {1}" -f $(if ($failed) { 'FAIL' } else { 'PASS' }), $time))
  }
  $percent = $null
  foreach ($m in [regex]::Matches($tail, '\[\s*(\d+)%\]')) { $percent = [int]$m.Groups[1].Value }
  if ($null -eq $percent) { return $null }
  $bad = 0
  foreach ($line in ($tail -split "`r?`n" | Where-Object { $_ -match '^[\.FEsxX]+(\s+\[\s*\d+%\])?\s*$' })) { $bad += ([regex]::Matches($line, '[FE]')).Count }
  $stale = ((Get-Date) - $file.LastWriteTime).TotalSeconds -gt 120
  # A suite's own progress is not a warning level: blue while healthy, red as soon as a test failed.
  $barColor = if ($bad) { $RED } elseif ($stale) { $ORANGE } else { $BLUE }
  $filled = [int][math]::Round($percent / 100 * 8)
  $bar = (C $barColor ($FULL * $filled)) + (C $GRAY ($EMPTY * (8 - $filled)))
  $text = "$(C $GRAY 'suite') $bar $(C $BOLD (C $barColor ('{0}%' -f $percent)))"
  if ($bad) { $text += ' ' + (C $RED ("{0}F" -f $bad)) }
  if ($stale) { $text += ' ' + (C $ORANGE 'stalled?') }
  return $text
}

# ---- assemble ------------------------------------------------------------------------------------
$parts = @()
if ($j.model.display_name) { $parts += (C $BOLD (C $CYAN $j.model.display_name)) }
if ($j.workspace.current_dir) { $parts += (C $BLUE (Split-Path -Leaf $j.workspace.current_dir)) }

$cw = $j.context_window
if ($cw -and $null -ne $cw.used_percentage) {
  $size = [int]$cw.context_window_size
  $used = [int]([double]$cw.used_percentage / 100 * $size)
  $parts += (Meter 'ctx' ([double]$cw.used_percentage) ('{0}k/{1}k' -f [int]($used / 1000), [int]($size / 1000)))
}

$rl = $j.rate_limits
if ($rl) {
  if ($rl.five_hour) { $parts += (Meter '5h' ([double]$rl.five_hour.used_percentage) ('resets ' + (Remaining $rl.five_hour.resets_at))) }
  if ($rl.seven_day) { $parts += (Meter '7d' ([double]$rl.seven_day.used_percentage) ('resets ' + (Remaining $rl.seven_day.resets_at))) }
}

$suite = SuiteProgress $j.session_id
if ($suite) { $parts += $suite }

$bg = BackgroundTasks $j.transcript_path
if ($bg) { $parts += $bg }

[Console]::Out.Write(($parts -join $SEP))

```
</details>


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
.\AppData\Local\Programs\OpenAI\Codex\bin\codex.exe

# Agregar codex y claude al path
[Environment]::SetEnvironmentVariable('Path', ([Environment]::GetEnvironmentVariable('Path','User') + ';' +
  $env:USERPROFILE + '\.local\bin;' + $env:USERPROFILE + '\AppData\Local\Programs\OpenAI\Codex\bin'), 'User')

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

# Codex sin preguntar tanto
codex --sandbox workspace-write --ask-for-approval never --no-daemon
```

#### Instrucciones para que no pregunte tanto

> Work autonomously until the task is complete.
> Do not ask me for confirmation between steps.
> Make reasonable implementation decisions yourself.
> Run the relevant tests and fix errors you encounter.
> Only stop if you are genuinely blocked or need information
> that cannot be inferred from the project.

[See Tokens](https://platform.openai.com/api-keys) | [Codex Cloud](https://chatgpt.com/codex/cloud) | [Models Pricing](https://openai.com/es-ES/api/pricing/)


### Install winget

```sh
$url = 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
$file = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
Invoke-WebRequest $url -OutFile $file
Add-AppxPackage -Path $file
winget --version
```

### Install agents (gentle-ai agents and settings) See: https://github.com/Gentleman-Programming/gentle-ai

#### Windows CMD

```sh
winget install --id GoLang.Go --exact
# o
$ProgressPreference = 'SilentlyContinue'
$r   = Invoke-RestMethod 'https://go.dev/dl/?mode=json'
$f   = $r[0].files | Where-Object { $_.os -eq 'windows' -and $_.arch -eq 'amd64' -and $_.kind -eq 'installer' }
$out = Join-Path $env:TEMP $f.filename
Invoke-WebRequest "https://go.dev/dl/$($f.filename)" -OutFile $out
# Verificar checksum (debe dar True)
(Get-FileHash $out -Algorithm SHA256).Hash -eq $f.sha256
Start-Process msiexec.exe -Wait -ArgumentLisestart'

set PATH "%PATH%;C:\Program Files\Go\bin;C:\Users\Administrator\go\bin"
go version
go install github.com/gentleman-programming/gentle-ai/v3/cmd/gentle-ai@latest

# O
& "C:\Users\Administrator\go\bin\gentle-ai.exe" 
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
