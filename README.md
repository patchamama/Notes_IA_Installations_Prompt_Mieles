
### Installation

Mac OS X

```sh
brew install ollama
ollama
brew install opencode

# Install agents (gentle-ai agents and settings) See: https://github.com/Gentleman-Programming/gentle-ai
curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash

# Install glm-4.7 flash model
ollama pull hf.co/unsloth/GLM-4.7-Flash-GGUF:UD-Q4_K_XL

#  Launch opencode with Ollama integration
ollama launch opencode --config
```

- Activate for the use of the free/paid model in https://opencode.ai/zen to use `opencode Go`

### IOS/Android APP to test local models

- Google AI Edge Gallery para modelos locales de Google como Gemma 4.

### AI Stack (SDD)

- [AI Gentle Stack](https://github.com/Gentleman-Programming/gentle-ai)

Install

```sh
curl -fsSL https://raw.githubusercontent.com/Gentleman-Programming/gentle-ai/main/scripts/install.sh | bash
```

### Mode save tokens

-  [Caveman: why use many tokens when few do trick](https://github.com/patchamama/caveman)

Install

```sh
claude plugin marketplace add JuliusBrussee/caveman && claude plugin install caveman@caveman
```

Trigger with:
```
/caveman or `Codex $caveman`
"talk like caveman"
"caveman mode"
"less tokens please"
```

Stop with: `"stop caveman" or "normal mode"`

### Agent Assistants

- [Portable AI agent skills. One CLI. Every coding assistant.](https://www.npmjs.com/package/@skilly-hand/skilly-hand)

| Command                     | Description                                              |
|----------------------------|----------------------------------------------------------|
| npx skilly-hand install    | Install skills into the current project                  |
| npx skilly-hand detect     | Auto-detect project stack and suggest skills            |
| npx skilly-hand list       | List all available skills in the catalog                |
| npx skilly-hand doctor     | Diagnose installation and configuration issues          |
| npx skilly-hand uninstall  | Remove installed skills    

### Improve the search (grep) for information in the documents

- [mgrep: A calm, CLI-native way to semantically grep everything, like code, images, pdfs and more.](https://github.com/mixedbread-ai/mgrep)

### Create Docker Ollama installation with SSL support (reverse ssl proxy)

#### HyperV Windows Server VM (2022, 2025) + WSL + Docker

Problema: no se puede instalar y configurar Docker pues necesita `Nested virtualization`.

```ps
# Ejecutar en el Host (activate nested virtualization)
Set-VMProcessor -VMName "VM_Name" -ExposeVirtualizationExtensions $true
# Host (apagar completamente la VM
Stop-VM "VM_Name" 
# Reiniciar la VM y dentro de la VM activar feautures:
dism /online /enable-feature /featurename:VirtualMachinePlatform /all
dism /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all
# Reiniciar VM y probar dentro de VM tras reiniciar (`Nested virtualization` OK sí muestra: `The operation completed successfully.`):
wsl --set-default-version 2
```

# Instalar y configurar `Docker`
Una vez instalado y ejecutado `Docker` este hará:

- crear docker-desktop
- crear docker-desktop-data
- usar WSL2 internamente

Para comprobar, ejecutar: 

```ps
wsl -l -v
```

Debería de salir algo así: 

```
NAME                   STATE           VERSION
docker-desktop         Running         2
```

Test final, ejecuta en el terminal:

```ps
docker run hello-world
```

Si funciona:

- ✔ Docker OK
- ✔ WSL2 OK
- ✔ listo para Ollama

#### Montar Ollama con Docker

```ps
mkdir C:\ollama-ssl
cd C:\ollama-ssl
```

#### Crear `docker-compose.yml`

```ps
notepad docker-compose.yml
```

Pegar:

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

#### Crear `Caddyfile`

```ps
notepad Caddyfile
```

> [!NOTE]
> Asegúrate de que exista el archivo `Caddyfile` sin extensión pues notepad suele en estos casos crear un archivo `Caddyfile.txt` y puedes comprobarlo con `dir c:\ollama-ssl`, sí no existe el archivo `Caddyfile`, puedes crearlo con `rename Caddyfile.txt Caddyfile`. 

Pegar:

```
https://localhost {
    reverse_proxy ollama:11434
    tls internal
}
```

O mejor para evitar problemas con encoding UTF-8, pegar en el terminal:

```ps
@"
https://localhost {
    reverse_proxy ollama:11434
    tls internal
}
"@ | Out-File -Encoding utf8 Caddyfile
```

#### Levantar contenedores y verificar

```ps
# Levantar contenedor
docker compose down
docker compose up -d

# Verificar
docker ps

# Descargar un modelo ligero en Ollama como `deepseek-r1:1.5b`
docker exec -it ollama ollama pull deepseek-r1:1.5b

# Descargar e instalar certifiado SSL (crítico para ELO)
docker exec caddy cat /data/caddy/pki/authorities/local/root.crt > root.crt
# Instalar certificado en windows
certutil -addstore -f "ROOT" root.crt

# Test rápido (debe de mostar un json con StatusCode: 200)
curl https://localhost/api/tags
```

Finalmente quedaría:

```
Anbieter:	Ollama
API-Schlüssel:	ollama
Modellname:	deepseek-r1:1.5b
API-Endpunkt:	https://localhost
```


#### Problemas técnicos

- ELO no conecta

Prueba cambiar la url por `https://127.0.0.1` y cambia el contenido de `Caddyfile` a:

```
https://127.0.0.1 {
    reverse_proxy ollama:11434
    tls internal
}
```

Opcional que se puede testear:
- Compartir GPU de máquina Host con VM
- Instalar `llama3:8b`
- Exponer `Ollama Docker` en la red

