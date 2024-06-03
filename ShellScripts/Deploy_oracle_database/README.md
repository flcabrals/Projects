# ORACLE-DEPLOY-CHANGES

These scripts are designed to meet the needs of automatically executing scripts for changes to the Oracle database. <br>
This process purpose to reduce the execution time of the scripts during the pre-defined window and allow the possibility of a greater volume of changes proposed by the business areas. <br>

## Installation

Edit or create the file ibmdba on folder /etc. <br>
If the file ibmdba was exists on /etc directory include the deploy dir folder : <br>
DEPLOY_DIR=<folder of your choice> <br>

If the file ibmdba not exists create and include the information bellow. <br>
```
#===========================================================
# /etc/ibmdba
#
# Versao 2.0 (Oracle Support only)
# Arquivo de configuracao utilizado pelos scripts que sao
# usados pelo equipe de Suporte DB para realizar atividades
# de Banco de Dados.
#
# Observacao
# ==========
# Este arquivo eh de uso exclusivo da equipe DBA/IBM.
# Nao modifique nem exclua este arquivo sem a previa consulta/
# autorizacao da IBM.
# Em caso de Phaseout do cliente solicitar remocao desse arquivo.
# O arquivo deve estar como root:system permissao 644
#
# Owner
# =====
# IBM SDC Brasil, Suporte DB/DC
#===========================================================
#
DEPLOY_DIR='folder of your choice'
``` 

Download these scripts and unzip on your folder. <br>

Here is a description of each script. <br>

The directory structure is :
```
<DEPLOY_DIR>/<INSTANCE_NAME>/automatizacao-de-deploy-gold/<DATE_TO_DEPLOY>/<CHANGE>/<SCHEMA>/ 

Where :  DEPLOY_DIR     = Base directory
         INSTANCE_NAME  = Name of the Oracle instance 
         DATE_TO_DEPLOY = Date of the deploy will apply (format : YYYYMMDD)
         CHANGE         = Number of the change
         SCHEMA         = Schema to apply the scripts
```

### ScriptDeployChangesOracle.ksh
It will perform the online deployment using the parameters defined in the configuration file for each instance. (Ge. Schemas and instances that the scripts will be applied to.) <br>
The script uses connection to the environment through Wallet, being necessary to configure the instance that each owner will connect, or through a single user because the process changes the user using the option "current_schema". <br>
```
Format: ScriptDeployChangesOracle.ksh <INSTANCE_DEPLOY> <YAML_SEQUENCE_CHANGES>

Where:  INSTANCE_DEPLOY       = INSTANCE_NAME (Same name of config file name)
        YAML_SEQUENCE_CHANGES = sequence_change_oracle.yaml
		                YAML file is in <DEPLOY_DIR>/<INSTANCE_NAME>/automatizacao-de-deploy-gold/
```
