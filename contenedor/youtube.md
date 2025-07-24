
# Contenedor YouTube Viewer con Chromium + Xvfb + VNC en RHEL 9

Este proyecto crea un contenedor que ejecuta Chromium en un entorno gráfico virtual (`Xvfb`), reproduce un video de YouTube durante 10 minutos, luego se pausa 5 minutos y repite el ciclo. Además, expone el entorno gráfico mediante VNC para poder verlo remotamente.

---

## 1. Requisitos previos en RHEL 9

Importar la clave GPG de EPEL:

```bash
sudo rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-9
```

Instalar el repositorio EPEL:

```bash
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
```

Habilitar el repositorio EPEL y actualizar caché:

```bash
sudo dnf config-manager --enable epel
sudo dnf makecache
```

Instalar Podman (si no está instalado):

```bash
sudo dnf install -y podman
```

---

## 2. Archivos del proyecto

### Dockerfile

```Dockerfile
FROM registry.access.redhat.com/ubi9/ubi

USER root

RUN dnf -y install wget rpm && \
    wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    rpm -ivh epel-release-latest-9.noarch.rpm && \
    dnf config-manager --enable epel && \
    dnf makecache

RUN dnf -y install chromium xorg-x11-server-Xvfb wmctrl xdotool x11vnc tigervnc-server && \
    dnf clean all

RUN useradd -ms /bin/bash chromeuser

USER chromeuser
WORKDIR /home/chromeuser

COPY --chown=chromeuser:chromeuser start.sh watch_once.sh x11vnc.sh .
RUN chmod +x start.sh watch_once.sh x11vnc.sh

EXPOSE 5900

CMD ["./start.sh"]
```

---

### start.sh

```bash
#!/bin/bash

echo "Inicio del ciclo repetitivo de YouTube con VNC..."

while true; do
  echo "🟢 Iniciando sesión de video y VNC..."
  ./watch_once.sh
  echo "🟡 Esperando 5 minutos antes de la próxima ejecución..."
  sleep 300
done
```

---

### watch_once.sh

```bash
#!/bin/bash

echo "Iniciando Xvfb..."
Xvfb :99 -screen 0 1280x720x24 &
XVFB_PID=$!

export DISPLAY=:99
sleep 2

echo "Iniciando Chromium..."
chromium --no-sandbox --disable-gpu --disable-software-rasterizer \
  "https://www.youtube.com/watch?v=AWFPhBKeea4" &
CHROME_PID=$!

echo "Iniciando x11vnc..."
./x11vnc.sh & 
VNC_PID=$!

sleep 600

echo "Deteniendo Chromium, Xvfb y x11vnc..."
kill $CHROME_PID
kill $XVFB_PID
kill $VNC_PID
```

---

### x11vnc.sh

```bash
#!/bin/bash

x11vnc -display :99 -nopw -forever -shared
```

---

## 3. Construcción de la imagen

Desde el directorio donde estén los archivos, ejecutá:

```bash
podman build -t youtube-viewer .
```

---

## 4. Ejecución del contenedor

Exponiendo el puerto VNC 5900 dentro del contenedor en el puerto 8080 del host:

```bash
podman run -d --name youtube_chromium -p 8080:5900 youtube-viewer
```

---

## 5. Conexión VNC

Desde tu máquina cliente, conectate con un cliente VNC al host usando:

```
ip-del-servidor-rhel:8080
```

---

## 6. Detener todos los contenedores en Podman

Para detener todos los contenedores corriendo:

```bash
podman ps -q | xargs -r podman stop
```

Para eliminar todos los contenedores (detenidos y corriendo):

```bash
podman ps -a -q | xargs -r podman rm
```

---

## 7. Opcional: Agregar contraseña a VNC

1. Generar archivo de contraseña:

```bash
x11vnc -storepasswd
```

2. Modificar `x11vnc.sh` para usar la contraseña:

```bash
#!/bin/bash

x11vnc -display :99 -rfbauth ~/.vnc/passwd -forever -shared
```


