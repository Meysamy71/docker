#/bin/bash

BACKUP_PATH=/var/dockers/backup
LOG_PATH=/var/dockers/log
LOG_DATE=`date +%Y.%m.%d.%H:%M`
CONTAINER_NUMBER=`docker ps --format '{{.Names}}'|wc -l`

func_log(){

if [[ $1 -eq 0 ]]
    then
        echo "Docker $5 $2 in $3 Successfully" >> $4/$2/$2.log
    else
        echo "Docker $5 $2 in $3 Error" >> $4/$2/$2.log
    fi
}

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
    
    func_log $? $CONTAINER_NAME $LOG_DATE $LOG_PATH "Commit"

#Docker Image Save and Zip    
    docker image save $CONTAINER_NAME:backup | xz  > $BACKUP_PATH/$CONTAINER_NAME/$CONTAINER_NAME.$LOG_DATE.tar.xz 
    
    func_log $? $CONTAINER_NAME $LOG_DATE $LOG_PATH "Image save"

#Rsync Backup
    rsync -az $BACKUP_PATH/$CONTAINER_NAME/ devops@192.168.18.132:/home/devops/dockers/$CONTAINER_NAME >> /dev/null 2>&1
    
    func_log $? $CONTAINER_NAME $LOG_DATE $LOG_PATH "Sync"

#Docker Image Remove Container Backup Tag    
    docker image rm $CONTAINER_NAME:backup >> /dev/null 2>&1
    
    func_log $? $CONTAINER_NAME $LOG_DATE $LOG_PATH "Image remove"

echo "=================" >> $LOG_PATH/$CONTAINER_NAME/$CONTAINER_NAME.log

done

#Backup rm 2 days
find $BACKUP_PATH -name *.tar.xz -mtime 2 -exec rm -rf {} \;
