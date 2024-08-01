Despliegue de Robotshop en una maquina linux


# Robotshop deployment in a Linux virtual machine

In this tutorial we will be configuring an application using docker in a linux virtual machine

We define the following scenario
- We have a linux virtual machine (in our case a RHEL 8)
- We already have a INSTANA tenant

Configure the virtual machine
=

1. Connect the virtual machine using ssh. In our example we have a SSH KEY

       ssh -i pem_ibmcloudvsi_download.pem 169.55.98.38 -p 2223 -l itzuser
   
2. Install the yum-utils package (which provides the yum-config-manager utility) and set up the repository

        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

   
3. Install Docker Engine, containerd, and Docker Compose:

        sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   
4. Start docker

        sudo systemctl start docker

5. test docker

6. 
