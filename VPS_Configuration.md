# Server AI Production 24/7

Fuentes: 

- https://www.youtube.com/watch?v=7qmu3QmEwpE
  
<p align="left">
  <a href="https://www.youtube.com/watch?v=7qmu3QmEwpE">
    <img src="https://img.youtube.com/vi/7qmu3QmEwpE/hqdefault.jpg"
         alt="Ver vídeo en YouTube"
         width="25%">
  </a>
</p>

- https://www.youtube.com/watch?v=BY8cl-cXf6I
  
<p align="left">
  <a href="https://www.youtube.com/watch?v=BY8cl-cXf6I">
    <img src="https://img.youtube.com/vi/BY8cl-cXf6I/hqdefault.jpg"
         alt="Ver vídeo en YouTube"
         width="25%">
  </a>
</p>

# Agregar sin usar root

```ssh
ssh root@ip
# Agregar usuario humano en el servidor
sudo adduser dev
# Agregar usuario a grupo sudo y dev
usermod -aG sudo dev
id dev

su - dev
sudo whoami

# Agregar usuario para ejecutar `claude` (claude, codex,...) sin permisos `sudo`
adduser claude
```

# Habilitar acceso desde la máquina local usando las claves ssh sin necesidad de introducir contraseña (desde el terminal local)

```ssh
# desde el terminal local y no el servidor
ssh-copy-id dev@ip
ssh-copy-id claude@ip
```

## Acceder desde la máquina local directamente

```ssh
# desde el terminal local y no el servidor
ssh dev@ip
ssh claude@ip
```

# Solo acceder con la clave ssh: Sí se desea desactivar el acceso del usuario `root`, deshabilitar el acceso con contraseña, se edita el archivo `nano /etc/ssh/sshd_config`:

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

```ssh
systemctl restart ssh
```

# Activar/configrar el Firewall (ufw: _uncomplicated firewall_ ). 

```ssh
ufw --version
# Bloquear por defecto todas las llamadas entrantes
ufw default deny incoming
# Por defecto permitir todas las llamadas salientes
ufw default allow outgoing
# Permitir ssh y activar ufw
ufw ssh
ufw enable
ufw status
```

# Instalar la herramienta `fail2ban` para banear por defecto cualquier IP que intente conectarse

```ssh
sudo app install fail2ban -y
systemctl enable --now fail2ban
```

# Instalar tmux y github cli para mantener las sesiones abiertas 

```ssh
sudo apt install tmux gh -y
tmux -V
```

### Configuración de `tmux`

```ssh
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

# Definir área de trabajo del agente de claude

```ssh
sudo mkdir -p /home/claude/proyectos
sudo chown -R claude:claude /home/claude/proyectos
```

# Acceder al servidor como `claude` e instalar claude desde usuario `claude@ip`

```ssh
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
claude --version
claude doctor
claude
```

> [!NOTE]
> Dentro de `claude` ejecutar `/login` para iniciar la sesión.

# Configurar cuenta de github desde `claude@ip`

```ssh
gh auth login
gh auth setup-git
cd /home/claude/proyectos
git clone <proyecto>
```

# Para que funcione el acceso al servidor automáticamente desde ssh a github

```ssh
# Generar clave ssh del servidor 
ssh-keygen -t ed25519 -C "patchamama.go@gmail.com" -f ~/.ssh/id_ed25519 -N ""
# Mostrar contenido de la llave privada
cat ~/.ssh/id_ed25519.pub
```

Copiar contenido de la llave privada e insertar en cuenta de github > settings > SSH and GPG keys > Button "New SSH key", de esta forma se podrá clonar y trabajar con proyectos privados en github. 

# Configurar cuenta de claude-remote desde `claude@ip` 

Esto nos dará un código QR que nos permitiría conectarnos 

```ssh
claude remote-control
```

# Crear sesión persistente con  `dev@ssh` 

```ssh
sudo nano /etc/systemd/system/claude-remote.service
```

<img width="80%" alt="image" src="https://github.com/user-attachments/assets/68359eb5-7a55-4e4d-9267-b8c3bea73475" />

```ssh
sudo tee /etc/systemd/system/claude-remote.service > /dev/null << 'EOF'
[Unit]
Description=Claude Code Remote Control
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
User=claude
WorkingDirectory=/home/claude/proyectos
ExecStart=/usr/bin/tmux new-session -d -s claude 'claude remote-control'
ExecStop=/usr/bin/tmux kill-session -t claude
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
```

Asegurarse que el path de claude es correcto:

```ssh
which claude
# /home/claude/.local/bin/claude
```

Reemplazar la línea:

```
ExecStart=/usr/bin/tmux new-session -d -s claude 'claude remote-control'
```

por 

```
ExecStart=/usr/bin/tmux new-session -d -s claude '/home/claude/.local/bin/claude remote-control'
```

Reiniciar servicio

```ssh
sudo systemctl daemon-reload
sudo systemctl enable --now claude-remote
sudo systemctl start claude-remote
sudo systemctl status claude-remote
```

> [!NOTE]
> De esta forma, al reiniciarse el servidor, estará siempre levantándose de forma automática el `claude-remote` en `tmux` y accesible desde le móvil.

# TIPs que mejoran la interacción con Agentes/AI

- Sí se desea que la IA ejecute comandos sudo sin estar preguntando por la contraseña (`ssh dev@ip`):

```ssh
echo 'dev ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/dev
sudo chmod 0440 /etc/sudoers.d/dev
```

- Activar control remoto desde dentro de claude

```
/rc
# o /remoto-control
``` 

- Reactivar la última sesión de `claude` abierta

```ssh
claude -c
```

- Cerrar `tmux` y dejarlo en modo persistente (dtacht): `Ctrl + b + d`



