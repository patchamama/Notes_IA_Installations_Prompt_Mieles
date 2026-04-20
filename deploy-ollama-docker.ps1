#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$StateFile = "C:\ollama-ssl\deploy-state.json"

# ── Available models catalogue ────────────────────────────────────────────────

$Catalogue = @(
    [PSCustomObject]@{ Tag = "deepseek-r1:1.5b"; Desc = "DeepSeek R1 1.5B  -- fast, lightweight" }
    [PSCustomObject]@{ Tag = "llama3.1:8b";      Desc = "Meta LLaMA 3.1 8B -- balanced quality" }
    [PSCustomObject]@{ Tag = "gemma4:latest";    Desc = "Google Gemma 4     -- latest release" }
    [PSCustomObject]@{ Tag = "gpt-oss";          Desc = "OpenAI OSS model" }
    [PSCustomObject]@{ Tag = "phi4:latest";      Desc = "Microsoft Phi-4    -- efficient reasoning" }
    [PSCustomObject]@{ Tag = "mistral:latest";   Desc = "Mistral 7B         -- strong multilingual" }
    [PSCustomObject]@{ Tag = "qwen2.5:7b";       Desc = "Alibaba Qwen 2.5 7B -- coding & reasoning" }
)

# ── Checkpoint / resume ───────────────────────────────────────────────────────

function Get-DeployState {
    if (Test-Path $StateFile) {
        $s = Get-Content $StateFile -Raw | ConvertFrom-Json
        if ($null -eq $s.Completed -or $s.Completed -isnot [array]) {
            $s | Add-Member -NotePropertyName Completed -NotePropertyValue @() -Force
        }
        if ($null -eq $s.Models -or $s.Models -isnot [array]) {
            $s | Add-Member -NotePropertyName Models -NotePropertyValue @() -Force
        }
        return $s
    }
    return [PSCustomObject]@{
        VMName    = ""
        Completed = [string[]]@()
        Models    = [string[]]@()
    }
}

function Save-State($state) {
    $state | ConvertTo-Json | Set-Content $StateFile -Encoding utf8
}

function Is-Done($state, $step)  { $state.Completed -contains $step }

function Mark-Done($state, $step) {
    if (-not (Is-Done $state $step)) { $state.Completed = @($state.Completed) + $step }
    Save-State $state
    Write-Host "[DONE] $step" -ForegroundColor Green
}

# ── VM connectivity ───────────────────────────────────────────────────────────

function Wait-VMReady {
    param($VMName, $Credential, [int]$TimeoutSec = 300)
    Write-Host "  Waiting for VM to respond" -NoNewline
    $until = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $until) {
        try {
            Invoke-Command -VMName $VMName -Credential $Credential `
                -ScriptBlock { 1 } -ErrorAction Stop | Out-Null
            Write-Host " ready." -ForegroundColor Green
            return
        } catch {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 5
        }
    }
    throw "VM '$VMName' did not respond within ${TimeoutSec}s"
}

function Invoke-InVM([scriptblock]$Script) {
    Invoke-Command -VMName $VMName -Credential $cred -ScriptBlock $Script
}

# ── Step validators ───────────────────────────────────────────────────────────

function Assert-WSL2 {
    $out = Invoke-InVM { wsl --list --verbose 2>&1 | Out-String }
    if ($out -notmatch "VERSION\s+2" -and $out -notmatch "\*.*2") {
        Write-Host "  Warning: could not confirm WSL2 (output: $out) -- continuing." -ForegroundColor Yellow
        return
    }
    Write-Host "  WSL2 confirmed." -ForegroundColor Green
}

function Assert-DockerReady {
    Write-Host "  Waiting for Docker daemon" -NoNewline
    Invoke-InVM {
        $until = (Get-Date).AddSeconds(180)
        while ((Get-Date) -lt $until) {
            docker info 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { return }
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 5
        }
        throw "Docker daemon not ready after 180s"
    }
    Write-Host " ready." -ForegroundColor Green
}

function Assert-OllamaAPI {
    Write-Host "  Validating Ollama API" -NoNewline
    $response = Invoke-InVM { curl -sk https://localhost/api/tags 2>&1 }
    if ($response -notmatch "models") { throw "Unexpected API response: $response" }
    Write-Host " OK" -ForegroundColor Green
}

# ── UI helpers ────────────────────────────────────────────────────────────────

function Write-Banner($text) {
    $line = "=" * ($text.Length + 6)
    Write-Host ""
    Write-Host "  $line" -ForegroundColor Cyan
    Write-Host "  =  $text  =" -ForegroundColor Cyan
    Write-Host "  $line" -ForegroundColor Cyan
    Write-Host ""
}

function Select-Models {
    Write-Host "  Available Ollama models:" -ForegroundColor Cyan
    Write-Host ""
    for ($i = 0; $i -lt $Catalogue.Count; $i++) {
        Write-Host ("  [{0}] {1,-22} {2}" -f $i, $Catalogue[$i].Tag, $Catalogue[$i].Desc)
    }
    Write-Host ("  [{0}] Custom                 Enter your own model tag" -f $Catalogue.Count)
    Write-Host ""
    Write-Host "  Enter numbers separated by spaces (e.g. 0 2 3): " -NoNewline -ForegroundColor Yellow
    $raw = (Read-Host).Trim() -split '\s+'

    $selected = @()
    foreach ($token in $raw) {
        $n = [int]$token
        if ($n -lt $Catalogue.Count) {
            $selected += $Catalogue[$n].Tag
        } elseif ($n -eq $Catalogue.Count) {
            $custom = (Read-Host "  Custom model tag (e.g. llama3:latest)").Trim()
            if ($custom) { $selected += $custom }
        }
    }

    if ($selected.Count -eq 0) {
        Write-Host "  No models selected -- defaulting to deepseek-r1:1.5b" -ForegroundColor Yellow
        $selected = @("deepseek-r1:1.5b")
    }

    Write-Host ""
    Write-Host "  Models queued for install:" -ForegroundColor Green
    $selected | ForEach-Object { Write-Host "    - $_" }
    return $selected
}

# =============================================================================
# STARTUP -- detect interrupted installation
# =============================================================================

Write-Banner "Ollama SSL Deploy Script"

$state = Get-DeployState

if ($state.Completed.Count -gt 0) {
    $lastStep  = $state.Completed[-1]
    $vmLabel   = if ($state.VMName) { $state.VMName } else { "(not set)" }
    $modLabels = if ($state.Models.Count -gt 0) { $state.Models -join ", " } else { "(not set)" }
    $modShort  = if ($modLabels.Length -gt 37) { $modLabels.Substring(0, 34) + "..." } else { $modLabels }

    Write-Host "  +----------------------------------------------------+" -ForegroundColor Yellow
    Write-Host "  |   INTERRUPTED INSTALLATION DETECTED                |" -ForegroundColor Yellow
    Write-Host "  |----------------------------------------------------|" -ForegroundColor Yellow
    Write-Host ("  |  VM       : {0,-37}|" -f $vmLabel)   -ForegroundColor Yellow
    Write-Host ("  |  Models   : {0,-37}|" -f $modShort)  -ForegroundColor Yellow
    Write-Host ("  |  Completed: {0,-37}|" -f "$($state.Completed.Count) step(s)") -ForegroundColor Yellow
    Write-Host ("  |  Last step: {0,-37}|" -f $lastStep)  -ForegroundColor Yellow
    Write-Host "  +----------------------------------------------------+" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [R] Resume from checkpoint" -ForegroundColor Cyan
    Write-Host "  [S] Start over from the beginning" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Choice [R/S] (default: R): " -NoNewline -ForegroundColor Yellow
    $answer = (Read-Host).Trim()

    if ($answer -match "^[Ss]") {
        Write-Host ""
        Write-Host "  Starting over -- previous state cleared." -ForegroundColor Magenta
        $state = [PSCustomObject]@{
            VMName    = ""
            Completed = [string[]]@()
            Models    = [string[]]@()
        }
        Save-State $state
    } else {
        Write-Host ""
        Write-Host "  Resuming installation..." -ForegroundColor Green
    }
}

# ── VM selection (skipped on resume if already saved) ────────────────────────

if (-not $state.VMName) {
    Write-Host ""
    $vms = Get-VM
    Write-Host "  Available Hyper-V VMs:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $vms.Count; $i++) {
        Write-Host ("  [{0}] {1} -- {2}" -f $i, $vms[$i].Name, $vms[$i].State)
    }
    Write-Host ""
    Write-Host "  Select VM number: " -NoNewline -ForegroundColor Yellow
    $choice       = Read-Host
    $state.VMName = $vms[[int]$choice].Name
    Save-State $state
}

$VMName = $state.VMName

# ── Model selection (skipped on resume if already saved) ─────────────────────

if ($state.Models.Count -eq 0) {
    Write-Host ""
    Write-Banner "Model Selection"
    Write-Host "  Select all models now -- no interruptions during deploy." -ForegroundColor Gray
    Write-Host ""
    $state.Models = [string[]]$(Select-Models)
    Save-State $state
} else {
    Write-Host "  Models from checkpoint: $($state.Models -join ', ')" -ForegroundColor Gray
}

# ── Credentials (always prompted -- not stored in state) ─────────────────────

$cred = Get-Credential -Message "Credentials for VM '$VMName'"
Write-Host ""
Write-Host "  Target VM : $VMName" -ForegroundColor Cyan
Write-Host "  Models    : $($state.Models -join ', ')" -ForegroundColor Cyan

# =============================================================================
# STEP 1 -- Nested Virtualization
# =============================================================================

if (-not (Is-Done $state "nested-virt")) {
    Write-Banner "STEP 1 -- Nested Virtualization"
    Stop-VM $VMName -Force -ErrorAction SilentlyContinue
    Set-VMProcessor -VMName $VMName -ExposeVirtualizationExtensions $true
    Start-VM $VMName
    Wait-VMReady $VMName $cred
    Mark-Done $state "nested-virt"
}

# =============================================================================
# STEP 2 -- Enable WSL features + reboot
# =============================================================================

if (-not (Is-Done $state "wsl-features")) {
    Write-Banner "STEP 2 -- Enabling WSL Features"
    Invoke-InVM {
        dism /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
        dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    }
    Mark-Done $state "wsl-features"
}

if (-not (Is-Done $state "wsl-reboot")) {
    Write-Host "  Rebooting VM to apply WSL features..."
    Restart-VM $VMName -Force
    Wait-VMReady $VMName $cred -TimeoutSec 300
    Mark-Done $state "wsl-reboot"
}

# =============================================================================
# STEP 3 -- Set WSL2 as default
# =============================================================================

if (-not (Is-Done $state "wsl-install")) {
    Write-Banner "STEP 3a -- Install WSL Application"
    Invoke-InVM {
        # DISM only enables Windows components; the WSL app must be installed separately
        Write-Host "  Running wsl --install --no-distribution..."
        $out = wsl --install --no-distribution 2>&1 | Out-String
        Write-Host $out
    }
    # Reboot so Windows finalises the WSL app installation before the kernel MSI
    Write-Host "  Rebooting VM to finalise WSL app install..."
    Restart-VM $VMName -Force
    Wait-VMReady $VMName $cred -TimeoutSec 300
    Mark-Done $state "wsl-install"
}

if (-not (Is-Done $state "wsl2-default")) {
    Write-Banner "STEP 3b -- Configure WSL2 Kernel and Default Version"
    Invoke-InVM {
        # Ensure nested virt features are active (idempotent)
        Write-Host "  Confirming VirtualMachinePlatform feature..."
        dism /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
        dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null

        # Enable "Receive updates for other Microsoft products" so wsl --update works
        Write-Host "  Enabling Microsoft Update for other products..."
        $svcMgr = New-Object -ComObject Microsoft.Update.ServiceManager
        $svcMgr.ClientApplicationID = "WSL2 Setup"
        # GUID 7971f918-... is the Microsoft Update service
        $svcMgr.AddService2("7971f918-a847-4430-9279-4a52d1efe18d", 7, "") | Out-Null
        Write-Host "  Microsoft Update enabled." -ForegroundColor Green

        # Install WSL application (DISM enables the Windows components but does NOT
        # install the WSL app itself -- this step is required before any wsl command works)
        Write-Host "  Installing WSL application..."
        $installOut = wsl --install --no-distribution 2>&1 | Out-String
        Write-Host $installOut
        # wsl --install exits 0 even when a reboot is pending; we continue regardless
        # because the kernel MSI step below is always needed on Windows 10

        # Install the WSL2 Linux kernel update package
        Write-Host "  Downloading WSL2 Linux kernel update..."
        $msi = "$env:TEMP\wsl_kernel.msi"
        Invoke-WebRequest `
            -Uri "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi" `
            -OutFile $msi -UseBasicParsing
        Write-Host "  Installing WSL2 kernel update package..."
        Start-Process msiexec -ArgumentList "/i `"$msi`" /quiet /norestart" -Wait
        Remove-Item $msi -Force -ErrorAction SilentlyContinue
        Write-Host "  WSL2 kernel installed." -ForegroundColor Green

        # Update WSL to the latest available version
        Write-Host "  Updating WSL..."
        wsl --update 2>&1 | Out-String | Write-Host

        # Set WSL2 as the default version
        Write-Host "  Setting WSL2 as default version..."
        wsl --set-default-version 2
        Write-Host "  WSL2 set as default." -ForegroundColor Green
    }
    Assert-WSL2
    Mark-Done $state "wsl2-default"
}

# =============================================================================
# STEP 4 -- Chocolatey + Docker Desktop + reboot
# =============================================================================

if (-not (Is-Done $state "docker-install")) {
    Write-Banner "STEP 4 -- Install Docker Desktop"
    Invoke-InVM {
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Host "  Installing Chocolatey..."
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [Net.ServicePointManager]::SecurityProtocol = 3072
            iex ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        choco install docker-desktop -y
    }
    Mark-Done $state "docker-install"
}

if (-not (Is-Done $state "docker-reboot")) {
    Write-Host "  Rebooting VM after Docker install..."
    Stop-VM $VMName -Force -ErrorAction SilentlyContinue
    Start-VM $VMName
    Wait-VMReady $VMName $cred -TimeoutSec 300
    Mark-Done $state "docker-reboot"
}

# =============================================================================
# STEP 5 -- Start Docker Desktop, wait for daemon
# =============================================================================

if (-not (Is-Done $state "docker-ready")) {
    Write-Banner "STEP 5 -- Start Docker Desktop"

    # Ensure WSL is fully up to date before Docker starts
    Invoke-InVM {
        Write-Host "  Updating WSL before starting Docker..."
        wsl --update 2>&1 | Out-Null
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    }

    Write-Host ""
    Write-Host "  +-------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host "  |  ACTION REQUIRED -- Manual step in the VM             |" -ForegroundColor Yellow
    Write-Host "  |                                                       |" -ForegroundColor Yellow
    Write-Host "  |  1. Switch to the VM window.                          |" -ForegroundColor Yellow
    Write-Host "  |  2. Accept the Docker Desktop terms of service.       |" -ForegroundColor Yellow
    Write-Host "  |  3. Wait until the Docker Desktop dashboard loads.    |" -ForegroundColor Yellow
    Write-Host "  |  4. Come back here and press ENTER to continue.       |" -ForegroundColor Yellow
    Write-Host "  +-------------------------------------------------------+" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Press ENTER when Docker Desktop is running" | Out-Null

    Assert-DockerReady
    Mark-Done $state "docker-ready"
}

# =============================================================================
# STEP 6 -- Deploy Ollama + Caddy via Docker Compose
# =============================================================================

if (-not (Is-Done $state "compose-up")) {
    Write-Banner "STEP 6 -- Deploy Ollama + Caddy"
    Invoke-InVM {
        New-Item -ItemType Directory -Path C:\ollama-ssl -Force | Out-Null
        Set-Location C:\ollama-ssl

        @"
version: '3.8'
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
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
    depends_on:
      - ollama

volumes:
  ollama_data:
  caddy_data:
"@ | Set-Content docker-compose.yml -Encoding utf8

        @"
https://localhost {
    reverse_proxy ollama:11434
    tls internal
}
"@ | Set-Content Caddyfile -Encoding utf8

        docker compose down
        docker compose up -d
    }
    Mark-Done $state "compose-up"
}

# =============================================================================
# STEP 7 -- Pull selected models (each tracked independently)
# =============================================================================

$pendingModels = $state.Models | Where-Object { -not (Is-Done $state "model:$_") }

if ($pendingModels) {
    Write-Banner "STEP 7 -- Pull Ollama Models"
    $total = $state.Models.Count
    $idx   = 0
    foreach ($model in $state.Models) {
        $idx++
        $stepKey = "model:$model"
        if (Is-Done $state $stepKey) {
            Write-Host "  [$idx/$total] $model -- already pulled, skipping." -ForegroundColor DarkGray
            continue
        }
        Write-Host "  [$idx/$total] Pulling $model ..." -ForegroundColor Cyan
        Invoke-InVM -Script ([scriptblock]::Create("docker exec ollama ollama pull $model"))
        Mark-Done $state $stepKey
    }
}

# =============================================================================
# STEP 8 -- Install SSL certificate
# =============================================================================

if (-not (Is-Done $state "ssl-cert")) {
    Write-Banner "STEP 8 -- Install SSL Certificate"
    Invoke-InVM {
        docker exec caddy cat /data/caddy/pki/authorities/local/root.crt |
            Out-File C:\ollama-ssl\root.crt -Encoding ascii
        certutil -addstore -f "ROOT" C:\ollama-ssl\root.crt
    }
    Mark-Done $state "ssl-cert"
}

# =============================================================================
# STEP 9 -- Validate Ollama API
# =============================================================================

if (-not (Is-Done $state "api-ok")) {
    Write-Banner "STEP 9 -- Validate API"
    Assert-OllamaAPI
    Mark-Done $state "api-ok"
}

# =============================================================================
# COMPLETE
# =============================================================================

Write-Host ""
Write-Host "  +========================================+" -ForegroundColor Green
Write-Host "  |          DEPLOY COMPLETED              |" -ForegroundColor Green
Write-Host ("  |  VM     : {0,-30}|" -f $VMName) -ForegroundColor Green
Write-Host ("  |  Models : {0,-30}|" -f "$($state.Models.Count) installed") -ForegroundColor Green
Write-Host "  +========================================+" -ForegroundColor Green
Write-Host ""

Remove-Item $StateFile -ErrorAction SilentlyContinue
