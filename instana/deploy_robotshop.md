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

       sudo docker run hello-world

6. Deploy git in the virtual machine

       sudo yum install git

7. Clone the repository to the virtual machine

       git clone https://github.com/instana/robot-shop.git

8. Deploy the application

       sudo docker compose pull

9. Run the application

       sudo docker compose up

10. Fire up some load

       docker compose -f docker-compose.yaml -f docker-compose-load.yaml up

11. xxy
