####### DEGREE WORKS START SCRIPT ###############
#################################################
####### REQUIRED ENVIRONMENT VARIABLES ##########

export dw_user=dwadmin

# Can be set to "Classic" , "Web" , "Classic_Web"
export server_type=Classic

# Location of where this start script is located
export working_dir=/home/${dw_user}/cron/scripts

# Get this from the start script of any JAR app
export db_host=dwdbdev01.administrative.hbu.edu
export db_port=8010

# Get this from the classic host by running "sss core.amqp.broker.host | awk '{print $3}'"
export amqp_host=10.1.100.80

# Get this from the classic host  by running "sss core.amqp.broker.port | awk '{print $3}'"
export amqp_port=5672

# Variables required only for classic server (Specify the 'preq' & 'res' daemon here ONLY if the client has been configured for them)
export daemons='dap web tbe res'

# Variables required only for web server
# Get this from the classic host by running "sss classicConnector.serverNameOrIp | awk '{print $3}'"
export classic_host=dwappdev01.administrative.hbu.edu

# Get this from the classic host by running "env | grep DW_DAP08_PARAMS | sed 's/.*p//'"
export classic_port=7701

export tomcat_home=

# Timeout values
export jar_start_time=30
export tomcat_start_time=75
export cancel_auto_start=1500
export retry_interval=30
export log_file=dw.log
