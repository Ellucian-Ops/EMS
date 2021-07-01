#!/bin/ksh

#################################################
####### DEGREE WORKS START SCRIPT ###############
#################################################

#################################################

# Logging configuration
exec 1>>$working_dir/$log_file
exec 2>>/dev/null

# If this condition is satisfied, server has classic daemons as well as web applications
[ $server_type == "Classic_Web"  ] &&  echo -e "\nThis server has classic daemons as well as web applications!"

# If this condition is satisfied, server has classic daemons only
[ $server_type == "Classic"  ] && echo -e "\nDegree Works Classic Server"

# If this condition is satisfied, server has web applications only
[ $server_type == "Web"  ] && echo -e "\nDegree Works Web Server"

# Check for 'system uptime' to delay startup if system has just been rebooted
[ "`echo $(awk '{print $1}' /proc/uptime) / 60 | bc`" -lt "2" ] && echo Delaying startup by 2 minutes due to reboot... && sleep 120


echo -e "\nDegree Works services will be started as $dw_user user on `date`\n"


#  CONDITION TO START CLASSIC DAEMONS
if [[ `echo "$server_type"` == "Classic" || `echo "$server_type"` == "Classic_Web" ]];
        then
#  SOURCE CLASSIC ENV VARIABLES
          . /home/${dw_user}/.profile

#  TEST CONNECTIVITY TO DATABASE FROM CLASSIC SERVER
        echo -e "\nChecking connection to Database server from Classic server.....\n"
        let kwait=$cancel_auto_start
        count=0
        count_by=$retry_interval
        SID=`echo $IMAGE_DBNAME`
        until [ `timeout 1 bash -c "tnsping $SID" | grep OK | cut -f1 -d" "` = 'OK' ]
        do
            echo -e "\n$SID database is unreachable. Will retry connecting in $count_by seconds"
            echo -e "\nPlease check if the database in $db_host has been started and is reachable at port $db_port\n"
            echo -e "\nTimeout before services stop trying to be started automatically: ${count}s/${kwait}s"
            sleep $count_by
            let count=$count+$count_by;
        if [ $count -gt $kwait ]; then
           echo -e "\nAuto startup of DW classic daemons has been cancelled since database $SID is still unreachable after $cancel_auto_start seconds"
           exit 1
        fi
        done
        echo -e "\nConnection to $SID connection was successfull!\n"

#  TEST CONNECTIVITY TO RABBITMQ FROM CLASSIC SERVER
        count=0
        echo -e "\nChecking connection to Rabbitmq from Classic Server....."
        amqp_status=`timeout 1 bash -c "$working_dir/host_port_status.pl $amqp_host $amqp_port"`
        echo -e "\n$amqp_status"
        until [ `echo $amqp_status | cut -f1 -d" "` = 'Connection' ]
        do
            echo -e "\nRabbitmq is unreachable. Will retry connecting in $count_by seconds"
            echo -e "\nPlease verify if Rabbitmq has been started on $amqp_host and is reachable at port $amqp_port\n"
            echo -e "Timeout before services stop trying to be started automatically: ${count}s/${kwait}s"
            sleep $count_by
            let count=$count+$count_by;
            amqp_status=`timeout 1 bash -c "$working_dir/host_port_status.pl $amqp_host $amqp_port"`
            echo -e "\n$amqp_status\n"
     if [ $count -gt $kwait ]; then
           echo -e "\nAuto startup of DW classic daemons apps has been cancelled since Rabbitmq is still unreachable after $cancel_auto_start seconds"
           exit 1
     fi
     done

#  SCRIPT TO START CLASSIC DAEMONS
          echo -e "\nStarting Classic daemons\n"
                for daemon in $daemons
                do
# Determining user to start application
                  if [ `whoami` == "$dw_user" ]; then
                    echo "${daemon}start"
                    ${daemon}start
                  else
                    echo "${daemon}start"
                    /bin/su -c ${daemon}start - $dw_user
                  fi
                sleep 7
                done
          echo -e "\nAll Classic daemons have been started\n\n"
fi
########################### END OF CLASSIC DAEMONS #############################



#  CONDITION TO START WEB APPLICATIONS
if [[ `echo "$server_type"` == "Web" || `echo "$server_type"` == "Classic_Web" ]];
then

#  TEST CONNECTIVITY TO DATABASE FROM WEB SERVER
echo -e "\nChecking connectivity to Database server from Web server.....\n"
let kwait=$cancel_auto_start
count=0
count_by=$retry_interval
db_status=`timeout 1 bash -c "$working_dir/host_port_status.pl $db_host $db_port"`
echo -e "\n$db_status"
sleep 2
until [ `echo $db_status | cut -f1 -d" "` = 'Connection' ]
     do
            echo -e "\nDatabase is unreachable. Will attempt to connect again in $count_by seconds"
            echo -e "\nPlease check if the database in $db_host has been started and is reachable at port $db_port"
            echo -e "\nTimeout before services stop trying to be started automatically: ${count}s/${kwait}s"
            sleep $count_by
            let count=$count+$count_by;
            db_status=`timeout 1 bash -c "$working_dir/host_port_status.pl $db_host $db_port"`
            echo -e "\n$db_status"
     if [ $count -gt $kwait ]; then
                echo -e "\nAuto startup of DW web apps has been cancelled since the database is still unreachable after $cancel_auto_start seconds"
                exit 1
     fi
     done


#  TEST CONNECTIVITY TO RABBITMQ FROM WEB SERVER
     echo -e "\nChecking connection to Rabbitmq from Web Server....."
     amqp_status=`timeout 1 bash -c "$working_dir/host_port_status.pl $amqp_host $amqp_port"`
     echo -e "\n$amqp_status"
     count=0
     sleep 2
     until [ `echo $amqp_status | cut -f1 -d" "` = 'Connection' ]
     do
            echo -e "\nRabbitmq is unreachable. Will attempt to connect again in $count_by seconds"
            echo -e "\nPlease verify if Rabbitmq has been started on $amqp_host and is reachable at port $amqp_port"
            echo -e "\nTimeout before web services stop trying to be started automatically: ${count}s/${kwait}s"
            sleep $count_by
            let count=$count+$count_by;
            amqp_status=`timeout 1 bash -c "$working_dir/host_port_status.pl $amqp_host $amqp_port"`
            echo -e "\n$amqp_status"
     if [ $count -gt $kwait ]; then
                 echo -e "\nAuto startup of DW web apps has been cancelled since Rabbitmq is still unreachable after $cancel_auto_start seconds"
                 exit 1
     fi
     done

#  TEST CONNECTIVITY TO CLASSIC DAEMONS FROM WEB SERVER
        echo -e "\n\nChecking connection to classic daemons from Web Server....."
        classic_status=`timeout 1 bash -c "$working_dir/host_port_status.pl $classic_host $classic_port"`
        echo -e "\n$classic_status"
                count=0
        sleep 2
        until [ `echo $classic_status | cut -f1 -d" "` = 'Connection' ]
        do
            echo -e "\nThe Classic daemons are unreachable. Will attempt to connect again in $count_by seconds"
            echo -e "\nPlease verify if the classic daemons in $classic_host have been started and are reachable at port $classic_port"
            echo -e "\nTimeout before web services stop trying to be started automatically: ${count}s/${kwait}s"
            sleep $count_by
            let count=$count+$count_by;
            classic_status=`timeout 1 bash -c "$working_dir/host_port_status.pl $classic_host $classic_port"`
            echo -e "\n$classic_status"
     if [ $count -gt $kwait ]; then
         echo -e "\nAuto startup of DW web apps has been cancelled since the classic daemons are still unreachable after $cancel_auto_start seconds"
         exit 1
     fi
     done


echo -e "\n\nStarting DW Web Applications\n"

jar_scripts=/home/${dw_user}/scripts

# Array storing file names of start scripts for apps
dw_apps=`ls $jar_scripts/start_*`

# Loop for starting JAR apps
for app in ${dw_apps[*]}
do

# Loop to read start script to determine JAR app being started
  while IFS='' read -r LINE || [ -n "${LINE}" ]; do
  if [ `echo $LINE | grep java | sed 's/.*LOCATION\///' | sed 's/$*.jar//' | awk '{print $1}'` ]; then
        app_name=`echo $LINE | grep java | sed 's/.*LOCATION\///' | sed 's/$*.jar//' | awk '{print $1}'`
  fi
  done < $app

# Get list of current running JAR apps
  running_apps=`ps -ef | grep java | grep -v grep | grep -v org.apache.catalina.startup.Bootstrap | grep -v transitexecutor | awk '{print $(NF)}' | sed 's/.*\///' | sed 's/$*.jar//'`

# Condition to check if JAR app is already running
  if [[ `echo "$running_apps" | grep -w "$app_name"` == "$app_name" ]]; then
    echo -e "\n$app_name is already running\n"
    continue
  fi
  echo -e "\n$app_name is starting\n\n"

# Determining user to start application
  if [ `whoami` == "$dw_user" ]; then
  $app
  else
  /bin/su -c $app - $dw_user
  fi
  sleep 12

# Finding log file of application that was started and tailing the logs
  app_log=`ls -ltr $jar_scripts/logs | awk '{print $(NF)}'`
  app_log=`echo $app_log | awk '{print $(NF)}'`
  timeout $jar_start_time bash -c "tail -f $jar_scripts/logs/$app_log"
done

#  TOMCAT STARTUP
tomcat_pid() {
    echo `ps aux | grep org.apache.catalina.startup.Bootstrap | grep -v grep | awk '{ print $2 }'`
}

pid=$(tomcat_pid)
    if [ -n "$pid" ]
    then
        echo -e "\nTomcat is already running\n"
    else
        # Start tomcat
        echo -e "\n\nStarting tomcat\n\n"

# Determining user to start application
        if [ `whoami` == "$dw_user" ]; then
        rm -rf $tomcat_home/work/* ; rm -rf $tomcat_home/temp/* ; cd $tomcat_home/bin && $tomcat_home/bin/startup.sh
        else
        /bin/su -c "rm -rf $tomcat_home/work/* ; rm -rf $tomcat_home/temp/* ; cd $tomcat_home/bin && $tomcat_home/bin/startup.sh" - $dw_user
        fi
        sleep 3
        timeout $tomcat_start_time bash -c "tail -f $tomcat_home/logs/catalina.out"
    fi

echo -e "\nThe following applications finished starting on `date`:\n`ps -ef|grep java|grep -v grep`\n"
fi
