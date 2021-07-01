#! /bin/ksh
# DW_nightly_maint.sh
# This script is intended to be run from crontab.
# It runs the nightly maintenance processes for DegreeWorks.
# Output goes to a dated log file.
# Disclaimer: No warrantee or support is provided for the use of this script
# Please customize as needed.
#
# Sample crontab entry to run at 4am daily:
# 00 04 * * *   /home/dwadmin/cron/scripts/DW_nightly_maint.sh 2>&1
#
export CLASSPATH=
export PATH=$PATH:$HOME/cron/scripts:/u01/app/dw/dwdev/app/scripts
export ORACLE_HOME=/u01/app/oracle/product/12.1.0/client_1
export DWHOME=/u01/app/ellucian/dw/dwdev
export ORACLE_SID=DWDEV
export TWO_TASK=$ORACLE_SID
. $DWHOME/app/scripts/dwenv $DWHOME/dwenv.config
env|sort> /home/dwadmin/cron/scripts/cron_env.txt
#
# create log path and name with date
export LOGFILE="/home/dwadmin/cron/logs/`/bin/date +dw_maint_%y%m%d.log`"
#
echo "Starting nightly extracts"               >> $LOGFILE
date                                           >> $LOGFILE
# debugoff                                       >> $LOGFILE
# RAD11FORCE=ALL
echo "Starting BannerExtract Course"           >> $LOGFILE
date                                           >> $LOGFILE
bannerextract course                           >> $LOGFILE
echo "Ending BannerExtract Course"             >> $LOGFILE
date                                           >> $LOGFILE
echo "Starting BannerExtract Student"          >> $LOGFILE
bannerextract student                          >> $LOGFILE
echo "Ending BannerExtract Student"            >> $LOGFILE
date                                           >> $LOGFILE

# bannerextract advisor                          >> $LOGFILE
#
echo "Starting nightly maintenance"             >> $LOGFILE
date                                            >> $LOGFILE
# remove all output and temp files older than 20 days
rmoldfiles $DWHOME/admin/dgwspool 20           >> $LOGFILE
rmoldfiles $DWHOME/admin/logdebug 20           >> $LOGFILE
rmoldfiles $DWHOME/admin/tmp 20                >> $LOGFILE
#
echo "Reload picklists with ucx12job"           >> $LOGFILE
ucx12job                                        >> $LOGFILE
#
echo "Restarting dap daemons"                   >> $LOGFILE
daprestart                                      >> $LOGFILE
echo "Restarting web daemons"                   >> $LOGFILE
webrestart                                      >> $LOGFILE
#
echo "Done nightly maintenance"                 >> $LOGFILE
date                                            >> $LOGFILE
#
# Uncomment and specify email to send the log file to if desired
# mailx -s DW_nightly_results  jbates@hbu.edu  < $LOGFILE
echo DW nightly updates results log file attached | mailx -r "jbates@hbu.edu" -s "HBU DW nightly updates results" -a ${LOGFILE} -S smtp="smtp.hbu.edu:25" -S ssl-verify=ignore jbates@hbu.edu
