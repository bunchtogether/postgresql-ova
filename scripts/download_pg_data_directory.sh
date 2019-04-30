#!/bin/bash

# Should be run from one of the postgres nodes
if [ ! -f /var/lib/postgresql/.ssh/rsync ]; then
  echo "This script requires rsync ssh-key to authenticate and download data, run this frome one of the postgres servers"
  exit 1
fi

if [ $# -lt 1 ]; then
  echo -e "Usage: $0 POSTGRES_IP\n"
  exit 0
fi

mkdir -p backup
sudo -u postgres rsync -avz postgres@$POSTGRES_IP:/var/lib/postgresql backup/
