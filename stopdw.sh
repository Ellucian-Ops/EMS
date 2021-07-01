#!/bin/ksh

#################################################
####### DEGREE WORKS STOP SCRIPT ###############
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

echo -e "\nDegree Works services should be stopped with this script either as $dw_user or root user\n"

#  CONDITION TO STOP WEB APPS
if [[ `echo "$server_type"` == "Web" || `echo "$server_type"` == "Classic_Web" ]];
then

#  CREATES ARRAY OF CURRENTLY RUNNING JAR APPS
dw_apps=`ps -ef | grep java | grep -v grep | grep -v org.apache.catalina.startup.Bootstrap | grep -v transitexecutor | awk '{print $(NF)}' | sed 's/.*\///' | sed 's/$*.jar//'`

#  LOOP TO STOP JAR APPS ONE BY ONE
for app in ${dw_apps[*]}
do
  pkill -f $app
  echo -e "$app has been stopped\n"
  sleep 1
done

# STOP TOMCAT
tomcat_pid() {
    echo `ps aux | grep org.apache.catalina.startup.Bootstrap | grep -v grep | awk '{ print $2 }'`
}

    pid=$(tomcat_pid)
    if [ -n "$pid" ]
    then
        SHUTDOWN_WAIT=15
# GETS tomcat_home DIRECTORY FROM RUNNING PROCESSES
        tomcat_home=`ps aux | grep org.apache.catalina.startup.Bootstrap | grep -v grep | awk '{print $(NF-2)}' | sed 's/.*=//' | sed 's/$*\/temp//'`
        echo -e "Stopping Tomcat"
        if [ `whoami` == "$dw_user" ]; then
                cd $tomcat_home/bin && $tomcat_home/bin/shutdown.sh
        else
                /bin/su -c "cd $tomcat_home/bin && $tomcat_home/bin/shutdown.sh" - $dw_user
        fi
    let kwait=$SHUTDOWN_WAIT
    count=0
    count_by=5
    until [ `ps -p $pid | grep -c $pid` = '0' ] || [ $count -gt $kwait ]
    do
        echo -e "\nWaiting for processes to exit. Timeout before we kill the pid: ${count}/${kwait}"
        sleep $count_by
        let count=$count+$count_by;
    done

    if [ $count -gt $kwait ]; then
        echo -e "\nKilling processes which didn't stop after $SHUTDOWN_WAIT seconds"
        kill -9 $pid
    fi
    else
        echo -e "\nTomcat is not running"
    fi
fi

#  CONDITION TO STOP CLASSIC DAEMONS
if [[ `echo "$server_type"` == "Classic" || `echo "$server_type"` == "Classic_Web" ]];
        then
#  SOURCE CLASSIC ENV VARIABLES
          . /home/${dw_user}/.profile
                for daemon in $daemons
                do
# Determining user to stop application
                  if [ `whoami` == "$dw_user" ]; then
                    echo "${daemon}stop"
                    ${daemon}stop
                  else
                    echo "${daemon}stop"
                    /bin/su -c ${daemon}stop - $dw_user
                    ${daemon}stop
                  fi
                sleep 1
                done
echo -e "\nAll Classic daemons are down\n"
ps -ef | grep db=$dw_user | grep -v grep | awk '{print $2}' | xargs kill -9 > /dev/null 2>&1
fi
echo -e "\n\nAll services were stopped on `date`\n\n"

# Clears logs & creates new file with correct permissions
#cd $working_dir
#rm -rf $log_file
#touch $log_file
#chmod 777 $log_file
#chown $dw_user $log_file
