#!/bin/bash

PRISM_IP="192.168.1.20" # This is your cluster virtual IP address.
PRISM_USERNAME="admin"
PRISM_PASSWORD="supersecretpassword" # Prism password
CVM_USERNAME="nutanix" # Default Nutanix CVM Username
CVM_PASSWORD="nutanix/4u" # Default Nutanix CVM Passowrd
VM_NAME="Reference VM - Windows Server 2019" # The name of the VM you want to extract it is disk into a QCOW2 image
GOLDEN_IMAGE_NAME="Windows_Server_2019_Server_Golden_Image" # The name of the target QCOW2 image
TARGET_STORAGE_CONTAINER="default-container-65802440092108" # Name of the storage contaiiner you need to use to store the QCOW2 image

# Get the Virtual Machine UUID
JQ_FILTER=".entities[] | select(.name==\"$VM_NAME\").uuid"
VM_UUID=`curl -s --insecure --user "$PRISM_USERNAME:$PRISM_PASSWORD" --request GET "https://$PRISM_IP:9440/PrismGateway/services/rest/v2.0/vms" | jq -r "$JQ_FILTER"`

# Get the vDisk NFS Path
JQ_FILTER=".entities[] | select(.attached_vm_uuid==\"$VM_UUID\" and .disk_address==\"scsi.0\").nutanix_nfsfile_path"
NFSFILE_PATH=`curl -s --insecure --user "$PRISM_USERNAME:$PRISM_PASSWORD" --request GET "https://$PRISM_IP:9440/PrismGateway/services/rest/v2.0/virtual_disks" | jq -r "$JQ_FILTER"`

# Build the command to run
COMMAND="/usr/local/nutanix/bin/qemu-img convert -c -p nfs://127.0.0.1$NFSFILE_PATH -O qcow2 nfs://127.0.0.1/$TARGET_STORAGE_CONTAINER/$GOLDEN_IMAGE_NAME.qcow2"

# /usr/local/nutanix/bin/qemu-img convert -c -p nfs://127.0.0.1/kafka_data/.acropolis/vmdisk/99791631-b826-47ac-90a0-a82f5c03389f -O qcow2 nfs://127.0.0.1/default-container-65802440092108/Windows_10_Golden_Image.qcow2
# Run the command on the CVM
sshpass -p $CVM_PASSWORD ssh -o "StrictHostKeyChecking=no" $CVM_USERNAME@$PRISM_IP $COMMAND

# Prepare the URL that will be copied
URL="nfs://$PRISM_IP/$TARGET_STORAGE_CONTAINER/$GOLDEN_IMAGE_NAME.qcow2"
echo "Please use the following URL to upload the image to Prism Central:"
echo $URL

# To-Do: Delete the image from th NFS share
