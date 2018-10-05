#!/bin/bash
set -e

# Copy SSH Key
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./credentials/id_rsa.pub ubuntu@127.0.0.1:~/id_rsa.pub
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./credentials/id_rsa ubuntu@127.0.0.1:~/id_rsa

# Copy configuration files
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./conf/postgres.yml ubuntu@127.0.0.1:~/postgres.yml
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./conf/post_setup_cluster.sh ubuntu@127.0.0.1:~/post_setup_cluster.sh
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./conf/etcd_peers ubuntu@127.0.0.1:~/etcd_peers
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./conf/start_etcd.sh ubuntu@127.0.0.1:~/start_etcd.sh
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./conf/glances.conf ubuntu@127.0.0.1:~/glances.conf

# Create Image script
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./create-image.sh ubuntu@127.0.0.1:~/create-image.sh
ssh -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -p 8022 ubuntu@127.0.0.1 "chmod +x ~/create-image.sh; ./create-image.sh;"

if [ ! -d "build" ]; then
  mkdir build
fi


scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ubuntu@127.0.0.1:~/ubuntu-postgresql.iso build/ubuntu-postgresql.iso

echo "Successfully generated ubuntu-postgresql.iso"