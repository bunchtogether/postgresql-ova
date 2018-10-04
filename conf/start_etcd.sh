#!/bin/bash

ETCD_PEERS_FILE_PATH=/etcd/etcd_peers 

IP_ADDRESS=$(ip route get 1 | awk '{print $NF;exit}')

ETCD_CLUSTER_PEERS=etcd=http://${IP_ADDRESS}:2380

while read peer; do
    if [ "$peer" != "" ]; then
        ETCD_CLUSTER_PEERS=$ETCD_CLUSTER_PEERS,etcd=http://${peer}:2380
    fi
done < ${ETCD_PEERS_FILE_PATH}

/bin/etcd --name etcd \
    --data-dir /etcd/data \
    --listen-client-urls http://${IP_ADDRESS}:2379 \
    --advertise-client-urls http://${IP_ADDRESS}:2379 \
    --listen-peer-urls http://${IP_ADDRESS}:2380 \
    --initial-advertise-peer-urls http://${IP_ADDRESS}:2380 \
    --initial-cluster ${ETCD_CLUSTER_PEERS} \
    --initial-cluster-token etcd-secret-token \
    --initial-cluster-state new