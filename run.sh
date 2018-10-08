#!/bin/bash
set -e

# Copy SSH Key
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./credentials/id_rsa.pub ubuntu@127.0.0.1:~/id_rsa.pub
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./credentials/rsync ubuntu@127.0.0.1:~/rsync
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./credentials/rsync.pub ubuntu@127.0.0.1:~/rsync.pub

# Copy configuration files
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./conf/glances.conf ubuntu@127.0.0.1:~/glances.conf

# Copy PostgreSQL Config files
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./conf/postgresql.conf ubuntu@127.0.0.1:~/postgresql.conf
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./conf/pg_hba.conf ubuntu@127.0.0.1:~/pg_hba.conf
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./conf/recovery.conf ubuntu@127.0.0.1:~/recovery.conf


# Create Image script
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./create-image.sh ubuntu@127.0.0.1:~/create-image.sh
ssh -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -p 8022 ubuntu@127.0.0.1 "chmod +x ~/create-image.sh; ./create-image.sh;"

if [ ! -d "build" ]; then
  mkdir build
fi


scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ubuntu@127.0.0.1:~/ubuntu-postgresql.iso build/ubuntu-postgresql.iso

echo "Successfully generated ubuntu-postgresql.iso"