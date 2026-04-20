# AI Tools & Installations

## Installation

### Mac OS X

```sh
brew install ollama
ollama
brew install opencode

# Install agents (gentle-ai agents and settings) See: https://github.com/Gentleman-Programming/gentle-ai
curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash

# Install glm-4.7 flash model
ollama pull hf.co/unsloth/GLM-4.7-Flash-GGUF:UD-Q4_K_XL

# Launch opencode with Ollama integration
ollama launch opencode --config
```

- Activate free/paid model support at <https://opencode.ai/zen> to use `opencode Go`

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

- [Caveman: why use many tokens when few do trick](https://github.com/patchamama/caveman)

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

### Semantic Search for Documents

- [mgrep: A calm, CLI-native way to semantically grep everything — code, images, PDFs and more.](https://github.com/mixedbread-ai/mgrep)

---

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
# Run on the Host — enable nested virtualization
Set-VMProcessor -VMName "VM_Name" -ExposeVirtualizationExtensions $true

# Shut down the VM completely from the Host
Stop-VM "VM_Name"

# Restart the VM, then enable the required features inside the VM
dism /online /enable-feature /featurename:VirtualMachinePlatform /all
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all

# Restart VM and verify nested virtualization (success = "The operation completed successfully.")

# Download and install WSL2 Kernel update:  https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi
wsl --set-default-version 2
```

#### Install and Configure Docker

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
https://localhost {
    reverse_proxy ollama:11434
    tls internal
}
```

Or use PowerShell to avoid UTF-8 encoding issues:

```ps
@"
https://localhost {
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
