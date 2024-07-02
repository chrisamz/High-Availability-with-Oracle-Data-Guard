-- performance_tuning.sql
-- This script applies performance tuning settings for Oracle Data Guard

-- Set the archive log destination size
ALTER SYSTEM SET log_archive_dest_1='LOCATION=/archivelogs/ MANDATORY REOPEN=60' SCOPE=BOTH;
ALTER SYSTEM SET log_archive_dest_2='SERVICE=standbydb ASYNC VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=standbydb REOPEN=60' SCOPE=BOTH;

-- Optimize the redo transport settings
ALTER SYSTEM SET log_archive_max_processes=4 SCOPE=BOTH;
ALTER SYSTEM SET log_archive_min_succeed_dest=1 SCOPE=BOTH;

-- Configure the standby redo log files
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 10 ('/u01/app/oracle/oradata/standbydb/redo10.log') SIZE 500M;
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 11 ('/u01/app/oracle/oradata/standbydb/redo11.log') SIZE 500M;
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 12 ('/u01/app/oracle/oradata/standbydb/redo12.log') SIZE 500M;
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 13 ('/u01/app/oracle/oradata/standbydb/redo13.log') SIZE 500M;

-- Enable Flashback Database
ALTER SYSTEM SET db_flashback_retention_target=1440 SCOPE=BOTH;
ALTER DATABASE FLASHBACK ON;

-- Set memory parameters for optimal performance
ALTER SYSTEM SET memory_target=2G SCOPE=BOTH;
ALTER SYSTEM SET memory_max_target=2G SCOPE=BOTH;
ALTER SYSTEM SET pga_aggregate_target=512M SCOPE=BOTH;
ALTER SYSTEM SET sga_target=1G SCOPE=BOTH;

-- Configure adaptive log file sync
ALTER SYSTEM SET _adaptive_log_file_sync=TRUE SCOPE=BOTH;

-- Tune Data Guard transport and apply parameters
ALTER SYSTEM SET standby_file_management=AUTO SCOPE=BOTH;
ALTER SYSTEM SET fal_server='standbydb' SCOPE=BOTH;
ALTER SYSTEM SET fal_client='primarydb' SCOPE=BOTH;
ALTER SYSTEM SET db_block_checking=FALSE SCOPE=BOTH;
ALTER SYSTEM SET db_block_checksum=FULL SCOPE=BOTH;

-- Optimize the I/O performance
ALTER SYSTEM SET disk_asynch_io=TRUE SCOPE=BOTH;
ALTER SYSTEM SET filesystemio_options=SETALL SCOPE=BOTH;

-- Set parallel execution parameters
ALTER SYSTEM SET parallel_max_servers=80 SCOPE=BOTH;
ALTER SYSTEM SET parallel_min_servers=10 SCOPE=BOTH;

-- Monitoring the Data Guard environment
ALTER SYSTEM SET dg_broker_start=TRUE SCOPE=BOTH;

-- Verify the tuning settings
SELECT name, value FROM v$parameter WHERE name IN (
    'log_archive_dest_1',
    'log_archive_dest_2',
    'log_archive_max_processes',
    'log_archive_min_succeed_dest',
    'db_flashback_retention_target',
    'memory_target',
    'memory_max_target',
    'pga_aggregate_target',
    'sga_target',
    'standby_file_management',
    'fal_server',
    'fal_client',
    'db_block_checking',
    'db_block_checksum',
    'disk_asynch_io',
    'filesystemio_options',
    'parallel_max_servers',
    'parallel_min_servers',
    'dg_broker_start'
);
