#!/bin/bash
#
# This script will invoke IBM Rman Backup scripts on remote Exadata nodes
# It is meant to execute backups even if the local RAC instance is down, by redirecting its execution
# to a remote node using # Exadata DCLI tool
#
#

## Global Variables
v_inst=`ps -ef |grep smon |grep $1 | cut -d "_" -f3`
export LANG=en_US.UTF-8
DBA_DIR=`grep "BKP_DIR=" /u02/ibmdba/backup/etc/ibmdba | grep -v "#" | cut -d'=' -f2`; export DBA_DIR
STATUS_FILE=$DBA_DIR/log/statusdb_$1.log

if [ -z $v_inst ]; then 	## Check whether database instance is online on current node
	## NOT ONLINE - REMOTE DCLI EXECUTION
	## Set environment variables
	export ORACLE_SID=$1
	export ORAENV_ASK=NO
	. oraenv

	## Retrieves the first node where instance is online (if any)
	srvctl status database -d $1 |egrep -v "not running" > $STATUS_FILE
	v_host=`cat $STATUS_FILE | head -1 | awk '{print $7}'`
	v_inst=`cat $STATUS_FILE | head -1 | awk '{print $2}'`

	# Remote Execution
	case "$2" in
		ARC) dcli -l root -c $v_host "export ORAENV_ASK=NO; oraenv; su - oracle -c '$DBA_DIR/job/RmanBackupArchive.ksh $v_inst $3'";;
		DEL) dcli -l root -c $v_host "export ORAENV_ASK=NO; oraenv; su - oracle -c '$DBA_DIR/job/RmanDeleteBackup.ksh  $v_inst $3'";;
		ON)  dcli -l root -c $v_host "export ORAENV_ASK=NO; oraenv; su - oracle -c '$DBA_DIR/job/RmanBackupOnline.ksh  $v_inst $3 $4'";;
		*)
		echo ""
		echo "-------------------------------------"
		echo "Invalid parameters  "
		echo "-------------------------------------"
		echo "Use ARC for ARCHIVELOG backups"
		echo "Use DEL for backup DELETION"
		echo "Use ON  for Online Database Backup"
		echo "-------------------------------------"
		echo ""
	;;
	esac

	else ## ONLINE - LOCAL EXECUTION

	## Set environment variables
	export ORACLE_SID=$v_inst
	export ORAENV_ASK=NO
	. oraenv

	# Local Backup or Delete Execution
	case "$2" in
		ARC) su - oracle -c "$DBA_DIR/job/RmanBackupArchive.ksh $v_inst $3";;
		DEL) su - oracle -c "$DBA_DIR/job/RmanDeleteBackup.ksh  $v_inst $3";;
		ON)  su - oracle -c "$DBA_DIR/job/RmanBackupOnline.ksh  $v_inst $3 $4";;
		*)
		echo ""
		echo "-------------------------------------"
		echo "Invalid parameters  "
		echo "-------------------------------------"
		echo "Use ARC for ARCHIVELOG backups"
		echo "Use DEL for backup DELETION"
		echo "Use ON  for Online Database Backup"
		echo "-------------------------------------"
		echo ""
		;;
	esac
fi
exit 0