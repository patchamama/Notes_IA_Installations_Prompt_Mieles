# VPS Configuration & Local Machine

Fuente: https://www.youtube.com/watch?v=7qmu3QmEwpE

# Agregar sin usar root

```ssh
ssh root@patchamama.com
# Agregar usuario humano en el servidor
adduser devadmin
# Agregar usuario a grupo sudo y devadmin
usermod -aG sudo devadmin
id devadmin


# Agregar usuario para ejecutar `claude` (claude, codex,...) sin permisos `sudo`
adduser claude
```

# Habilitar acceso desde la máquina local usando las claves ssh sin necesidad de introducir contraseña (desde el terminal local)

```ssh
# desde el terminal local y no el servidor
ssh-copy-id devadmin@patchamama.com
ssh-copy-id claude@patchamama.com
```

## Acceder desde la máquina local directamente

```ssh
# desde el terminal local y no el servidor
ssh devadmin@patchamama.com
ssh claude@patchamama.com
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
```

# Definir área de trabajo del agente de claude

```ssh
sudo mkdir -p /home/claude/proyectos
sudo chown -R claude:claude /home/claude/proyectos
```

# Acceder al servidor como `claude` e instalar claude desde usuario `ssh@claude`

```ssh
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
claude --version
claude doctor
claude
```

> [!NOTE]
> Dentro de `claude` ejecutar `/login` para iniciar la sesión.

# Configurar cuenta de github desde `ssh@claude`

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

# Configurar cuenta de claude-remote desde `ssh@claude` 

Esto nos dará un código QR que nos permitiría conectarnos 

```ssh
claude remote-control
```

# Crear sesión persistente con  `devadmin@ssh` 

```ssh
sudo nano /etc/systemd/system/claude-remote.service
```

<img width="80%" alt="image" src="https://github.com/user-attachments/assets/68359eb5-7a55-4e4d-9267-b8c3bea73475" />

Asegurarse que el path de claude es correcto:

```ssh
which claude
# /home/claude/.local/bin/claude
```

Reemplazar la línea:

```
ExecStart=/usr/bin/tmux new-session -d -s claude 'claude-remote'
```

por 

```
ExecStart=/usr/bin/tmux new-session -d -s claude '/home/claude/.local/bin/claude-remote'
```
