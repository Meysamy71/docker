#/bin/bash

BACKUP_PATH=/var/dockers/backup
LOG_PATH=/var/dockers/log
LOG_DATE=`date +%Y.%m.%d.%H:%M`
CONTAINER_NUMBER=`docker ps --format '{{.Names}}'|wc -l`

for ((i=1;i<=$CONTAINER_NUMBER;i++))
do
    CONTAINER_NAME=`docker ps --format '{{.Names}}'|head -n $i |tail -n 1`
#Create Backup and Log Path    
    if [[ ! -d $CONTAINER_NAME  ]]
    then
            mkdir -p $BACKUP_PATH/$CONTAINER_NAME
    fi
    
    if [[ ! -d $CONTAINER_NAME  ]]
    then
            mkdir -p $LOG_PATH/$CONTAINER_NAME
    fi
#Docker Container Commit	    
    docker commit $CONTAINER_NAME $CONTAINER_NAME:backup >> /dev/null 2>&1
    if [[ $? -eq 0 ]]
    then
	echo "Docker commit $CONTAINER_NAME in $LOG_DATE Successfully" >> $LOG_PATH/$CONTAINER_NAME/$CONTAINER_NAME.log
    else	
	echo "Docker commit $CONTAINER_NAME in $LOG_DATE Error" >> $LOG_PATH/$CONTAINER_NAME/$CONTAINER_NAME.log
    fi
#Docker Image Save and Zip    
    docker image save $CONTAINER_NAME:backup | xz  > $BACKUP_PATH/$CONTAINER_NAME/$CONTAINER_NAME.$LOG_DATE.tar.xz 
    if [[ $? -eq 0 ]]
    then
	echo "Docker image save $CONTAINER_NAME in $LOG_DATE Successfully" >> $LOG_PATH/$CONTAINER_NAME/$CONTAINER_NAME.log
    else	
	echo "Docker image save $CONTAINER_NAME in $LOG_DATE Error" >> $LOG_PATH/$CONTAINER_NAME/$CONTAINER_NAME.log
    fi
#Rsync Backup
    rsync -az $BACKUP_PATH/$CONTAINER_NAME/ devops@192.168.18.132:/home/devops/dockers/$CONTAINER_NAME >> /dev/null 2>&1
    if [[ $? -eq 0 ]]
    then
	echo "Docker image scp $CONTAINER_NAME in $LOG_DATE Successfully" >> $LOG_PATH/$CONTAINER_NAME/$CONTAINER_NAME.log
    else	
	echo "Docker image scp $CONTAINER_NAME in $LOG_DATE Error" >> $LOG_PATH/$CONTAINER_NAME/$CONTAINER_NAME.log
    fi
#Docker Image Remove Container Backup Tag    
    docker image rm $CONTAINER_NAME:backup >> /dev/null 2>&1
    if [[ $? -eq 0 ]]
    then
	echo "Docker image remove $CONTAINER_NAME:backup in $LOG_DATE Successfully" >> $LOG_PATH/$CONTAINER_NAME/$CONTAINER_NAME.log
    else	
	echo "Docker image remove $CONTAINER_NAME:backup in $LOG_DATE Error" >> $LOG_PATH/$CONTAINER_NAME/$CONTAINER_NAME.log
    fi

echo "=================" >> $LOG_PATH/$CONTAINER_NAME/$CONTAINER_NAME.log

done

#Backup rm 2 days
find $BACKUP_PATH -name *.tar.xz -mtime 2 -exec rm -rf {} \;

