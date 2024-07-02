#!/bin/bash

# failover.sh
# This script performs a failover operation from the primary to the standby database

# Define environment variables
PRIMARY_DB_NAME=primarydb
STANDBY_DB_NAME=standbydb
ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
STANDBY_DB_HOST=your_standby_host
ORACLE_USER=oracle

# Ensure the ORACLE_HOME and ORACLE_SID are set
export ORACLE_HOME=$ORACLE_HOME
export PATH=$ORACLE_HOME/bin:$PATH

# Function to execute SQL commands
function execute_sql {
    local db_host=$1
    local sql_command=$2
    echo "Executing SQL command on $db_host: $sql_command"
    ssh ${ORACLE_USER}@${db_host} <<EOF
    export ORACLE_HOME=$ORACLE_HOME
    export PATH=$ORACLE_HOME/bin:$PATH
    sqlplus -s / as sysdba <<EOT
    $sql_command
    exit;
EOT
EOF
}

# Step 1: Prepare the Standby Database for Failover
echo "Preparing the standby database for failover..."
execute_sql $STANDBY_DB_HOST "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE FINISH FORCE;"

# Step 2: Activate the Standby Database as the Primary Database
echo "Activating the standby database as the primary database..."
execute_sql $STANDBY_DB_HOST "ALTER DATABASE ACTIVATE STANDBY DATABASE;"

# Step 3: Open the New Primary Database
echo "Opening the new primary database..."
execute_sql $STANDBY_DB_HOST "ALTER DATABASE OPEN;"

# Step 4: Verify the New Primary Database
echo "Verifying the new primary database..."
execute_sql $STANDBY_DB_HOST "SELECT OPEN_MODE FROM V\$DATABASE;"

# Completion message
echo "Failover operation completed successfully."
