#!/usr/bin/env bash
# start-ollama.sh — Start Ollama with optimized settings for speak-mentor
#
# Supported platforms: macOS (Intel + Apple Silicon), Linux native, WSL2
#
# Performance flags used:
#   OLLAMA_KEEP_ALIVE=-1          Model stays in VRAM indefinitely (no reloads between pipeline passes)
#   OLLAMA_KV_CACHE_TYPE=q8_0    50% less VRAM with minimal quality loss (requires Flash Attention)
#   OLLAMA_FLASH_ATTENTION=1     Enable Flash Attention (Apple Silicon, NVIDIA Pascal+, AMD ROCm)
#   OLLAMA_NUM_PARALLEL=2        Allow 2 concurrent requests to the same model
#   OLLAMA_MAX_LOADED_MODELS=3   Keep up to 3 models in VRAM simultaneously (high-VRAM only)
#
# Key findings from benchmarks (translategemma:12b, M1 Max):
#   - Decode speed is hardware-bound (~25 t/s) and doesn't change across env var combinations
#   - The biggest lever is num_ctx in the request: ctx=2048 → 163 t/s prefill vs 74 t/s at ctx=4096
#   - OLLAMA_MAX_LOADED_MODELS improves multi-model pipelines (no reloads between passes)
#   - Upgrading Ollama to 0.19+ (MLX backend) gives +93% decode on Apple Silicon over Metal
#   - WSL2: VRAM is shared with Windows; tune NUM_PARALLEL by actual VRAM, not total GPU spec

set -euo pipefail

OLLAMA_PORT=${1:-11434}

# ── helpers ───────────────────────────────────────────────────────────────────
port_in_use() {
  # Use a real TCP connect — the only method that works across the WSL2/Windows boundary.
  # lsof and ss only see WSL2-namespace processes; a Windows process holding the port is invisible to them.
  (echo >/dev/tcp/127.0.0.1/"$1") &>/dev/null 2>&1
}

find_free_port() {
  local p=$1
  while port_in_use "$p"; do (( p++ )); done
  echo "$p"
}

# Find nvidia-smi regardless of PATH (WSL2 exposes it at a fixed path)
nvidia_smi() {
  if command -v nvidia-smi &>/dev/null; then
    nvidia-smi "$@"
  elif [ -x /usr/lib/wsl/lib/nvidia-smi ]; then
    /usr/lib/wsl/lib/nvidia-smi "$@"
  else
    return 1
  fi
}

# RAM in GB from /proc/meminfo (Linux + WSL2)
linux_ram_gb() { awk '/MemTotal/ {printf "%d", $2/1048576}' /proc/meminfo; }

# NVIDIA VRAM in GB
nvidia_vram_gb() {
  local mb
  mb=$(nvidia_smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d '[:space:]')
  [[ "$mb" =~ ^[0-9]+$ ]] && printf "%d" $(( mb / 1024 )) || echo "0"
}

# Tune NUM_PARALLEL + MAX_LOADED by VRAM (NVIDIA) or RAM (AMD/Apple — unified memory)
tune_by_vram() {
  local gb=$1
  if   [[ "$gb" -ge 24 ]]; then NUM_PARALLEL=2; MAX_LOADED=3; echo "≥24GB: MAX_LOADED=3, NUM_PARALLEL=2"
  elif [[ "$gb" -ge 16 ]]; then NUM_PARALLEL=2; MAX_LOADED=2; echo "≥16GB: MAX_LOADED=2, NUM_PARALLEL=2"
  else                          NUM_PARALLEL=1; MAX_LOADED=1; echo "<16GB: MAX_LOADED=1, NUM_PARALLEL=1 (memory-constrained)"
  fi
}

# ── 1. Stop any running Ollama instance ───────────────────────────────────────
echo "Stopping existing Ollama instance..."

pkill -f "ollama serve" 2>/dev/null || true
pkill -f "ollama runner" 2>/dev/null || true

# On macOS, Ollama also runs as a menu-bar app (Ollama.app) — kill it too
if [[ "$(uname)" == "Darwin" ]]; then
  osascript -e 'quit app "Ollama"' 2>/dev/null || true
  pkill -x "Ollama" 2>/dev/null || true
fi

# On WSL2, Ollama may be running as a Windows process (installed via Windows installer).
# pkill only kills WSL2-namespace processes; the Windows process must be stopped via PowerShell.
if grep -qi microsoft /proc/version 2>/dev/null; then
  powershell.exe -Command "Stop-Process -Name 'ollama' -Force -ErrorAction SilentlyContinue" 2>/dev/null || true
fi

# Wait up to 5 s for our own processes to release the port
for i in $(seq 1 5); do
  port_in_use "${OLLAMA_PORT}" || break
  sleep 1
done

# If another process still holds the port, find the next free one
if port_in_use "${OLLAMA_PORT}"; then
  echo "Error: listen tcp 0.0.0.0:${OLLAMA_PORT}: bind: address already in use"
  OLLAMA_PORT=$(find_free_port $(( OLLAMA_PORT + 1 )))
  echo "Switching to port ${OLLAMA_PORT}"
fi

# ── 2. Detect platform + hardware, set optimal flags ─────────────────────────
USE_FLASH=1
KV_CACHE=q8_0
NUM_PARALLEL=2
MAX_LOADED=2

# Detect platform
PLATFORM="linux"
if [[ "$(uname)" == "Darwin" ]]; then
  PLATFORM="macos"
elif grep -qi microsoft /proc/version 2>/dev/null; then
  PLATFORM="wsl2"
fi

if [[ "$PLATFORM" == "macos" ]]; then
  # ── macOS ──────────────────────────────────────────────────────────────────
  if [[ "$(uname -m)" != "arm64" ]]; then
    echo "Intel Mac detected — disabling Flash Attention and KV cache quantization"
    USE_FLASH=0; KV_CACHE=f16; NUM_PARALLEL=1; MAX_LOADED=1
  else
    RAM_GB=$(sysctl hw.memsize 2>/dev/null | awk '{printf "%d", $2/1073741824}')
    CHIP=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | awk -F': ' '{print $2}' | head -1)
    echo "Apple Silicon detected (${CHIP}, ${RAM_GB}GB) — enabling Flash Attention + KV cache q8_0"
    # Apple Silicon uses unified memory — tune by RAM (same pool for CPU+GPU)
    tune_by_vram "${RAM_GB}"
  fi

elif [[ "$PLATFORM" == "wsl2" ]]; then
  # ── WSL2 ───────────────────────────────────────────────────────────────────
  # AMD ROCm is not supported under WSL2; only NVIDIA via CUDA/DirectML

  # Point to Windows Ollama models so the Linux Ollama instance sees the same models
  WIN_USER=$(powershell.exe -NoProfile -Command '[Environment]::UserName' 2>/dev/null | tr -d '\r\n')
  WIN_MODELS="/mnt/c/Users/${WIN_USER}/.ollama/models"
  if [ -d "$WIN_MODELS" ]; then
    OLLAMA_MODELS="$WIN_MODELS"
    echo "Using Windows Ollama models at ${OLLAMA_MODELS}"
  fi

  RAM_GB=$(linux_ram_gb)
  if nvidia_smi &>/dev/null; then
    VRAM_GB=$(nvidia_vram_gb)
    GPU_NAME=$(nvidia_smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 | xargs)
    echo "WSL2 + NVIDIA detected (${GPU_NAME}, ${VRAM_GB}GB VRAM, ${RAM_GB}GB RAM) — enabling Flash Attention + KV cache q8_0"
    # VRAM is shared with Windows host — tune conservatively by actual VRAM
    tune_by_vram "${VRAM_GB}"
  else
    echo "WSL2 detected, no NVIDIA GPU found (CPU only, ${RAM_GB}GB RAM) — disabling Flash Attention and KV cache quantization"
    USE_FLASH=0; KV_CACHE=f16; NUM_PARALLEL=1; MAX_LOADED=1
  fi

else
  # ── Native Linux ────────────────────────────────────────────────────────────
  RAM_GB=$(linux_ram_gb)
  if nvidia_smi &>/dev/null; then
    VRAM_GB=$(nvidia_vram_gb)
    GPU_NAME=$(nvidia_smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 | xargs)
    echo "NVIDIA GPU detected (${GPU_NAME}, ${VRAM_GB}GB VRAM, ${RAM_GB}GB RAM) — enabling Flash Attention + KV cache q8_0"
    tune_by_vram "${VRAM_GB}"
  elif command -v rocm-smi &>/dev/null || [ -e /dev/kfd ]; then
    GPU_NAME=$(rocm-smi --showproductname 2>/dev/null | awk -F': ' '/GPU/{print $2; exit}' || echo "AMD GPU")
    echo "AMD ROCm detected (${GPU_NAME}, ${RAM_GB}GB RAM) — enabling Flash Attention + KV cache q8_0"
    # ROCm uses system RAM as VRAM (unified) — tune by RAM
    tune_by_vram "${RAM_GB}"
  else
    echo "No GPU detected (CPU only, ${RAM_GB}GB RAM) — disabling Flash Attention and KV cache quantization"
    USE_FLASH=0; KV_CACHE=f16; NUM_PARALLEL=1; MAX_LOADED=1
  fi
fi

# ── 3. Resolve network-accessible IP ─────────────────────────────────────────
if [[ "$PLATFORM" == "wsl2" ]]; then
  # On WSL2, the IP other machines see is the Windows host IP, not the WSL2 IP.
  NETWORK_IP=$(powershell.exe -NoProfile -Command \
    "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { \$_.IPAddress -notmatch '^(127\.|169\.254\.)' -and \$_.PrefixOrigin -ne 'WellKnown' } | Sort-Object -Property InterfaceMetric | Select-Object -First 1).IPAddress" \
    2>/dev/null | tr -d '\r\n')
elif [[ "$PLATFORM" == "macos" ]]; then
  NETWORK_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")
else
  NETWORK_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '/src/{print $7; exit}' || hostname -I 2>/dev/null | awk '{print $1}')
fi

# ── 4. Start Ollama ───────────────────────────────────────────────────────────
echo ""
echo "Starting Ollama..."
echo "  OLLAMA_HOST             = 0.0.0.0:${OLLAMA_PORT}"
echo "  OLLAMA_ORIGINS          = *"
echo "  OLLAMA_KEEP_ALIVE       = -1 (indefinite)"
echo "  OLLAMA_NUM_PARALLEL     = ${NUM_PARALLEL}"
echo "  OLLAMA_MAX_LOADED_MODELS= ${MAX_LOADED}"
echo "  OLLAMA_FLASH_ATTN       = ${USE_FLASH}"
echo "  OLLAMA_KV_CACHE         = ${KV_CACHE}"
[[ -n "${OLLAMA_MODELS:-}" ]] && echo "  OLLAMA_MODELS           = ${OLLAMA_MODELS}"
echo ""
echo "Tip: keep num_ctx ≤ 4096 in requests — smaller context = faster prefill."
echo "     ctx=2048 → ~2x faster prefill vs ctx=4096 with no quality loss for short texts."
echo ""
if [[ -n "${NETWORK_IP:-}" ]]; then
  echo "  Network access:"
  echo "    http://${NETWORK_IP}:${OLLAMA_PORT}       (other machines on the same network)"
  echo "    http://localhost:${OLLAMA_PORT}            (this machine only)"
  echo ""
fi

# Final port check — catches the race between our check and ollama's bind
if port_in_use "${OLLAMA_PORT}"; then
  OLLAMA_PORT=$(find_free_port $(( OLLAMA_PORT + 1 )))
  echo "Port still in use — switching to ${OLLAMA_PORT} before launch"
  echo "  OLLAMA_HOST             = 0.0.0.0:${OLLAMA_PORT} (updated)"
fi

export OLLAMA_HOST=0.0.0.0:${OLLAMA_PORT}
export OLLAMA_ORIGINS="*"
export OLLAMA_KEEP_ALIVE=-1
export OLLAMA_NUM_PARALLEL=${NUM_PARALLEL}
export OLLAMA_MAX_LOADED_MODELS=${MAX_LOADED}
export OLLAMA_FLASH_ATTENTION=${USE_FLASH}
export OLLAMA_KV_CACHE_TYPE=${KV_CACHE}
[[ -n "${OLLAMA_MODELS:-}" ]] && export OLLAMA_MODELS

exec ollama serve
