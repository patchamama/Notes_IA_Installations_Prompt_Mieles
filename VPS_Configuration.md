# VPS Configuration & Local Machine

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

# Acceder al servidor como `claude` e instalar claude

```ssh
curl -fsSL https://claude.ai/install.sh | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
claude --version
claude doctor
```


