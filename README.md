# High Availability with Oracle Data Guard

## Overview

This project focuses on setting up and managing Oracle Data Guard for high availability and disaster recovery. Oracle Data Guard provides a robust solution to ensure data protection, high availability, and disaster recovery for Oracle databases.

## Technologies

- Oracle Data Guard

## Key Features

- Data Guard configuration
- Switchover and failover processes
- Monitoring scripts
- Performance tuning

## Project Structure

```
oracle-data-guard/
├── config/
│   ├── primary_init.ora
│   ├── standby_init.ora
│   ├── listener.ora
│   ├── tnsnames.ora
├── scripts/
│   ├── configure_data_guard.sh
│   ├── switchover.sh
│   ├── failover.sh
│   ├── monitor_data_guard.sh
│   ├── performance_tuning.sql
├── logs/
│   ├── data_guard_monitoring.log
├── docs/
│   ├── configuration_guide.md
│   ├── switchover_guide.md
│   ├── failover_guide.md
│   ├── performance_tuning_guide.md
├── README.md
└── LICENSE
```

## Instructions

### 1. Clone the Repository

Start by cloning the repository to your local machine:

```bash
git clone https://github.com/your-username/oracle-data-guard.git
cd oracle-data-guard
```

### 2. Set Up Oracle Data Guard

#### Configuration Files

- **Primary Database Initialization Parameters (`primary_init.ora`)**:
  - Contains the initialization parameters for the primary database.
  
- **Standby Database Initialization Parameters (`standby_init.ora`)**:
  - Contains the initialization parameters for the standby database.
  
- **Listener Configuration (`listener.ora`)**:
  - Contains the listener configuration for both primary and standby databases.
  
- **TNS Names Configuration (`tnsnames.ora`)**:
  - Contains the network service names configuration.

#### Example: `primary_init.ora`

```ini
# primary_init.ora
db_name=primarydb
db_unique_name=primarydb
log_archive_config='DG_CONFIG=(primarydb,standbydb)'
log_archive_dest_1='LOCATION=/archivelogs/ VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=primarydb'
log_archive_dest_2='SERVICE=standbydb LGWR ASYNC VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=standbydb'
remote_login_passwordfile='EXCLUSIVE'
```

#### Example: `standby_init.ora`

```ini
# standby_init.ora
db_name=primarydb
db_unique_name=standbydb
log_archive_config='DG_CONFIG=(primarydb,standbydb)'
log_archive_dest_1='LOCATION=/archivelogs/ VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=standbydb'
log_archive_dest_2='SERVICE=primarydb LGWR ASYNC VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=primarydb'
remote_login_passwordfile='EXCLUSIVE'
standby_file_management=AUTO
```

#### Example: `listener.ora`

```ini
# listener.ora
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = primarydb)
      (ORACLE_HOME = /path/to/oracle_home)
      (SID_NAME = primarydb)
    )
    (SID_DESC =
      (GLOBAL_DBNAME = standbydb)
      (ORACLE_HOME = /path/to/oracle_home)
      (SID_NAME = standbydb)
    )
  )

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = your_host)(PORT = 1521))
    )
  )
```

#### Example: `tnsnames.ora`

```ini
# tnsnames.ora
primarydb =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = primary_host)(PORT = 1521))
    (CONNECT_DATA =
      (SERVICE_NAME = primarydb)
    )
  )

standbydb =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = standby_host)(PORT = 1521))
    (CONNECT_DATA =
      (SERVICE_NAME = standbydb)
    )
  )
```

### 3. Configure Data Guard

Use the `configure_data_guard.sh` script to set up Oracle Data Guard.

```bash
# configure_data_guard.sh
# This script configures Oracle Data Guard

# Set environment variables
export ORACLE_SID=primarydb
export ORACLE_HOME=/path/to/oracle_home

# Create standby control file
rman target / <<EOF
BACKUP CURRENT CONTROLFILE FOR STANDBY FORMAT '/path/to/standby_control.ctl';
EOF

# Transfer the control file and archive logs to the standby server
scp /path/to/standby_control.ctl standby_host:/path/to/standby_control.ctl
scp /archivelogs/* standby_host:/archivelogs/

# Configure the standby database
ssh standby_host <<EOF
export ORACLE_SID=standbydb
export ORACLE_HOME=/path/to/oracle_home

rman target / <<EOT
RESTORE STANDBY CONTROLFILE FROM '/path/to/standby_control.ctl';
EOT

sqlplus / as sysdba <<EOT
STARTUP MOUNT;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT FROM SESSION;
EOT
EOF

# Start Data Guard on the primary database
sqlplus / as sysdba <<EOF
ALTER SYSTEM SET log_archive_dest_state_2=ENABLE;
EOF
```

### 4. Switchover and Failover

Use the `switchover.sh` and `failover.sh` scripts to perform switchover and failover operations.

#### Example: `switchover.sh`

```bash
# switchover.sh
# This script performs a switchover operation

# Switchover to standby database
sqlplus / as sysdba <<EOF
ALTER DATABASE COMMIT TO SWITCHOVER TO STANDBY WITH SESSION SHUTDOWN;
EOF

# Switch the roles on the standby database
ssh standby_host <<EOF
export ORACLE_SID=standbydb
export ORACLE_HOME=/path/to/oracle_home

sqlplus / as sysdba <<EOT
ALTER DATABASE COMMIT TO SWITCHOVER TO PRIMARY;
ALTER DATABASE OPEN;
EOT
EOF
```

#### Example: `failover.sh`

```bash
# failover.sh
# This script performs a failover operation

# Failover to standby database
ssh standby_host <<EOF
export ORACLE_SID=standbydb
export ORACLE_HOME=/path/to/oracle_home

sqlplus / as sysdba <<EOT
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE FINISH;
ALTER DATABASE ACTIVATE STANDBY DATABASE;
ALTER DATABASE OPEN;
EOT
EOF
```

### 5. Monitoring and Performance Tuning

#### Monitoring Scripts

Use the `monitor_data_guard.sh` script to monitor the status of Oracle Data Guard.

```bash
# monitor_data_guard.sh
# This script monitors the status of Oracle Data Guard

sqlplus / as sysdba <<EOF
SET LINESIZE 200
COLUMN DB_UNIQUE_NAME FORMAT A20
COLUMN DATABASE_ROLE FORMAT A20
COLUMN PROTECTION_MODE FORMAT A20
SELECT DB_UNIQUE_NAME, DATABASE_ROLE, PROTECTION_MODE, OPEN_MODE FROM V$DATABASE;
EOF
```

#### Performance Tuning

Use the `performance_tuning.sql` script to apply performance tuning settings.

```sql
-- performance_tuning.sql
-- This script applies performance tuning settings for Oracle Data Guard

-- Set the archive log destination size
ALTER SYSTEM SET log_archive_dest_1='LOCATION=/archivelogs/ MANDATORY REOPEN=60' SCOPE=BOTH;

-- Optimize the redo transport settings
ALTER SYSTEM SET log_archive_max_processes=4 SCOPE=BOTH;
ALTER SYSTEM SET log_archive_min_succeed_dest=1 SCOPE=BOTH;

-- Configure the standby redo log files
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 SIZE 500M;
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 SIZE 500M;
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 SIZE 500M;
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 SIZE 500M;
```

### 6. Documentation

#### Configuration Guide

`docs/configuration_guide.md`

```markdown
# Oracle Data Guard Configuration Guide

## Overview

This guide provides step-by-step instructions for configuring Oracle Data Guard for high availability and disaster recovery.

## Prerequisites

- Oracle Database installed on both primary and standby servers.
- Network connectivity between primary and standby servers.
- Oracle listener configured on both servers.

## Steps

1. Configure the primary database.
2. Configure the standby database.
3. Set up Data Guard on the primary database.
4. Start Data Guard on the standby database.
5. Verify the Data Guard configuration.
```

#### Switchover Guide

`docs/switchover_guide.md`

```markdown
# Oracle Data Guard Switchover Guide

## Overview

This guide provides step-by-step instructions for performing a switchover operation with Oracle Data Guard.

## Steps

1. Prepare the primary database for switchover.
2. Perform the switchover to the standby database.
3. Verify the new primary database.
```

#### Failover

 Guide

`docs/failover_guide.md`

```markdown
# Oracle Data Guard Failover Guide

## Overview

This guide provides step-by-step instructions for performing a failover operation with Oracle Data Guard.

## Steps

1. Prepare the standby database for failover.
2. Perform the failover to the standby database.
3. Verify the new primary database.
```

#### Performance Tuning Guide

`docs/performance_tuning_guide.md`

```markdown
# Oracle Data Guard Performance Tuning Guide

## Overview

This guide provides performance tuning tips for optimizing Oracle Data Guard.

## Tips

1. Optimize redo transport settings.
2. Configure standby redo log files.
3. Adjust archive log destination size.
```

### Conclusion

By following these steps, you can set up and manage Oracle Data Guard to ensure high availability and disaster recovery for your Oracle databases.

## Contributing

We welcome contributions to improve this project. If you would like to contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch.
3. Make your changes.
4. Submit a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.



---

Thank you for using our High Availability with Oracle Data Guard project! We hope this guide helps you set up and manage Oracle Data Guard effectively.
