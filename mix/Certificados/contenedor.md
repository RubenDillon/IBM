Crear Dominio y generar un certificado para el dominio
=


1. Crear un subdominio en DuckDNS
DuckDNS te permite registrar un subdominio dinámico gratis.

Ir a https://www.duckdns.org/

Iniciá sesión con tu cuenta GitHub/Google.

Elegí un subdominio, por ejemplo: ibmconcert.duckdns.org

Te va a mostrar un token, por ejemplo: 842c7a3-a5f5-4001-xxxx

Anotá el subdominio y el token, los vas a usar en el script.

2. tenemos que crear la siguiente estructura

```   
duckdns-certbot/
├── certs/                     # Donde se guardan los .pem
├── duckdns.env                # Variables necesarias
├── get-cert.sh                # Script para emitir el certificado
└── podmanfile (opcional)     # Si querés hacer una imagen personalizada
```

Debemos crear el archivo duckdns.env

```
export DuckDNS_Token="7842c7a3-xvd5-e3fs-0909-p5t4"
export CERT_DOMAIN="ibmconcert.duckdns.org"
export EMAIL="xyz@gmail.com"

```

Luego el archivo get-cert.sh

```
#!/bin/bash
set -e

# Cargar variables
source ./duckdns.env

# Crear volumen para persistir certificados
CERTS_DIR="$(pwd)/certs"
mkdir -p "$CERTS_DIR"

# Ejecutar acme.sh con DNS-01 usando DuckDNS
podman run --rm \
  -e DuckDNS_Token="${DuckDNS_Token}" \
  -v "$CERTS_DIR":/acme.sh \
  neilpang/acme.sh \
  --issue --dns dns_duckdns -d "$CERT_DOMAIN" \
  --keylength ec-256 \
  --fullchain-file "/acme.sh/fullchain.pem" \
  --key-file "/acme.sh/privkey.pem" \
  --cert-file "/acme.sh/cert.pem" \
  --ca-file "/acme.sh/ca.pem" \
  --debug

```

luego permisos de ejecucion

```
chmod +x get-cert.sh
```

En ./certs/ vas a encontrar los siguientes archivos

fullchain.pem → para SSLCertificateFile
privkey.pem → para SSLCertificateKeyFile




