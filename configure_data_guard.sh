#!/bin/bash

# configure_data_guard.sh
# This script configures Oracle Data Guard

# Define environment variables
PRIMARY_DB_NAME=primarydb
STANDBY_DB_NAME=standbydb
ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
PRIMARY_DB_HOST=your_primary_host
STANDBY_DB_HOST=your_standby_host
ORACLE_USER=oracle

# Ensure the ORACLE_HOME and ORACLE_SID are set for both primary and standby
export ORACLE_HOME=$ORACLE_HOME
export PATH=$ORACLE_HOME/bin:$PATH

# Function to execute SQL commands
function execute_sql {
    local sql_command=$1
    echo "Executing SQL command: $sql_command"
    sqlplus -s / as sysdba <<EOF
    $sql_command
    exit;
EOF
}

# Step 1: Create a Standby Control File on the Primary Database
echo "Creating standby control file on the primary database..."
execute_sql "ALTER DATABASE CREATE STANDBY CONTROLFILE AS '/tmp/standby_control.ctl';"

# Step 2: Transfer the Control File and Archive Logs to the Standby Server
echo "Transferring control file and archive logs to the standby server..."
scp /tmp/standby_control.ctl ${ORACLE_USER}@${STANDBY_DB_HOST}:/tmp/standby_control.ctl
scp $ORACLE_HOME/dbs/*.ora ${ORACLE_USER}@${STANDBY_DB_HOST}:$ORACLE_HOME/dbs/

# Step 3: Configure the Standby Database
echo "Configuring the standby database..."
ssh ${ORACLE_USER}@${STANDBY_DB_HOST} <<EOF
export ORACLE_HOME=$ORACLE_HOME
export PATH=$ORACLE_HOME/bin:$PATH
export ORACLE_SID=$STANDBY_DB_NAME

rman target / <<EOT
STARTUP NOMOUNT;
RESTORE CONTROLFILE FROM '/tmp/standby_control.ctl';
ALTER DATABASE MOUNT;
EXIT;
EOT

sqlplus -s / as sysdba <<EOT
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;
EXIT;
EOT
EOF

# Step 4: Set Data Guard Configuration Parameters on the Primary Database
echo "Setting Data Guard configuration parameters on the primary database..."
execute_sql "ALTER SYSTEM SET log_archive_dest_2='SERVICE=$STANDBY_DB_NAME ASYNC VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=$STANDBY_DB_NAME';"
execute_sql "ALTER SYSTEM SET fal_server='$STANDBY_DB_NAME';"
execute_sql "ALTER SYSTEM SET fal_client='$PRIMARY_DB_NAME';"
execute_sql "ALTER SYSTEM SET standby_file_management=AUTO;"

# Step 5: Enable Archiving on the Primary Database
echo "Enabling archiving on the primary database..."
execute_sql "ALTER SYSTEM SET log_archive_dest_state_2=ENABLE;"

# Step 6: Verify Data Guard Configuration
echo "Verifying Data Guard configuration..."
execute_sql "SELECT DEST_ID, STATUS, DESTINATION FROM V\$ARCHIVE_DEST WHERE DEST_ID=2;"

# Completion message
echo "Oracle Data Guard configuration completed successfully."
