#!/bin/bash

# monitor_data_guard.sh
# This script monitors the status of the Oracle Data Guard environment

# Define environment variables
PRIMARY_DB_NAME=primarydb
STANDBY_DB_NAME=standbydb
ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
PRIMARY_DB_HOST=your_primary_host
STANDBY_DB_HOST=your_standby_host
ORACLE_USER=oracle
LOG_FILE=/var/log/data_guard_monitoring.log

# Ensure the ORACLE_HOME and PATH are set
export ORACLE_HOME=$ORACLE_HOME
export PATH=$ORACLE_HOME/bin:$PATH

# Function to execute SQL commands
function execute_sql {
    local db_host=$1
    local sql_command=$2
    ssh ${ORACLE_USER}@${db_host} <<EOF
    export ORACLE_HOME=$ORACLE_HOME
    export PATH=$ORACLE_HOME/bin:$PATH
    sqlplus -s / as sysdba <<EOT
    SET LINESIZE 200
    SET PAGESIZE 100
    $sql_command
    exit;
EOT
EOF
}

# Function to log monitoring results
function log_result {
    local result=$1
    echo "$(date): $result" >> $LOG_FILE
}

# Step 1: Check the Primary Database Status
echo "Checking the primary database status..."
PRIMARY_STATUS=$(execute_sql $PRIMARY_DB_HOST "SELECT DB_UNIQUE_NAME, DATABASE_ROLE, OPEN_MODE FROM V\$DATABASE;")
log_result "Primary Database Status: $PRIMARY_STATUS"

# Step 2: Check the Standby Database Status
echo "Checking the standby database status..."
STANDBY_STATUS=$(execute_sql $STANDBY_DB_HOST "SELECT DB_UNIQUE_NAME, DATABASE_ROLE, OPEN_MODE FROM V\$DATABASE;")
log_result "Standby Database Status: $STANDBY_STATUS"

# Step 3: Check the Data Guard Configuration
echo "Checking the Data Guard configuration..."
DG_CONFIG=$(execute_sql $PRIMARY_DB_HOST "SELECT DEST_ID, STATUS, DESTINATION FROM V\$ARCHIVE_DEST WHERE DEST_ID=2;")
log_result "Data Guard Configuration: $DG_CONFIG"

# Step 4: Check the Log Apply Status on the Standby Database
echo "Checking the log apply status on the standby database..."
LOG_APPLY_STATUS=$(execute_sql $STANDBY_DB_HOST "SELECT THREAD#, SEQUENCE#, APPLIED FROM V\$ARCHIVED_LOG WHERE APPLIED='YES' ORDER BY FIRST_TIME DESC;")
log_result "Log Apply Status: $LOG_APPLY_STATUS"

# Completion message
echo "Data Guard monitoring completed successfully. Results logged to $LOG_FILE."
