On Premise in a multinode cluster
=

This document will show how to install Concert in a multinode environemnt based in Red Hat OpenShift

1. Access the github to obtain the yaml to use it for the deployment using the RHOS console

https://github.com/niklaushirt/ibm-aiops-deployer/tree/main?tab=readme-ov-file#22--install-ibm-concert-with-demo-content

```
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#     ________  __  ___   __________    ___         __                        __  _
#    /  _/ __ )/  |/  /  /  _/_  __/   /   | __  __/ /_____  ____ ___  ____ _/ /_(_)___  ____
#    / // __  / /|_/ /   / /  / /     / /| |/ / / / __/ __ \/ __ `__ \/ __ `/ __/ / __ \/ __ \
#  _/ // /_/ / /  / /  _/ /  / /     / ___ / /_/ / /_/ /_/ / / / / / / /_/ / /_/ / /_/ / / / /
# /___/_____/_/  /_/  /___/ /_/     /_/  |_\__,_/\__/\____/_/ /_/ /_/\__,_/\__/_/\____/_/ /_/
#
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------------------------------------"
#  Installing IBM IT Automation Solutoions
#
#  IBM Concert
#
#  ©2025 nikh@ch.ibm.com
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Get a Cluster from TechZone: https://techzone.ibm.com/collection/tech-zone-certified-base-images
#   Type:               VMWare on IBM Cloud / UPI Public
#   Worker node count:  3
#   Flavour:            16x64 ❗ 
#   OpenShift Version:  4.14
#   Storage:            ODF 500GB or Managed NFS - 2TB 
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# Installs:
#
#  - IBM Concert
#  - IBM Concert Demo Content
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
# ---------------------------------------------------------------------------------------------------------------------------------------------------"
---
apiVersion: v1                     
kind: Namespace
metadata:
  name: ibm-installer
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: ibm-install-configuration-concert
  namespace: ibm-installer
immutable: false
data:
  ENTITLED_REGISTRY_KEY: >-
    mñqfkpmbirojmrñvc,erlti549p6820ìkrf-vm,dfkñbp9-------------TOKEN-------------c8geqcubqXXxx4yHALLrwFKQdmuC1-rUGYZkJxDlTeA
data:
  INSTALLATION_CONFIG.yaml: >+
    #*************************************************************************************************************************************************
    #--------------------------------------------------------------------------------------------------------------------------------------
    # Global Configuration
    #--------------------------------------------------------------------------------------------------------------------------------------
    #*************************************************************************************************************************************************

    global_config:
      # --------------------------------------------------------------------------------------------------------------------------------------
      # Passwords and Licenses
      # --------------------------------------------------------------------------------------------------------------------------------------
      # Use this Password for all Instances - do NOT use the "-" character
      global_password: PASSw0rd2019


      environment_name: Demo
      cloud_platform: existing-ocp
      # Set this value to True to accept all licenses
      accept_all_licenses: True
      # Key to decrypt Licenses
      #license_token: NONE


      # --------------------------------------------------------------------------------------------------------------------------------------
      # Pull Registires
      # --------------------------------------------------------------------------------------------------------------------------------------
      entitled_registry: cp.icr.io
      entitled_registry_user: cp
      catalog_image: icr.io/cpopen/ibm-aiops-catalog:latest
      current_supported_aiops_version: v4.10

      # --------------------------------------------------------------------------------------------------------------------------------------
      # Notifications and Cards
      # --------------------------------------------------------------------------------------------------------------------------------------
      # Create Welcome Cards in ibm-aiops
      create_cards: true
      # Create App Menu Items in OCP
      create_ocp_items: true
      # Create Notifications in OCP
      create_ocp_notifications: true
      position_ocp_notifications: BannerBottom
      position_final_ocp_notification: BannerTop


      # --------------------------------------------------------------------------------------------------------------------------------------
      # Passwords and Licenses
      # --------------------------------------------------------------------------------------------------------------------------------------
      # Set this value to True to accept all licenses
      accept_all_licenses: False


    # *************************************************************************************************************************************************
    # -------------------------------------------------------------------------------------------------------------------------------------
    # OpenShift Configuration
    # --------------------------------------------------------------------------------------------------------------------------------------
    # *************************************************************************************************************************************************

    openshift:

    - name: "mycluster"
      ocp_version: "4.15"
      cluster_name: "mycluster"
      domain_name: example.com
      openshift_storage:
      - storage_name: auto-storage
        storage_type: auto
        # Alternatively use
        #storage_name: ibm-roks-storage
        #storage_type: custom
        #ocp_storage_class_file: ibmc-file-gold-gid
        #ocp_storage_class_block: ibmc-block-gold




    #*************************************************************************************************************************************************
    #--------------------------------------------------------------------------------------------------------------------------------------
    # IBM IT AUTOMATION - INSTALLATION Configuration
    #--------------------------------------------------------------------------------------------------------------------------------------
    #*************************************************************************************************************************************************
  
    ibmitautomation:

    # --------------------------------------------------------------------------------------------------------------------------------------
    # IBM CONCERT
    # --------------------------------------------------------------------------------------------------------------------------------------
  
    - project: ibm-concert
      instances:
      - name: ibm-concert
        kind: IBMConcert
        install: true
        
        # ---------------------------------------------------------------------
        # CONCERT REGISTRY
        prod_registry: cp.icr.io
        private_registry_location: cp.icr.io
        prod_user: cp

        # ---------------------------------------------------------------------
        # PROJECT SETTINGS
        project_operator: ibm-concert-operators 
        project_instance: ibm-concert 

        # ---------------------------------------------------------------------
        # CONTAINER RUNTIME
        docker_exe: podman 

        # --------------------------------------------------------------------------------------------------------------------------------------
        # Storage Classes Override for this Instance (see comment below)
        # --------------------------------------------------------------------------------------------------------------------------------------
        #storage_class_file: automatic
        #storage_class_block: automatic


      - name: ibm-concert-demo-content
        kind: IBMConcertDemoContent
        install: true

        # ---------------------------------------------------------------------
        # DEMO CONTENT
        install_demo_content: true
        install_demoapps: true

        # ---------------------------------------------------------------------
        # Create a custom app to show links to all installed IT Automation Products
        create_home_ui: false
      

        # ---------------------------------------------------------------------
        # LDAP
        install_ldap: true
        # ldap domain
        ldap_domain: ibm.com
        # ldap base
        ldap_base: dc=ibm,dc=com
        # LDAP Admin Password (OVERRIDES GLOBAL PASSWORD)
        #ldap_admin_password: CHANGEME
        # LDAP Password for all Users (OVERRIDES GLOBAL PASSWORD)
        #ldap_user_password: CHANGEME
        # ldap namespace
        ldap_namespace: openldap
        # Integrate AIOps Login with OpenLDAP 
        ldap_register: true
        # Integrate OpenShift Login with OpenLDAP
        integrate_ocp_openldap: true



  INSTALL_REPO: 'https://github.com/niklaushirt/ibm-aiops-deployer.git -b main'
















# ------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------
# DO NOT MODIFY BELOW
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------
---
kind: ServiceAccount
apiVersion: v1
metadata:
  name: ibm-installer-admin
  namespace: ibm-installer
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ibm-installer-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: ibm-installer-admin
    namespace: ibm-installer
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ibm-installer-default-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: default
    namespace: ibm-installer
---
apiVersion: batch/v1
kind: Job
metadata:
  name: ibm-install-concert
  namespace: ibm-installer
  labels:
   aiops-type: data-load-job
spec:

  template:
    metadata:
      labels:
        app: ibm-concert
    spec:
      serviceAccount: ibm-installer-admin
      containers:
        - name: install
          image: quay.io/niklaushirt/ibm-aiops-tools:2.3
          imagePullPolicy: IfNotPresent
          securityContext:
            privileged: true
            allowPrivilegeEscalation: true
            runAsUser: 0
            capabilities:
              add: 
              - ALL
          resources:
            requests:
              memory: "64Mi"
              cpu: "150m"
            limits:
              memory: "2024Mi"
              cpu: "1200m"
          command:
            - /bin/sh
            - -c
            - |
              #!/bin/bash
              #set -x
              echo "***************************************************************************************************************************************************"
              echo "***************************************************************************************************************************************************"
              echo "                                                                                                                                                   "
              echo " 🚀 Install IBM Concert                                                                                                                                                  "
              echo "                                                                                                                                                   "
              echo "***************************************************************************************************************************************************"
              echo "***************************************************************************************************************************************************"
              echo "  "
              echo "  "
              echo "  ⏳ INSTALLATION START TIMESTAMP: $(date)"
              echo ""
              echo "------------------------------------------------------------------------------------------------------------------------------"
              echo " 📥 Housekeeping"
              #oc delete ConsoleNotification --all>/dev/null 2>/dev/null 
              oc delete job  -n ibm-installer --ignore-not-found $(oc get job -n ibm-installer|grep load-|awk '{print$1}'):-notfound  --ignore-not-found>/dev/null 2>/dev/null 
              oc delete pod  -n ibm-installer $(oc get po -n ibm-installer|grep load-|awk '{print$1}'):-notfound  --ignore-not-found>/dev/null 2>/dev/null 
              echo ""
              echo ""

              echo "------------------------------------------------------------------------------------------------------------------------------"
              echo " 🚀 Getting Installation source from GitHub"
              echo "------------------------------------------------------------------------------------------------------------------------------"
              echo "   📥 Clone Repo $INSTALL_REPO"
              git clone $INSTALL_REPO
              cd ibm-aiops-deployer

              echo ""
              echo ""
              echo "------------------------------------------------------------------------------------------------------------------------------"
              echo "   🔎 This Repo includes those latestet Commits"
              git log|head -n 17
              echo ""
              echo ""

              echo "------------------------------------------------------------------------------------------------------------------------------"
              echo " 📝 Config File"         
              cat /tmp/config-file/INSTALLATION_CONFIG.yaml


              echo "------------------------------------------------------------------------------------------------------------------------------"
              echo " 🚀 Starting Installation"
              echo "------------------------------------------------------------------------------------------------------------------------------"
              echo ""

              # echo "------------------------------------------------------------------------------------------------------------------------------"
              # echo " 🚀 Prepare Ansible"
              #pip -q install openshift pyyaml kubernetes
              #apt update && apt install -fy python3-kubernetes python3-openshift
              # echo ""
              # echo ""


              echo "------------------------------------------------------------------------------------------------------------------------------"
              echo " 🚀 Launching Ansible Playbook"
              export ANSIBLE_LOG_PATH=/tmp/ansible.log
              ansible-playbook ./ansible/ibm-itautomation-products-install.yaml -e "config_file_path=/tmp/config-file/INSTALLATION_CONFIG.yaml" -e cp_entitlement_key=$ENTITLED_REGISTRY_KEY
              echo ""
              echo ""

              echo "------------------------------------------------------------------------------------------------------------------------------"
              echo "  ⏳ INSTALLATION END TIMESTAMP: $(date)"
              echo ""


              echo "------------------------------------------------------------------------------------------------------------------------------"
              echo " 🚀 Finalize Installation"
              ./tools/90_finalizeInstallation.sh
              echo ""

              while true
              do
                sleep 1000
              done


          env:
          - name: INSTALL_REPO
            valueFrom:
              configMapKeyRef:
                name: ibm-install-configuration-concert
                key: INSTALL_REPO
          - name: ENTITLED_REGISTRY_KEY
            valueFrom:
              configMapKeyRef:
                name: ibm-install-configuration-concert
                key: ENTITLED_REGISTRY_KEY
                optional: true
          volumeMounts:
            - name: config-file
              mountPath: /tmp/config-file
      volumes:
        - name: config-file
          configMap:
            name: ibm-install-configuration-concert
            items:
            - key: INSTALLATION_CONFIG.yaml
              path: INSTALLATION_CONFIG.yaml
      restartPolicy: Never
  backoffLimit: 500
  ```

  
