# Configure Application Perspective for Robotshop application

In this tutorial we will be configuring an Application Perspective for the Robotshop application

We define the following scenario
- We have a linux virtual machine (in our case a RHEL 8)
- We already have a INSTANA tenant
- We already have deployed Robotshop
- We already deploy the Instana agent

Configure the Application Perspective
=

1. Connect to the Instana UI and select Applications

2. Select Add and then New Application Perspective

3. Complete the following information
    - Select Services or Endpoints
    - Select in Filter, HOST, Name and then the name of the virtual machine where RobotShop is already deployed
    - The wizard will discover the services that are running and show it in the screen (services like for example catalogue, cities and so on)
    - Click Next
    - Give a name to this App Perspective and select ALL Calls 

4. Wait a couple of minutes and you will see the data populated 
