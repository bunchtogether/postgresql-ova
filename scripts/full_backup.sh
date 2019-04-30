#!/bin/bash


if [ $# -lt 2 ]; then
  echo -e "\nUsage:\n\t $0 <POSTGRES_IP> <POSTGRES_SSH_KEY> <OPTIONAL DATABASE_NAME>\n"
  exit 1
fi

POSTGRES_IP=$1
POSTGRES_KEY=$2
PG_DB_NAME=''

if [ $# -eq 3 ]; then
  PG_DB_NAME=$3
  DUMP_FILE_NAME=$(echo "$PG_DB_NAME-dump-$(date +%m-%d-%Y).sql")
  ssh ubuntu@$POSTGRES_IP -i $POSTGRES_KEY bash -c "'sudo -u postgres pg_dump $PG_DB_NAME | tee /home/ubuntu/$DUMP_FILE_NAME'"
  scp -i $POSTGRES_KEY ubuntu@$POSTGRES_IP:/home/ubuntu/$DUMP_FILE_NAME "$POSTGRES_IP-$DUMP_FILE_NAME"
  ssh ubuntu@$POSTGRES_IP -i $POSTGRES_KEY bash -c "'rm -rf /home/ubuntu/$DUMP_FILE_NAME'"
else
  DUMP_FILE_NAME=$(echo "full_dump_$(date +%m-%d-%Y).sql")
  ssh ubuntu@$POSTGRES_IP -i $POSTGRES_KEY bash -c "'sudo -u postgres pg_dumpall | tee /home/ubuntu/$DUMP_FILE_NAME'"
  scp -i $POSTGRES_KEY ubuntu@$POSTGRES_IP:/home/ubuntu/$DUMP_FILE_NAME "$POSTGRES_IP-$DUMP_FILE_NAME"
  ssh ubuntu@$POSTGRES_IP -i $POSTGRES_KEY bash -c "'rm -rf /home/ubuntu/$DUMP_FILE_NAME'"
fi

