# Arquitectura Distribuida con 3 VM en RHEL 9: Front‑end, API y Base de Datos

Este documento describe cómo configurar **tres** máquinas virtuales en RHEL 9 para un servicio de consulta de clientes:

* **VM1 (Front‑end)**

  * IP pública: `150.239.108.78`
  * IP privada: `10.241.0.12`
  * Apache sirve la página HTML en puerto **8080**

* **VM2 (API)**

  * IP privada: `10.241.0.8`
  * Apache+PHP sirve la API en puerto **8080**, consulta a VM3

* **VM3 (MySQL)**

  * IP privada: `10.241.0.10`
  * MariaDB/MySQL aloja la base de datos `clientes_db` en puerto **8080**

---

## 🖥️ Diagrama de Flujo

```text
[Usuario Internet]
    ↓ (150.239.108.78:8080)
[VM1: Front‑end Apache]
    ↓ (10.241.0.8:8080)
[VM2: API Apache+PHP]
    ↓ (10.241.0.10:8080)
[VM3: MariaDB (MySQL)]
```

---

## 🔧 VM3: Servidor MySQL (Puerto 8080)

1. **Instalación y arranque**

   ```bash
   sudo dnf install mariadb-server -y
   sudo systemctl enable --now mariadb
   ```

2. **Configurar MariaDB en puerto 8080**

   * Opción A: Editar `/etc/my.cnf`

     ```bash
     sudo sed -i '/^\[mysqld\]/a port=8080' /etc/my.cnf
     ```
   * Opción B: Crear `/etc/my.cnf.d/10-server-port.cnf`

     ```bash
     sudo tee /etc/my.cnf.d/10-server-port.cnf << 'EOF'
     [mysqld]
     port=8080
     EOF
     ```

3. **Abrir puerto en firewall**

   ```bash
   sudo firewall-cmd --add-port=8080/tcp --permanent
   sudo firewall-cmd --reload
   ```

4. **Reiniciar y verificar**

   ```bash
   sudo systemctl restart mariadb
   ss -tuln | grep 8080
   # debe mostrar '0.0.0.0:8080'
   ```

5. **Crear base de datos, tabla y usuario**

   ```bash
   mysql -u root -P 8080 -p << 'SQL'
   CREATE DATABASE IF NOT EXISTS clientes_db;
   USE clientes_db;
   CREATE TABLE IF NOT EXISTS clientes (
     IdCliente INT PRIMARY KEY,
     Nombre VARCHAR(100),
     Direccion VARCHAR(255),
     Pais VARCHAR(100)
   );

   CREATE USER IF NOT EXISTS 'api_user'@'10.241.0.8' IDENTIFIED BY 'secure_password';
   GRANT SELECT ON clientes_db.* TO 'api_user'@'10.241.0.8';
   FLUSH PRIVILEGES;

   INSERT INTO clientes VALUES
     (1,'Juan Pérez','Calle Falsa 123','Argentina'),
     (2,'María Gómez','Av. Siempre Viva 456','Chile')
   ON DUPLICATE KEY UPDATE Nombre=VALUES(Nombre);
   SQL
   ```

---

## 🛠️ VM2: Servidor de API (Apache + PHP)

1. **Instalación**

   ```bash
   sudo dnf install httpd php php-mysqlnd -y
   sudo systemctl enable --now httpd
   sudo firewall-cmd --add-port=8080/tcp --permanent
   sudo firewall-cmd --reload
   ```

2. **Configurar Apache en puerto 8080**

   ```bash
   sudo sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
   sudo systemctl restart httpd
   ```

3. **Desplegar API**

   ```bash
   sudo mkdir -p /var/www/html/api
   sudo chown -R apache:apache /var/www/html/api
   cat << 'EOF' > /var/www/html/api/clientes.php
   <?php
   header('Access-Control-Allow-Origin: *');
   header('Access-Control-Allow-Methods: GET, OPTIONS');
   header('Access-Control-Allow-Headers: Content-Type');
   header('Content-Type: application/json');

   if (\$_SERVER['REQUEST_METHOD'] === 'OPTIONS') exit;

   \$id = intval(\$_GET['id'] ?? 0);
   if (\$id <= 0) {
     http_response_code(400);
     echo json_encode(['error' => 'ID inválido']);
     exit;
   }

   // Conectar a MariaDB en VM3 puerto 8080 con usuario dedicado
   \$conn = new mysqli('10.241.0.10', 'api_user', 'secure_password', 'clientes_db', 8080);
   if (\$conn->connect_error) {
     http_response_code(500);
     echo json_encode(['error' => 'DB Conexión fallida']);
     exit;
   }

   \$stmt = \$conn->prepare('SELECT Nombre, Direccion, Pais FROM clientes WHERE IdCliente = ?');
   \$stmt->bind_param('i', \$id);
   \$stmt->execute();
   \$res = \$stmt->get_result();

   if (\$row = \$res->fetch_assoc()) {
     echo json_encode(\$row);
   } else {
     http_response_code(404);
     echo json_encode(['error' => 'Cliente no encontrado']);
   }

   \$stmt->close();
   \$conn->close();
   ?>
   EOF
   ```

4. **Verificar**

   ```bash
   curl -i "http://localhost:8080/api/clientes.php?id=1"
   ```

---

## 🖥️ VM1: Servidor Front‑end (Apache)

1. **Instalación**

   ```bash
   sudo dnf install httpd -y
   sudo systemctl enable --now httpd
   sudo firewall-cmd --add-port=8080/tcp --permanent
   sudo firewall-cmd --reload
   ```

2. **Configurar Apache en puerto 8080**

   ```bash
   sudo sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
   sudo systemctl restart httpd
   ```

3. **Página HTML**
   Guarda como `/var/www/html/index.html`:

   ```html
   <!DOCTYPE html>
   <html lang="es">
   <head>
     <meta charset="UTF-8">
     <title>Buscar Cliente</title>
     <style>
       body { font-family: Arial, sans-serif; margin: 20px; }
       #resultado { margin-top: 10px; color: #333; }
       #resultado.error { color: red; }
     </style>
   </head>
   <body>
     <h1>Consulta de Cliente</h1>
     <input type="number" id="idCliente" placeholder="ID cliente">
     <button id="buscarBtn">Buscar</button>
     <div id="resultado"></div>

     <script>
       document.getElementById('buscarBtn').addEventListener('click', async () => {
         const id = document.getElementById('idCliente').value.trim();
         const out = document.getElementById('resultado');
         if (!id) {
           out.textContent = 'Ingresa un ID válido.';
           out.classList.add('error');
           return;
         }
         out.textContent = 'Buscando...';
         out.classList.remove('error');

         try {
           const res = await fetch(`http://10.241.0.8:8080/api/clientes.php?id=${id}`);
           const data = await res.json();
           if (!res.ok) {
             out.textContent = data.error;
             out.classList.add('error');
           } else {
             out.innerHTML =
               `<p><strong>Nombre:</strong> ${data.Nombre}</p>` +
               `<p><strong>Dirección:</strong> ${data.Direccion}</p>` +
               `<p><strong>Pais:</strong> ${data.Pais}</p>`;
           }
         } catch (err) {
           out.textContent = 'Error de conexión con la API.';
           out.classList.add('error');
         }
       });
     </script>
   </body>
   </html>
   ```

---

## 📝 Scripts de Automatización

### `setup_vm3.sh` (MySQL)

```bash
#!/bin/bash
sudo dnf install mariadb-server -y
sudo systemctl enable --now mariadb
# Configurar puerto 8080 en /etc/my.cnf.d
sudo tee /etc/my.cnf.d/10-server-port.cnf << 'EOF'
[mysqld]
port=8080
EOF
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl restart mariadb
mysql -u root -P 8080 -p << 'SQL'
CREATE DATABASE IF NOT EXISTS clientes_db;
USE clientes_db;
CREATE TABLE IF NOT EXISTS clientes (IdCliente INT PRIMARY KEY, Nombre VARCHAR(100), Direccion VARCHAR(255), Pais VARCHAR(100));
CREATE USER IF NOT EXISTS 'api_user'@'10.241.0.8' IDENTIFIED BY 'secure_password';
GRANT SELECT ON clientes_db.* TO 'api_user'@'10.241.0.8';
FLUSH PRIVILEGES;
INSERT INTO clientes VALUES (1,'Juan Pérez','Calle Falsa 123','Argentina'),(2,'María Gómez','Av. Siempre Viva 456','Chile') ON DUPLICATE KEY UPDATE Nombre=VALUES(Nombre);
SQL
```

### `setup_vm2.sh` (API)

```bash
#!/bin/bash
sudo dnf install httpd php php-mysqlnd -y
sudo systemctl enable --now httpd
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
sudo sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
sudo systemctl restart httpd
sudo mkdir -p /var/www/html/api && sudo chown -R apache:apache /var/www/html/api
cat << 'EOF' > /var/www/html/api/clientes.php
<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
if (\$_SERVER['REQUEST_METHOD']==='OPTIONS') exit;
\$id = intval(\$_GET['id'] ?? 0);
if (\$id<=0) { http_response_code(400); echo json_encode(['error'=>'ID inválido']); exit; }
\$conn = new mysqli('10.241.0.10','api_user','secure_password','clientes_db',8080);
if (\$conn->connect_error) { http_response_code(500); echo json_encode(['error'=>'DB Conexión fallida']); exit; }
\$stmt = \$conn->prepare('SELECT Nombre, Direccion, Pais FROM clientes WHERE IdCliente=?');
\$stmt->bind_param('i', \$id);
\$stmt->execute();
\$res = \$stmt->get_result();
if (\$row=\$res->fetch_assoc()) echo json_encode(\$row);
else { http_response_code(404); echo json_encode(['error'=>'Cliente no encontrado']); }
\$stmt->close(); \$conn->close();
?>
EOF
```

### `setup_vm1.sh` (Front‑end)

```bash
#!/bin/bash
sudo dnf install httpd -y
sudo systemctl enable --now httpd
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
sudo sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
sudo systemctl restart httpd
cat << 'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><title>Buscar Cliente</title></head>
<body>
  <h1>Consulta de Cliente</h1>
  <input type="number" id="idCliente" placeholder="ID cliente">
  <button onclick="buscar()">Buscar</button>
  <div id="resultado"></div>
<script>
async function buscar(){const id=document.getElementById('idCliente').value;const out=document.getElementById('resultado');out.textContent='Buscando...';try{const res=await fetch(`http://10.241.0.8:8080/api/clientes.php?id=${id}`);const data=await res.json();if(!res.ok)out.textContent=data.error;else out.innerHTML=`Nombre: ${data.Nombre}<br>Dirección: ${data.Direccion}<br>Pais: ${data.Pais}`;}catch(e){out.textContent='Error conexión API';}};
</script>
</body>
</html>
EOF
```

---

## ✅ Resumen Final

* **VM1**: Interfaz pública en `150.239.108.78:8080`.
* **VM2**: API PHP en `10.241.0.8:8080`, usa `api_user` para conectar a MariaDB.
* **VM3**: MariaDB en `10.241.0.10:8080`, base de datos `clientes_db`.

