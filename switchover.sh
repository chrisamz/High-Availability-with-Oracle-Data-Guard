#!/bin/bash

# switchover.sh
# This script performs a switchover operation between the primary and standby databases

# Define environment variables
PRIMARY_DB_NAME=primarydb
STANDBY_DB_NAME=standbydb
ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
PRIMARY_DB_HOST=your_primary_host
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

# Step 1: Prepare the Primary Database for Switchover
echo "Preparing the primary database for switchover..."
execute_sql $PRIMARY_DB_HOST "ALTER DATABASE COMMIT TO SWITCHOVER TO STANDBY WITH SESSION SHUTDOWN;"

# Step 2: Verify the Primary Database Switchover Status
echo "Verifying the primary database switchover status..."
execute_sql $PRIMARY_DB_HOST "SELECT SWITCHOVER_STATUS FROM V\$DATABASE;"

# Step 3: Switch the Roles on the Standby Database
echo "Switching the roles on the standby database..."
execute_sql $STANDBY_DB_HOST "ALTER DATABASE COMMIT TO SWITCHOVER TO PRIMARY;"

# Step 4: Open the New Primary Database
echo "Opening the new primary database..."
execute_sql $STANDBY_DB_HOST "ALTER DATABASE OPEN;"

# Step 5: Convert the Former Primary Database to Standby
echo "Converting the former primary database to standby..."
execute_sql $PRIMARY_DB_HOST "STARTUP MOUNT;"
execute_sql $PRIMARY_DB_HOST "ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT FROM SESSION;"

# Completion message
echo "Switchover operation completed successfully."
