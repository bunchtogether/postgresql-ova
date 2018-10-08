# PostgreSQL v10 OVA

## Post Installation Steps

### Setup Replication Master

```sql
    -- Create replicator User
    CREATE ROLE replicator WITH REPLICATION PASSWORD 'REPLICATOR_PASSWORD' LOGIN;


```

# Replica Server

Edit `postgresql.conf` and set `hot_standby = on`

Run the following command 
    ```
    pg_basebackup -h MASTER_IP_ADDRESS_HERE -D /var/lib/postgresql/10/main/ -P -U replicator --wal-method=stream
    # Password: Enter your REPLICATOR_PASSWORD here

    ```


command="$HOME/bin/rrsync -ro ~/backups/",no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding ssh-rsa AAA...vp Automated remote backup