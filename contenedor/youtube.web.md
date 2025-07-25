
# Contenedor con Chromium + VNC + noVNC en RHEL (puerto 8080)

Este contenedor permite ejecutar Chromium en un entorno sin GUI (RHEL minimal), renderizado con Xvfb y accesible vía navegador web usando noVNC en el puerto 8080.

---

## ✅ Características

- Corre Chromium con salida gráfica en Xvfb
- VNC servido por x11vnc
- Accesible desde navegador web vía noVNC (HTML5 + WebSockets)
- Todo dentro de un contenedor Podman compatible

---

## 🛠️ Estructura del proyecto

```
.
├── Dockerfile
├── start.sh
├── watch_once.sh
├── x11vnc.sh
└── noVNC/          <-- Clonado desde GitHub
```

---

## 📄 Dockerfile

```Dockerfile
FROM fedora:40

RUN dnf install -y \
    chromium \
    xorg-x11-server-Xvfb \
    x11vnc \
    git \
    python3 \
    python3-pip \
    procps \
    wget \
    tar \
    && dnf clean all

# Clonar noVNC y websockify como root
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

# Copiar scripts antes de cambiar de usuario
COPY start.sh watch_once.sh x11vnc.sh /home/usuario/

# Crear usuario y asignar permisos a los scripts
RUN useradd -ms /bin/bash usuario && \
    chown usuario:usuario /home/usuario/*.sh && \
    chmod +x /home/usuario/*.sh

# Cambiar a usuario no root
USER usuario
WORKDIR /home/usuario

CMD ["./start.sh"]

```

---

## ▶️ start.sh

```bash
#!/bin/bash

# Iniciar Xvfb
Xvfb :99 -screen 0 1280x720x24 &

export DISPLAY=:99

# Iniciar x11vnc (sin contraseña)
x11vnc -display :99 -nopw -forever -shared &

# Lanzar Chromium para ver un video por 10 minutos
./watch_once.sh &

# Iniciar noVNC (WebSocket en puerto 8080)
/opt/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080
```

---

## ▶️ watch_once.sh

```bash
#!/bin/bash

export DISPLAY=:99

# Esperar a que el Xvfb y VNC estén listos
sleep 5

# Lanzar Chromium en modo app
chromium-browser --no-sandbox --disable-gpu --start-fullscreen --app=https://www.youtube.com/watch?v=AWFPhBKeea4 &

# Ver el video durante 10 minutos
sleep 600

# Cerrar Chromium
pkill chromium
```

---

## ▶️ x11vnc.sh (opcional)

```bash
#!/bin/bash

x11vnc -display :99 -nopw -forever -shared
```

---

## 🧪 Cómo construir y ejecutar

```bash
podman build -t youtube-viewer .

podman run -d --name youtube_chromium -p 8080:8080 youtube-viewer
```

---

## 🌐 Acceder desde el navegador

Conectate desde tu navegador a:

```
http://IP_DEL_SERVIDOR:8080/vnc.html
```

---

## 🧹 Detener y eliminar contenedores

```bash
podman stop youtube_chromium
podman rm youtube_chromium
```

---

## 🔁 Ejecutar el contenedor cada 15 minutos (opcional)

Podés usar `cron` en el host para iniciar el contenedor así:

```cron
*/15 * * * * podman start youtube_chromium
```

Y dejar que el contenedor se apague solo al terminar los 10 minutos de reproducción (usando `sleep 600 && podman stop self` si se desea).

---
