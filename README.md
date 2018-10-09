# PostgreSQL v10 OVA

Post Installation Steps

# Steps 1 - Update Config files

Edit postgresql.conf and search for `archive_command` and replace REPLICA_IP_ADDRESS with IP address of the replica server

### Start PostgreSQL database 
    sudo systemctl start pg

### Create Replication user
    # Create replocation user ( username: replicator ) and set strong password
    sudo -u postgres createuser -U postgres replicator -P -c 5 --replication
    # Enter password for new role: // Enter strong password
    # cb0DaK90@43

# Step 2 - Update Replica Server

Edit postgresql.conf and search for `hot_standby` and remove the pound sign before it and set it to on

    hot_standby = on;

# Step 3 - Copy `data_directory` directory contents from master to the replica server.

    # Switch to postgres user
    sudo su postgres

    # Delete all files under `/var/lib/postgresql/10/main` on replica server
    cd /var/lib/postgresql/10/main/
    rm -rf *

    # Copy files /var/lib/postgresql/10/main from master server to replica server with pg_basebackup utility
    pg_basebackup -h MASTER_SERVER_IP_ADDRESS -D /var/lib/postgresql/10/main/ -P -U replicator --wal-method=stream
    # Password: Enter your REPLICATOR_PASSWORD here 

# Step 4 - Setup recovery.conf
    Copy recover.conf from /etc/postgresql/recovery.conf and un-comment the following files
        1. Set `standby_mode = on`, to enable Standby mode on replica server
        2. Update `primary_conninfo` with username and password of the user created in Step 1 and update the MASTER_SERVER_IP_ADDRESS with the IP address of the master server
        3. Set `trigger_file = '/tmp/IAmTheMasterNow'` to enable fast trigger, when the file is available at the path the replica server becomes the master

    Start postgres service on replica server
        sudo systemctl start pg