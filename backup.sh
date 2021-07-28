#/bin/bash
# init time to check sync time
seconds_init=`date +%s`

# Get latest vaccination data and users from production
echo 'get /root/backups/backup_vaccination.json' | sftp root@crvs.gm
echo 'get /root/backups/backup_users.json' | sftp root@crvs.gm

# Get, print and store the mongodb container name in a var
CONTAINER_NAME=`docker ps | grep mongo | awk '{print $NF}'`
echo Container name : $CONTAINER_NAME

# copy fresh 
docker cp backup_users.json $CONTAINER_NAME:/tmp
docker cp backup_vaccination.json $CONTAINER_NAME:/tmp
docker exec $CONTAINER_NAME mongoimport --host localhost --db gambia --collection vaccination --mode=merge --file /tmp/backup_vaccination.json
docker exec $CONTAINER_NAME mongoimport --host localhost --db gambia --collection users --mode=merge --file /tmp/backup_users.json

# Generate a local copy of the mongodb
echo Local backup of mongo db
backup_date=`date +'%Y%m%d'`
machine_name=`hostnamectl | grep hostname |  awk '{print($NF);}'`
echo machine name ${machine_name}
docker exec $CONTAINER_NAME mongoexport --host localhost --db gambia --collection vaccination > backup_vaccination_local.json
tar_name=backup_${machine_name}_${backup_date}.tgz
tar czvf ${tar_name} backup_vaccination.json

# push copy to production
echo put ${tar_name} | sftp root@crvs.gm

# calculate time consumed
seconds_end=`date +%s`
echo Done in `expr ${seconds_end} - ${seconds_init}` seconds