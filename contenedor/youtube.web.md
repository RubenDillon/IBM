
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
    mesa-dri-drivers \
    mesa-libGL \
    libXScrnSaver \
    libXcursor \
    libXrandr \
    alsa-lib \
    wget \
    tar \
    && dnf clean all

# Clonar noVNC y websockify antes de cambiar usuario
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

RUN useradd -ms /bin/bash usuario

COPY start.sh watch_once.sh x11vnc.sh /home/usuario/
RUN chown usuario:usuario /home/usuario/*.sh && chmod +x /home/usuario/*.sh

USER usuario
WORKDIR /home/usuario

CMD ["./start.sh"]
```

---

## ▶️ start.sh

```bash
#!/bin/bash

Xvfb :0 -screen 0 1920x1080x24 &
export DISPLAY=:0

./x11vnc.sh &

sleep 5

/opt/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 8080 &

sleep 3

./watch_once.sh

sleep 300

exec "$0"
```

---

## ▶️ watch_once.sh

```bash
#!/bin/bash

export DISPLAY=:0

chromium-browser --no-sandbox --disable-gpu --disable-software-rasterizer \
  --autoplay-policy=no-user-gesture-required \
  --disable-features=MediaSessionService \
  --window-size=1920,1080 --start-fullscreen --kiosk "https://www.youtube.com/watch?v=AWFPhBKeea4&autoplay=1&mute=1" &

sleep 600

pkill -f chromium-browser
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

## 🔁 Ejecutar el contenedor cada 15 minutos

Primero asegurar que el contenedor no esta levantado
```
podman container list
```

Para asegurar que no este levantado y solo creado

```
podman ps -q | xargs -r podman stop
podman rm -a -f
podman container prune
podman rmi --all --force

podman create --name youtube_chromium -p 8080:8080 youtube-kiosk
```

Luego, ya podés usar `cron` en el host para iniciar el contenedor así:

```
crontab -e
```

Agregar esta linea 

```cron
*/15 * * * * /usr/bin/podman start youtube_chromium
5-59/15 * * * * /usr/bin/podman stop youtube_chromium
```

Y dejar que el contenedor se apague solo al terminar los 10 minutos de reproducción (usando `sleep 600 && podman stop self` si se desea).

---

Para validar si el cron ha sido ejecutado

```
journalctl -u crond

```


Matar todos los contenedores 

```
podman ps -q | xargs -r podman stop
podman rm -a -f
podman container prune
podman rmi --all --force
```

