#!/bin/bash
set -e

# Copy SSH Key
scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ./credentials/id_rsa ubuntu@127.0.0.1:~/id_rsa
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
else
  rm -rf build/*
fi

scp -i ./credentials/ubuntu_vm_id_rsa -o StrictHostKeyChecking=no -P 8022 ubuntu@127.0.0.1:~/ubuntu-postgresql.iso build/ubuntu-postgresql.iso

echo "Successfully generated ubuntu-postgresql.iso"

export DIRECTORY=$(pwd)
export VMRUN=/Applications/VMware\ Fusion.app/Contents/Library/vmrun
export VERSION=1.0.1
export OVF_TOOL=/Applications/VMware\ Fusion.app/Contents/Library/VMware\ OVF\ Tool/ovftool
export BUILD_NAME=PostgreSQL.$VERSION
export VM_DIRECTORY=~/Documents/Virtual\ Machines.localized
export BASELINE=$VM_DIRECTORY/OVA\ Baseline.vmwarevm/OVA\ Baseline.vmx
export OUTPUT=$VM_DIRECTORY/$BUILD_NAME.vmwarevm/$BUILD_NAME.vmx
export ISO_PATH=$DIRECTORY/build/ubuntu-postgresql.iso
export OVA_PATH=$DIRECTORY/build/PostgreSQL.$VERSION.ova

rm -rf ~/Documents/Virtual\ Machines.localized/$BUILD_NAME.vmwarevm
mkdir ~/Documents/Virtual\ Machines.localized/$BUILD_NAME.vmwarevm

"$VMRUN" -T ws clone "$BASELINE" "$OUTPUT" -cloneName=$BUILD_NAME full

cat "$OUTPUT" | sed '/^ide/d' > "$OUTPUT.2"
bash -c "cat >> \"$OUTPUT.2\"" <<EOL
ide0:0.present = "TRUE"
ide0:0.fileName = "$ISO_PATH"
ide0:0.deviceType = "cdrom-image"
ide0:0.startConnected = "TRUE"
EOL
mv "$OUTPUT.2" "$OUTPUT"

"$VMRUN" -T ws start "$OUTPUT"

sleep 300


# Unmount CD-ROM ISO
cat "$OUTPUT" | sed '/^ide/d' > "$OUTPUT.2"
bash -c "cat >> \"$OUTPUT.2\"" <<EOL
ide0:0.present = "FALSE"
ide0:0.fileName = emptyBackingString
ide0:0.deviceType = "cdrom-image"
ide0:0.startConnected = "FALSE"
EOL
mv "$OUTPUT.2" "$OUTPUT"

"$VMRUN" -T ws stop "$OUTPUT"

# Remove CD-ROM
cat "$OUTPUT" | sed '/^ide/d' > "$OUTPUT.2"
bash -c "cat >> \"$OUTPUT.2\"" <<EOL
ide0:0.fileName = emptyBackingString
ide0:0.deviceType = "cdrom-image"
ide0:0.startConnected = "FALSE"
EOL
mv "$OUTPUT.2" "$OUTPUT"


# cat "$OUTPUT" | sed '/^ide/d' > "$OUTPUT.2"
# mv "$OUTPUT.2" "$OUTPUT"

"$OVF_TOOL" --shaAlgorithm=SHA1 --acceptAllEulas "$OUTPUT" "$OVA_PATH"

rm -rf ~/Documents/Virtual\ Machines.localized/$BUILD_NAME\ .vmwarevm

echo "Finished creating PostgreSQL $VERSION OVA"
