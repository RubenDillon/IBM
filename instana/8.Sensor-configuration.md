# Sensors configuration

In this tutorial we will introduce how to configure specific sensors in the VM


Python sensor configuration
=

When you review your agent and found the following message "The instana package is not installed in this Python application, or the instana package cannot announce itself to the host agent, for example due to networking issues." and CODE "python_sensor_not_installed"

1. Connect the virtual machine using ssh. In our example we have a SSH KEY

       ssh -i pem_ibmcloudvsi_download.pem 169.55.98.38 -p 2223 -l itzuser
   
2. Install the python 38

       yum install python38
   
3. Deploy the sensor

        sudo pip3 install git+https://github.com/instana/python-sensor@v2.5.1
   
4.  fsafsd



## Nginx sensor configuration

1. Determinar version de nginx ejecutando el siguiente comando.

	Comando:

		nginx -v

   	Resultado:

	  	root@ubuntu-server:~# nginx -v
		nginx version: nginx/1.18.0 (Ubuntu)

2. Descargar el binario correspondiente a la version de nginx instalada.

	- Ingresar a la siguiente ruta:

 	https://www.ibm.com/docs/en/instana-observability/current?topic=nginx-distributed-tracing-binaries

	- Identificar la version del binario correspondiente.

	![image](https://github.com/juan-conde-21/Nginx-Tracing/assets/13276404/3a71eb24-5b91-4ba2-a02b-6aa91809a9c9)

	- Descargar el archivo zip correspondiente a la distribucion de Linux utilizado.

	![image](https://github.com/juan-conde-21/Nginx-Tracing/assets/13276404/b006457e-8b7c-4d7a-9f72-880165970348)

	![image](https://github.com/juan-conde-21/Nginx-Tracing/assets/13276404/be183c5d-cab0-4c8c-9a8c-c8b6f6fe1f63)

   	Para autenticarse en el repositorio de Instana utilizar como usuario "_" (guión bajo) y contraseña el agent key de Instana (utilizado para la descarga del agente) .

 	![image](https://github.com/juan-conde-21/Nginx-Tracing/assets/13276404/b910a8f3-bab3-4746-b8ce-88a0fdf8085b)


3. Subir el archivo zip descargado en el paso anterior al servidor nginx y descomprimir. 

	Comando:

		unzip linux-amd64-glibc-nginx-{nginx-version}.zip

	Ejemplo de ejecucion:

		root@ubuntu-server:~# unzip linux-amd64-glibc-nginx-1.18.0.zip 
		Archive:  linux-amd64-glibc-nginx-1.18.0.zip
		  inflating: glibc-libinstana_sensor.so  
		  inflating: glibc-nginx-1.18.0-ngx_http_ot_module.so  
		root@ubuntu-server:~# ls -lart
		total 3924
		-rw-r--r--  1 root root     161 Dec  5  2019 .profile
		-rw-r--r--  1 root root    3106 Dec  5  2019 .bashrc
		-rwxr-xr-x  1 root root 1147832 Jan 22 16:24 glibc-nginx-1.18.0-ngx_http_ot_module.so
		-rwxr-xr-x  1 root root 1783768 Jan 22 16:24 glibc-libinstana_sensor.so
		-rwxrwxr-x  1 root root 1054316 Jan 22 16:29 linux-amd64-glibc-nginx-1.18.0.zip
		drwxr-xr-x 19 root root    4096 Mar 15 03:01 ..
		drwx------  2 root root    4096 Mar 15 03:01 .ssh
		drwx------  3 root root    4096 Mar 15 03:01 snap
		drwx------  4 root root    4096 Mar 15 03:38 .


4. Agregar permisos de ejecucion sobre los binarios descargados

	Comando:

		chmod 775 glibc-*

	Resultado:

		root@ubuntu-server:~# chmod 775 glibc-*
		root@ubuntu-server:~# ls -lart
		total 3924
		-rw-r--r--  1 root root     161 Dec  5  2019 .profile
		-rw-r--r--  1 root root    3106 Dec  5  2019 .bashrc
		-rwxrwxr-x  1 root root 1147832 Jan 22 16:24 glibc-nginx-1.18.0-ngx_http_ot_module.so
		-rwxrwxr-x  1 root root 1783768 Jan 22 16:24 glibc-libinstana_sensor.so		

5. Modificar los nombres de las librerias descargadas.

	Comando:

		mv glibc-nginx-{nginx-version}-ngx_http_ot_module.so ngx_http_opentracing_module.so
		mv glibc-libinstana_sensor.so libinstana_sensor.so

	Resultado:

		root@ubuntu-server:~# mv glibc-nginx-1.18.0-ngx_http_ot_module.so ngx_http_opentracing_module.so
		root@ubuntu-server:~# mv glibc-libinstana_sensor.so libinstana_sensor.so
		root@ubuntu-server:~# ls -lart
		total 3924
		-rw-r--r--  1 root root     161 Dec  5  2019 .profile
		-rw-r--r--  1 root root    3106 Dec  5  2019 .bashrc
		-rwxrwxr-x  1 root root 1147832 Jan 22 16:24 ngx_http_opentracing_module.so
		-rwxrwxr-x  1 root root 1783768 Jan 22 16:24 glibc-libinstana_sensor.so


6. Identificar el path de modulos de nginx.

	Comando:

		nginx -V

	Identificar la ubicacion de la ruta de los modulos de nginx:
	
		--modules-path=

	Resultado:

	![image](https://github.com/juan-conde-21/Nginx-Tracing/assets/13276404/b6d79588-3fc3-4ca8-b21d-5a5602443542)

	*Nota: esta ruta depende de la configuración aplicada a nginx, para este ejemplo se encuentra en la ruta "/usr/lib/nginx/modules"

7. Crear la carpeta de modulos en caso no existir. (Opcional)

	Comando:
	
	 	mkdir /usr/lib/nginx
		mkdir /usr/lib/nginx/modules

8. Copiar los binarios en la carpeta de modulos de nginx, para este ejemplo esta en la ruta "/usr/lib/nginx/modules"

	Comando:

	   cp ngx_http_opentracing_module.so libinstana_sensor.so /usr/lib/nginx/modules
	   ls -lart /usr/lib/nginx/modules

   	Resultado:

		root@ubuntu-server:~# cp ngx_http_opentracing_module.so libinstana_sensor.so /usr/lib/nginx/modules
		root@ubuntu-server:~# ls -lart /usr/lib/nginx/modules
		total 3216
		-rw-r--r-- 1 root root  180792 Nov 10  2022 ngx_stream_module.so
		-rw-r--r-- 1 root root  108168 Nov 10  2022 ngx_mail_module.so
		-rw-r--r-- 1 root root   23552 Nov 10  2022 ngx_http_xslt_filter_module.so
		-rw-r--r-- 1 root root   27728 Nov 10  2022 ngx_http_image_filter_module.so
		drwxr-xr-x 3 root root    4096 Mar 15 03:11 ..
		drwxr-xr-x 2 root root    4096 Mar 15 03:56 .
		-rwxrwxr-x 1 root root 1147832 Mar 15 03:57 ngx_http_opentracing_module.so
		-rwxrwxr-x 1 root root 1783768 Mar 15 03:57 libinstana_sensor.so

9. Crear el archivo instana-config.json con el nombre del servicio (con este nombre sera reconocido en Instana )  y los datos del agente Instana.

	Comando:

		vi /etc/instana-config.json

   	Contenido del archivo instana-config.json :

  		{
		  "service": "nginxtracing_nginx",
		  "agent_host": "127.0.0.1",
		  "agent_port": 42699,
		  "max_buffered_spans": 1000
		}

10. Modificar el archivo de configuracion de nginx agregando los modulos y variables para habilitar el tracing. Para este ejemplo la ruta de modulos es la siguiente "/usr/lib/nginx/modules"

	Comando:

		cd /etc/nginx
		vi nginx.conf

	Agregar las siguientes lineas de configuracion:

		load_module /usr/lib/nginx/modules/ngx_http_opentracing_module.so; 
			
		env INSTANA_SERVICE_NAME;
		env INSTANA_AGENT_HOST;
		env INSTANA_AGENT_PORT;
		env INSTANA_MAX_BUFFERED_SPANS;
		env INSTANA_DEV;

		#Dentro de la sección http
		
		opentracing_load_tracer /usr/lib/nginx/modules/libinstana_sensor.so /etc/instana-config.json;
		opentracing_propagate_context;


	Ejemplo del archivo de configuracion modificado:

		load_module /usr/lib/nginx/modules/ngx_http_opentracing_module.so;
		
		env INSTANA_SERVICE_NAME;
		env INSTANA_AGENT_HOST;
		env INSTANA_AGENT_PORT;
		env INSTANA_MAX_BUFFERED_SPANS;
		env INSTANA_DEV;
		
		user www-data;
		worker_processes auto;
		pid /run/nginx.pid;
		include /etc/nginx/modules-enabled/*.conf;
		
		events {
		        worker_connections 768;
		        # multi_accept on;
		}
		
		http {
		
		        opentracing_load_tracer /usr/lib/nginx/modules/libinstana_sensor.so /etc/instana-config.json;
		        opentracing_propagate_context;
		
		        ##
		        # Basic Settings
		        ##
		
11. Reiniciar los servicios de nginx para aplicar los cambios:

	Comando:

		systemctl restart nginx
		systemctl status nginx

	Resultado:

		root@ubuntu-server:/etc/nginx# systemctl restart nginx
		root@ubuntu-server:/etc/nginx# systemctl status nginx
		● nginx.service - A high performance web server and a reverse proxy server
		     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
		     Active: active (running) since Fri 2024-03-15 04:10:36 UTC; 6s ago
		       Docs: man:nginx(8)
		    Process: 3711 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
		    Process: 3713 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
		   Main PID: 3716 (nginx)
		      Tasks: 5 (limit: 9511)
		     Memory: 3.6M
		     CGroup: /system.slice/nginx.service
		             ├─3716 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
		             ├─3717 nginx: worker process
		             └─3718 nginx: worker process
		
		Mar 15 04:10:36 ubuntu-server systemd[1]: Starting A high performance web server and a reverse proxy server...
		Mar 15 04:10:36 ubuntu-server nginx[3711]: Instana C++ Sensor v1.8.3 has been loaded.
		Mar 15 04:10:36 ubuntu-server nginx[3713]: Instana C++ Sensor v1.8.3 has been loaded.
		Mar 15 04:10:36 ubuntu-server systemd[1]: Started A high performance web server and a reverse proxy server.

12. Verificar en la consola de Instana, buscar por el nombre del servicio colocado en el archivo instana-config.json

![image](https://github.com/juan-conde-21/Nginx-Tracing/assets/13276404/f8d4aad3-6f8a-4040-92da-e053c4012a2a)





