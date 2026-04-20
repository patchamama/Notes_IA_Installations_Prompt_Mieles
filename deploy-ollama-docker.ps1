# =========================
# CONFIG
# =========================

$ErrorActionPreference = "Stop"

function Select-VM {
$vms = Get-VM
Write-Host "VMs disponibles:" -ForegroundColor Cyan
for ($i = 0; $i -lt $vms.Count; $i++) {
Write-Host "$i) $($vms[$i].Name) - Estado: $($vms[$i].State)"
}
$choice = Read-Host "Selecciona VM"
return $vms[$choice].Name
}

$VMName = Select-VM
$cred = Get-Credential

Write-Host "Usando VM: $VMName" -ForegroundColor Green

# =========================
# STEP 1: Nested Virtualization
# =========================

Write-Host "Configurando Nested Virtualization..."
Stop-VM $VMName -Force -ErrorAction SilentlyContinue
Set-VMProcessor -VMName $VMName -ExposeVirtualizationExtensions $true
Start-VM $VMName

Start-Sleep -Seconds 20

# =========================
# Helper: ejecutar comando con retry
# =========================

function Invoke-InVM {
param($Script)


$max = 10
for ($i=0; $i -lt $max; $i++) {
    try {
        return Invoke-Command -VMName $VMName -Credential $cred -ScriptBlock $Script
    } catch {
        Write-Host "Reintentando conexión VM..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15
    }
}
throw "No se pudo conectar a la VM"


}

# =========================
# STEP 2: Activar WSL
# =========================

Write-Host "Activando WSL..."
Invoke-InVM {
dism /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
}

Write-Host "Reiniciando VM..."
Restart-VM $VMName -Force
Start-Sleep -Seconds 40

# =========================
# STEP 3: Configurar WSL2
# =========================

Invoke-InVM {
wsl --set-default-version 2
}

# =========================
# STEP 4: Instalar Chocolatey + Docker
# =========================

Invoke-InVM {


if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Instalando Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

Write-Host "Instalando Docker Desktop..."
choco install docker-desktop -y


}

Write-Host "Esperando instalación Docker..."
Start-Sleep -Seconds 60
Stop-VM $VMName -Force -ErrorAction SilentlyContinue
Start-VM $VMName


# =========================
# STEP 5: Iniciar Docker
# =========================

Invoke-InVM {
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
}

Start-Sleep -Seconds 40

# =========================

# STEP 6: Crear entorno Ollama

# =========================

Invoke-InVM {


mkdir C:\ollama-ssl -ErrorAction SilentlyContinue
cd C:\ollama-ssl


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
"@ | Out-File -Encoding utf8 docker-compose.yml

@"
https://localhost {
reverse_proxy ollama:11434
tls internal
}
"@ | Out-File -Encoding utf8 Caddyfile


docker compose down
docker compose up -d


}

# =========================
# STEP 7: Descargar modelo + SSL
# =========================

Invoke-InVM {


docker exec ollama ollama pull deepseek-r1:1.5b

docker exec caddy cat /data/caddy/pki/authorities/local/root.crt > C:\ollama-ssl\root.crt

certutil -addstore -f "ROOT" C:\ollama-ssl\root.crt

curl https://localhost/api/tags


}

Write-Host "`nDEPLOY COMPLETADO 🚀" -ForegroundColor Green
