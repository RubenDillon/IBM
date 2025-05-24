# Crear y Usar una API Simple con MySQL, PHP y Apache en RHEL

Este documento describe paso a paso cómo crear y usar una API simple que se comunica con una base de datos MySQL, todo dentro de una máquina virtual con Red Hat Enterprise Linux (RHEL), Apache y PHP. La API permite consultar datos de clientes desde una página web alojada en el mismo servidor Apache.

---

## ⚙️ Requisitos Previos

* RHEL 8 o superior
* Acceso root o sudo
* Conexión a Internet para instalar paquetes

---

## 🔧 Paso 1: Instalar Apache, MySQL y PHP

```bash
sudo dnf install httpd mariadb-server php php-mysqlnd -y
sudo systemctl enable --now httpd mariadb
```

---

## 🛠️ Paso 2: Configurar MySQL

```bash
sudo mysql_secure_installation
```

Luego, ingresa a MySQL para crear la base de datos y la tabla:

```bash
mysql -u root -p
```

Dentro de MySQL:

```sql
CREATE DATABASE clientes_db;
USE clientes_db;

CREATE TABLE clientes (
  IdCliente INT PRIMARY KEY,
  Nombre VARCHAR(100),
  Direccion VARCHAR(255),
  Correo VARCHAR(100)
);

INSERT INTO clientes VALUES (1, 'Juan Pérez', 'Calle Falsa 123', 'juan@example.com');
INSERT INTO clientes VALUES (2, 'María Gómez', 'Av. Siempre Viva 456', 'maria@example.com');
```

---

## 📄 Paso 3: Crear la Página Web (Frontend)

Guardar en: `/var/www/html/index.html`

```html
<!DOCTYPE html>
<html>
<head>
  <title>Buscar Cliente</title>
  <script>
    async function buscarCliente() {
      const id = document.getElementById("idCliente").value;
      const response = await fetch(`api.php?id=${id}`);
      const data = await response.json();
      document.getElementById("resultado").innerHTML =
        data.error ? data.error :
        `Nombre: ${data.Nombre}<br>Dirección: ${data.Direccion}<br>Correo: ${data.Correo}`;
    }
  </script>
</head>
<body>
  <h1>Consulta de Cliente</h1>
  <input type="number" id="idCliente" placeholder="Ingrese ID del cliente">
  <button onclick="buscarCliente()">Buscar</button>
  <div id="resultado"></div>
</body>
</html>
```

---

## 🚀 Paso 4: Crear la API en PHP (Backend)

Guardar en: `/var/www/html/api.php`

```php
<?php
$host = 'localhost';
$db = 'clientes_db';
$user = 'root';
$pass = ''; // cambiar por la contraseña correspondiente

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
  die(json_encode(["error" => "Error de conexión a la base de datos."]));
}

$id = intval($_GET['id']);
$sql = "SELECT * FROM clientes WHERE IdCliente = $id";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
  echo json_encode($result->fetch_assoc());
} else {
  echo json_encode(["error" => "Cliente no encontrado."]);
}

$conn->close();
?>
```

---

## 🔄 Flujo de Funcionamiento

1. El usuario accede a `http://<IP_VM>/index.html`
2. Ingresa un ID de cliente
3. La página usa JavaScript para consultar `api.php?id=1`
4. La API consulta MySQL y devuelve un JSON
5. La página muestra los datos del cliente

---

## 📊 Resultado Esperado

Una aplicación web sencilla que permite consultar información de clientes almacenada en una base de datos MySQL, usando una API creada con PHP, todo dentro del mismo servidor Apache en RHEL.

---

📅 Ideal para workshops, pruebas de concepto y aprendizaje de arquitectura cliente-servidor con herramientas comunes y de código abierto.
