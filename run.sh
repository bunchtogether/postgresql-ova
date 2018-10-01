#!/bin/bash
set -e

# Copy SSH Key
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./credentials/id_rsa.pub ubuntu@127.0.0.1:~/id_rsa.pub
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./credentials/id_rsa ubuntu@127.0.0.1:~/id_rsa

# Create Image script
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./create-image.sh ubuntu@127.0.0.1:~/create-image.sh
ssh -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -p 8022 ubuntu@127.0.0.1 "chmod +x ~/create-image.sh; ./create-image.sh;"

if [ ! -d "build" ]; then
  mkdir build
fi

scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ubuntu@127.0.0.1:~/ubuntu-backpack-biblio.iso build/ubuntu-postgresql.iso

echo "Successfully generated ubuntu-postgresql.iso"