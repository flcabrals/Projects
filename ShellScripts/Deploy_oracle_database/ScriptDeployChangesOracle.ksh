#!/bin/ksh
#set -x
#
#***************************************************************************
# ---------------------------------------------------------------------------
#  			    ScriptDeployChangesOracle.ksh
# ---------------------------------------------------------------------------
#  Oracle deployment automation script
#  Authors: Fagner Freitas - fagnerfreitas@kyndryl.com
#           Flavio Cabral  - flcabral@kyndryl.com
#
#  To remove wrong character
#    execute: tr -d "\015" <NOME_ARQUIVO >NOME_ARQUIVO_new
#             rm NOME_ARQUIVO (arquivo velho)
#             mv NOME_ARQUIVO_new NOME_ARQUIVO
#             chmod 700 NOME_ARQUIVO
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
#                           ALTERATION HISTORY
# V1R0 - Initial version
# V1R1 - Oct-06-2020 - Exclusion of ORA errors (00942 and 01418)
#                      from function Function_Valida_Ora_Errors
# V1R2 - Nov-06-2020 - Adjust to show invalid object errors after deployment
#
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
#                           VERSION CONTROL
Versao=V1R2
#
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Input parameters :
#
# 1: Yaml with the sequence of changes to be applied in Database ( YAML_SEQUENCE_CHANGES )
#
# ---------------------------------------------------------------------------


# ---------------------------------------------------------------------------
# -                                FUNCTIONS                                -
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Help function
# ---------------------------------------------------------------------------
Function_Help()
{
   echo ${CNTR} ""
   echo ${CNTR} "Format: ScriptDeployChangesOracle.ksh <INSTANCE_DELPLOY> <YAML_SEQUENCE_CHANGES>"
   echo ${CNTR} ""
   echo ${CNTR} "Where:  INSTANCE_DELPLOY = INSTANCE_NAME (Same name of config file name)"
   echo ${CNTR} "        YAML_SEQUENCE_CHANGES = sequence_change_oracle.yaml"
   echo ${CNTR} ""
   exit 1
}

# ---------------------------------------------------------------------------
# Getting the parameters from configuration file
# ---------------------------------------------------------------------------
Function_GetConfig()
{
   #-
   if [ -f "$DBA_CONF_FILE" ]; then
   VAR=`grep ${1} ${DBA_CONF_FILE} | cut -d'=' -f2`
   fi
   if [ "${VAR}" = "" ]; then
      if [ -z "$2" ];  then
         echo ${VAR}
      else
         VAR=`grep ${2} ${DBA_CONF_FILE} | cut -d'=' -f2`
         echo ${VAR}
      fi
   else
       echo ${VAR}
   fi
}

# ---------------------------------------------------------------------------
# Creation of the file with the deployment logs
# ---------------------------------------------------------------------------
Function_Cria_Arq_Logs_Change()
{
	LOG_FILE=${1}

	if [ ! -e ${GIT_FONT_DIRECTORY}/${V_DAY_CHANGE}/LOGS_${V_CHANGE_DIRECTORY}.zip ]; then
		zip ${GIT_FONT_DIRECTORY}/${V_DAY_CHANGE}/LOGS_${V_CHANGE_DIRECTORY}.zip ${LOG_FILE}
	else
		zip -ur ${GIT_FONT_DIRECTORY}/${V_DAY_CHANGE}/LOGS_${V_CHANGE_DIRECTORY}.zip ${LOG_FILE}
	fi

}

# ---------------------------------------------------------------------------
# Validation of errors during Deploy
# ---------------------------------------------------------------------------
Function_Valida_Ora_Errors()
{
	LOG_FILE=${1}
	CONT_ERROR=`cat ${LOG_FILE} | grep -E 'ORA-|SP2-0310' | wc -l`
	VAR_ERROR_TMP=

	if [ ${CONT_ERROR} -eq 0 ]; then
		echo ""
	elif [ ${CONT_ERROR} -ge 1 ]; then
	    TEMP_FILE="$(mktemp ${BASE_FONT_DIRECTORY}/tmp/deploy_logfile.XXXXXX)"
		VAR_ERROR_TMP=$(cat ${LOG_FILE} | grep "ORA-" | grep -v "ORA-00942" | grep -v "ORA-01418" >> ${TEMP_FILE})
		VAR_ERROR_TMP2=$(cat ${LOG_FILE} | grep "Warning" >> ${TEMP_FILE})
	    VAR_ERROR_TMP3=$(cat ${LOG_FILE} | grep "SP2-0310" >> ${TEMP_FILE})
	    echo "${TEMP_FILE}"
	else
		echo ""
	fi

}

# ---------------------------------------------------------------------------
# Block the users during Deploy
# ---------------------------------------------------------------------------
Function_Block_Users()
{
	V_INST_DEPLOY=`Function_GetConfig DB_BLOCK_ACCESS`
	V_STATUS=${1}

		SQLPLUS_OUTPUT=`sqlplus -s  "${V_INST_DEPLOY}" <<EOF
        	SET HEAD OFF
        	SET AUTOPRINT OFF
        	SET TERMOUT OFF
        	SET SERVEROUTPUT ON
			alter system ${V_STATUS} restricted session;
		EOF`

}

# ---------------------------------------------------------------------------
# Get object error after Deploy
# ---------------------------------------------------------------------------
Function_Get_Show_Error_Obj_Invalid()
{
	OBJECT_NAME=${1}'  '${2}'  '${3}
	SPOOL_ERROR_FILE=${BASE_FONT_DIRECTORY}/tmp/error_obj_invalid_${V_DAY_CHANGE}_${V_STATUS}.log

		SQLPLUS_OUTPUT=`sqlplus -s  "${V_INST_DEPLOY}" <<EOF
        	SET HEAD OFF
        	SET AUTOPRINT OFF
        	SET TERMOUT OFF
        	SET FEEDBACK OFF
        	SET SERVEROUTPUT ON
        	SPOOL ${SPOOL_ERROR_FILE}
        	SHOW ERRORS ${OBJECT_NAME};
			SPOOL OFF
		EOF`

	echo `cat ${SPOOL_ERROR_FILE}`

}

# ---------------------------------------------------------------------------
# Block to recompile the objets invalid after Deploy
# ---------------------------------------------------------------------------
Function_List_Recomp_Obj_Invalid()
{

	SQLPATH=${ORACLE_HOME}/rdbms/admin; export SQLPATH
	V_INST_DEPLOY=`Function_GetConfig DB_BLOCK_ACCESS`
	V_STATUS=${1}
	SPOOL_FILE=${BASE_FONT_DIRECTORY}/tmp/obj_invalid_${V_DAY_CHANGE}_${V_STATUS}.log

		SQLPLUS_OUTPUT=`sqlplus -s  "${V_INST_DEPLOY}" <<EOF
        	SET HEAD OFF
        	SET AUTOPRINT OFF
        	SET TERMOUT OFF
        	SET FEEDBACK OFF
        	SET PAGES 0
        	SET SERVEROUTPUT ON
			exec SYS.UTL_RECOMP.RECOMP_PARALLEL(4);

			SPOOL ${SPOOL_FILE}

			select object_type||' '||owner||'.'||object_name
			from dba_objects
			where status='INVALID'
  			  and object_type <> 'UNDEFINED'
  			  and owner in ('REFCENT','GOLD_INTERF','REFCENT_USER','FISCAL','REFCESH','REFCENT_REPORT')
  			  order by object_type;

  			SPOOL OFF

		EOF`



	if [ ${V_STATUS} = 'after' ]; then

		echo " ==================== "						>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    	echo " ==================== "						>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    	echo " ==================== "						>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    	echo " Objetos Inválidos após a change : "			>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    	echo "  "											>> ${BASE_FONT_DIRECTORY}/config/Mail.out

		while read LINE
		do
        	V_EXISTS=$(cat ${BASE_FONT_DIRECTORY}/tmp/obj_invalid_${V_DAY_CHANGE}_${V_LIST_RECOMP_BEFORE}.log | grep "${LINE}" | wc -l)
			if [ ${V_EXISTS} -eq 0 ]; then
				ERRORS_OBJECT=`Function_Get_Show_Error_Obj_Invalid ${LINE}`
				echo "      ${LINE} "	>> ${BASE_FONT_DIRECTORY}/config/Mail.out
				echo "      ${ERRORS_OBJECT} "	>> ${BASE_FONT_DIRECTORY}/config/Mail.out
			fi
		done < "${BASE_FONT_DIRECTORY}/tmp/obj_invalid_${V_DAY_CHANGE}_${V_LIST_RECOMP_AFTER}.log"

	fi
}

# ---------------------------------------------------------------------------
# Sending email with change logs
# ---------------------------------------------------------------------------
Function_Envia_Email_Change()
{

	for LOGFILE in ${GIT_FONT_DIRECTORY}/${V_DAY_CHANGE}/*.zip
	do
		ATTACHMENTS="${ATTACHMENTS} -a ${LOGFILE}"
	done

	SMTP_SERVER=`Function_GetConfig SMTP_SERVER`
	EMAILS=`Function_GetConfig LIST_EMAIL`
	SUBJECT=`Function_GetConfig SUBJECT`

	/bin/mailx ${ATTACHMENTS} -S smtp="${SMTP_SERVER}" -r Relatorios_Carrefour@carrefour.com -s "${SUBJECT}" -v "${EMAILS}" < ${BASE_FONT_DIRECTORY}/config/Mail.out

}

# ---------------------------------------------------------------------------
# Function to validate the file with deploy sequence
# Variables :
#	V_ARRAY_SEQ_DEPLOY --> Variable with the file name with deploy sequence
#   V_DAY_CHANGE	   --> Variable with the day of implementation
# ---------------------------------------------------------------------------
Function_Valida_Arq_Seq_Conf()
{
	[ -z "$V_ARRAY_SEQ_DEPLOY" ] && Function_Help
	if	[ ! -f "$GIT_FONT_DIRECTORY/$V_ARRAY_SEQ_DEPLOY" ]; then
		echo "Arquivo de sequencia de deploy nao existe!!!!!"
		echo "Necessario informar ao analista responsavel!!!!"
		exit 1
	else
		echo >> $GIT_FONT_DIRECTORY/$V_ARRAY_SEQ_DEPLOY
		V_DAY_CHANGE=$(sed '1q' "$GIT_FONT_DIRECTORY/$V_ARRAY_SEQ_DEPLOY")
		V_DAY_CHANGE=${V_DAY_CHANGE//:}
		V_SLACK_MESSAGE=${V_SLACK_MESSAGE}" Data : "${V_DAY_CHANGE}" (Resultado)** \r\r "
	fi

	[ -z "$V_DB_DEPLOY" ] && Function_Help
	if	[ ! -f "$DBA_CONF_FILE" ]; then
		echo "Arquivo de configuracao da instancia nao existe!!!!!"
		echo "Necessario informar ao analista responsavel!!!!"
		exit 1
	fi


}

# ---------------------------------------------------------------------------
# Funcao de deploy das changes
# Variaveis :
#	V_N_CHANGE     --> Number of the change based of the directory name
#   V_OWNER_ARRAY  --> Array with the owners of the will that will be applied
#                      on environment
# ---------------------------------------------------------------------------
Function_Deploy_Seq_Change()
{
	V_N_CHANGE="${V_CHANGE_DIRECTORY:3}"
	V_OWNER_ARRAY=($V_OWNER)
	for OWNER in "${V_OWNER_ARRAY[@]}";
	do

		if [ ${OWNER} = 'refcent_user' ]; then
			V_INST_DEPLOY=`Function_GetConfig refcent`
		elif [ ${OWNER} = 'refcesh_user' ]; then
			V_INST_DEPLOY=`Function_GetConfig refcesh`
		else
			V_INST_DEPLOY=`Function_GetConfig ${OWNER}`
		fi

		SQLPATH=${GIT_FONT_DIRECTORY}/${V_DAY_CHANGE}/${V_CHANGE_DIRECTORY}/${OWNER}; export SQLPATH

		if [ ${OWNER} = 'tibdata' ]; then

			SPOOL_FILE=${GIT_FONT_DIRECTORY}/${V_DAY_CHANGE}/${V_CHANGE_DIRECTORY}/${OWNER}/001_uns_version_${V_CHANGE_DIRECTORY}_${OWNER}.log
			SCRIPT_FILE=001_uns_version.sql

		else

			SPOOL_FILE=${GIT_FONT_DIRECTORY}/${V_DAY_CHANGE}/${V_CHANGE_DIRECTORY}/${OWNER}/scr_install_${V_CHANGE_DIRECTORY}_${OWNER}.log
			SCRIPT_FILE=scr_install_${V_CHANGE_DIRECTORY}_${OWNER}.sql

		fi

		if [ ${OWNER} = 'dba' ]; then
			OWNER='system';
		fi

		SQLPLUS_OUTPUT=`sqlplus -s  "${V_INST_DEPLOY}" <<EOF
        	SET HEAD OFF
        	SET AUTOPRINT OFF
        	SET TERMOUT OFF
        	SET SERVEROUTPUT ON

        	ALTER SESSION SET CURRENT_SCHEMA = ${OWNER};

        	SPOOL ${SPOOL_FILE}

        	select sys_context('userenv','current_schema') CURRENT_SCHEMA from dual;

        	@${SCRIPT_FILE}

        	SPOOL OFF

    	EOF`

RC=$?

ERROR_ORA=`Function_Valida_Ora_Errors ${SPOOL_FILE}`

if [[ ! -s ${ERROR_ORA} ]] ; then

	V_SLACK_MESSAGE=${V_SLACK_MESSAGE}" \r\r- &#x2705;  \t-\tSchema "${OWNER}" \r\r "
    echo " Deploy Change : ${V_CHANGE_DIRECTORY} " 	>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " Status : Executado com sucesso "	>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " Owner : ${OWNER} "				>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " Script ${SCRIPT_FILE} "			>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " Log : ${SPOOL_FILE} "			>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " ==================== "			>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " ==================== "			>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " ==================== "			>> ${BASE_FONT_DIRECTORY}/config/Mail.out

else

	V_SLACK_MESSAGE=${V_SLACK_MESSAGE}" \r\r- &#x1F7E8; \t-\tSchema "${OWNER}" \r\r "
	echo " Deploy Change : ${V_CHANGE_DIRECTORY} "	>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " Status : Executado com falha "	>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " Owner : ${OWNER} "				>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " Script ${SCRIPT_FILE} "			>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " Log : ${SPOOL_FILE} "			>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " Erros :  "						>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    while IFS= read -r line
	do
  		echo "        $line"				>> ${BASE_FONT_DIRECTORY}/config/Mail.out
	done < "$ERROR_ORA"
    echo " ==================== "			>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " ==================== "			>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    echo " ==================== "			>> ${BASE_FONT_DIRECTORY}/config/Mail.out
    rm -f ${ERROR_ORA}


fi

Function_Cria_Arq_Logs_Change ${SPOOL_FILE}

	done
}


# ---------------------------------------------------------------------------
# Function to list the deployment sequence
# ---------------------------------------------------------------------------
Function_List_Seq_Deploy()
{
	sed 1d ${GIT_FONT_DIRECTORY}/${V_ARRAY_SEQ_DEPLOY} | while IFS=:, read -r key val ; do
    	val=$(echo ${val##*( )});val=$(echo ${val%%*( )});val=${val%\]}; val=$(echo ${val} | grep -o '[^\t ].*'); val=${val#\[}; val=${val#\"}; key=${key#export };
    	V_CHANGE_DIRECTORY=${key##*( )}
    	V_OWNER=${val}

		if [ ! -z "${V_CHANGE_DIRECTORY}" ]; then

    		V_SLACK_MESSAGE=${V_SLACK_MESSAGE}"**Change "${V_CHANGE_DIRECTORY}"** "
    		Function_Deploy_Seq_Change

		fi
  	done
}

# ---------------------------------------------------------------------------
# Identify the SO
# ---------------------------------------------------------------------------
SISOPER=`uname`
if [ "${SISOPER}" = "Linux" ]; then
   CNTR="-e"
fi
case ${SISOPER} in
   "AIX") AWK_CMD="awk";
    	  OPT="w";;
   "HP-UX") AWK_CMD="awk";
	    OPT="F";;
   "Linux") AWK_CMD="awk";
 	    OPT="w";;
   "SunOS") AWK_CMD="nawk";
   	    OPT="w";;
   *) echo ${CNTR} "\n Unknown platform: ${SISOPER}\n"; exit 1 ;;
esac



# ---------------------------------------------------------------------------
# Start of script execution
# ---------------------------------------------------------------------------

DEPLOY_DIR=`grep "DEPLOY_DIR=" /etc/ibmdba | grep -v "#" | cut -d'=' -f2`; export DEPLOY_DIR
V_ARRAY_SEQ_DEPLOY=${2}; export V_ARRAY_SEQ_DEPLOY
V_DB_DEPLOY=${1}; export V_DB_DEPLOY

BASE_FONT_DIRECTORY=${DEPLOY_DIR}
GIT_FONT_DIRECTORY=${DEPLOY_DIR}/${V_DB_DEPLOY}/automatizacao-de-deploy-gold
DBA_CONF_FILE=${DEPLOY_DIR}/config/${V_DB_DEPLOY}_deploy_oracle.conf

V_DAY_CHANGE=
V_CHANGE_DIRECTORY=
V_OWNER=
V_LIST_RECOMP_AFTER='after'
V_LIST_RECOMP_BEFORE='before'
V_DATE_DEPLOY=$(date +"%m%d%Y")
V_SLACK_MESSAGE='{ "text": "**Changes Gold (Environment - '${V_DB_DEPLOY}') -'
V_SLACK_CHANNEL=`Function_GetConfig SLACK_CHANNEL`

# ---------------------------------------------------------------------------
# Environment : ORACLE_HOME
# ---------------------------------------------------------------------------
export ORACLE_HOME=/app/Oracle/product/11.2.0.4/client_1
export http_proxy=`Function_GetConfig HTTP_PROXY`
export https_proxy=`Function_GetConfig HTTP_PROXY`

export TNS_ADMIN=$DEPLOY_DIR/tns_admin

PATH=$PATH:$HOME/.local/bin:$HOME/bin

export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export PATH=$PATH:$ORACLE_HOME/bin


export NLS_LANG=`Function_GetConfig NLS_LANG`

echo "" > ${BASE_FONT_DIRECTORY}/config/Mail.out

# ---------------------------------------------------------------------------
# Validates that the sequence file name was informed
# ---------------------------------------------------------------------------
Function_Valida_Arq_Seq_Conf

echo "inicio Deploy Gold ${V_DAY_CHANGE} - "`date` > ${BASE_FONT_DIRECTORY}/LogDeployGold${V_DB_DEPLOY}${V_DAY_CHANGE}.log

# ---------------------------------------------------------------------------
# List objects invalid - before
# ---------------------------------------------------------------------------
Function_List_Recomp_Obj_Invalid ${V_LIST_RECOMP_BEFORE}

# ---------------------------------------------------------------------------
# Enable block session
# ---------------------------------------------------------------------------
#Function_Block_Users "ENABLE"

# ---------------------------------------------------------------------------
# List of deployment sequence
# ---------------------------------------------------------------------------
Function_List_Seq_Deploy

# ---------------------------------------------------------------------------
# List objects invalid - after
# ---------------------------------------------------------------------------
Function_List_Recomp_Obj_Invalid ${V_LIST_RECOMP_AFTER}

# ---------------------------------------------------------------------------
# Disable block session
# ---------------------------------------------------------------------------
#Function_Block_Users "DISABLE"

echo "Fim Deploy Gold ${V_DAY_CHANGE} - "`date` >> ${BASE_FONT_DIRECTORY}/LogDeployGold${V_DB_DEPLOY}${V_DAY_CHANGE}.log

# ---------------------------------------------------------------------------
# Sent email with deployment logs
# ---------------------------------------------------------------------------
Function_Envia_Email_Change

V_SLACK_MESSAGE=${V_SLACK_MESSAGE}'"}'

echo ${V_SLACK_MESSAGE}  > ${BASE_FONT_DIRECTORY}/payload_deploy.txt

curl -H 'Content-Type: application/json; charset=utf-8' -d "${V_SLACK_MESSAGE}" ${V_SLACK_CHANNEL}

