
# Contenedor con Chromium + VNC + noVNC en Fedora (puerto 8080)

Este contenedor permite ejecutar Chromium en un entorno sin GUI (Fedora minimal), renderizado con Xvfb y accesible vía navegador web usando noVNC en el puerto 8080.

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

## Preparar el ambiente

```
sudo dnf install -y podman
sudo dnf install -y podman git wget tar unzip
sudo dnf install -y python3-pip


sudo rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-9
curl -Iv https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-9
sudo dnf install -y   https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo dnf makecache

sudo mkdir -p /run/user/$(id -u)
sudo chown "$USER":"$USER" /run/user/$(id -u)
ls -ld /run/user/$(id -u)


```


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

URL="https://www.youtube.com/embed/videoseries?list=PLBrdJqPHEZjuuzjTs7pZ_mnDagZHgqTfG&autoplay=1&mute=1&loop=1&playlist=AWFPhBKeea4,W7nXhghwvQ4,t_VsTw0Sj5o"

while true; do
  echo "Iniciando Chromium en modo kiosko..."
  chromium-browser --no-sandbox --disable-gpu --disable-software-rasterizer \
    --autoplay-policy=no-user-gesture-required \
    --disable-features=MediaSessionService \
    --window-size=1920,1080 --start-fullscreen --kiosk "$URL"
  echo "Chromium terminó. Reiniciando en 5 segundos..."
  sleep 5
done

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
podman build -t youtube-kiosk .

podman run -d --name youtube_kiosk -it --net=host youtube-kiosk
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
podman stop youtube_kiosk
podman rm youtube_kiosk
```

---

NOTA: El contenedor como esta configurado siempre va a estar funcionando, no necesita reiniciar ni nada... el playlist termina... se espera 5 segundos... y vuelve a correr
=


## 🔁 Ejecutar el contenedor cada 30 minutos (suponiendo que por algun motivo deseamos reiniciarlo cada 30 minutos)

Primero asegurar que el contenedor no esta levantado
```
podman container list
```

Nos aseguramos que crone esta instalado y activo 

```
dnf install cronie -y
systemctl enable crond --now
```

Para asegurar que no este levantado y solo creado

```
podman ps -q | xargs -r podman stop
podman rm -a -f
podman container prune
podman rmi --all --force

podman build -t youtube-kiosk .

podman create --name youtube_kiosk --net host -e DISPLAY=:0 -p 8080:8080  localhost/youtube-kiosk
```

Luego, ya podés usar `cron` en el host para iniciar el contenedor así:

```
crontab -e
```

Agregar esta linea 

```cron
# Iniciar el contenedor a los minutos 00, y 30 de cada hora
00,30 * * * * /usr/bin/podman start youtube_kiosk

# Detener el contenedor a los minutos 27 y 57
57,27 * * * * /usr/bin/podman stop youtube_kiosk
58,28 * * * * /usr/bin/podman rm -a -f
59,29 * * * * /usr/bin/podman create --name youtube_kiosk --net host -e DISPLAY=:0 -p 8080:8080  localhost/youtube-kiosk

```

Esto lo arranca en los minutos 00, 15, 30, 45 y lo apaga en 05, 20, 35, 50 respectivamente.

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


