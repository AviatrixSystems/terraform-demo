#!/bin/bash

#-----------------------------------------------------------------------------
# Common functions and variables used by aviatrix-demo scripts
# TOP must be defined by the caller of this script (or source)
#-----------------------------------------------------------------------------

export CONTROLLER=${HOSTNAME/demo/controller}
export DEMO_RUNNER=${HOSTNAME}
export DEMOUSER=$(echo $HOSTNAME | awk -F. '{ print $2 }')
export DEMORUNNINGFILE=${TOP}/demo.running
export MAILGUN_API_KEY="api:key-af33146f1b7bbda4e72993549946698e"

#-----------------------------------------------------------------------------
# checks to see if the demo environment is running now or not
#-----------------------------------------------------------------------------
function is_demo_running() {
    [ -f $DEMORUNNINGFILE ]
}

#-----------------------------------------------------------------------------
# convert from seconds to days, hours, minutes, seconds
# Arguments:
#  totalSeconds - $1 - number of seconds to convert
# @see original source here: https://stackoverflow.com/a/12199816
#-----------------------------------------------------------------------------
function human_readable_time() {
    local totalSeconds=$1

    local sec=0
    local min=0
    local hour=0
    local day=0

    if [ $totalSeconds -gt 59 ]; then
        sec=$(( $totalSeconds % 60 ))
        totalSeconds=$(( $totalSeconds / 60 ))
        if [ $totalSeconds -gt 59 ]; then
            min=$(( $totalSeconds % 60 ))
            totalSeconds=$(( $totalSeconds / 60 ))
            if [ $totalSeconds -gt 23 ];then
                hour=$(( $totalSeconds % 24 ))
                day=$(( $totalSeconds / 24 ))
            else
                hour=$totalSeconds
            fi
        else
            min=$totalSeconds
        fi
    else
        sec=$totalSeconds
    fi

    local delim=""
    if [ $day -gt 0 ]; then
        printf "${delim}%02d" ${day}
        delim=":"
    fi
    if [ "$delim" != "" -o $hour -gt 0 ]; then
        printf "${delim}%02d" ${hour}
        delim=":"
    fi
    if [ "$delim" != "" -o $min -gt 0 ]; then
        printf "${delim}%02d" ${min}
        delim=":"
    fi
    if [ "$delim" != "" -o $sec -gt 0 ]; then
        printf "${delim}%02d" ${sec}
        delim=":"
    fi

    # add new line
    printf "\n"
}

#-----------------------------------------------------------------------------
# waits until the controller IP is accessible via a curl request (i.e., a
# successsful login request)
# Arguments:
#   $1 - publicIp - the public ip address of the controller
#   $2 - password - the password for the user "admin" to the controller
# Returns:
#   0 when successful; 1 if controller is not accessible after 10 tries
#-----------------------------------------------------------------------------
function wait_for_controller_up() {
    publicIp="$1"
    password="$2"
    tries=1
    success=0
    while [ $tries -lt 10 -a $success -eq 0 ]; do
        echo "[Aviatrix Controller] Attempt $tries ..."
        output=$(curl -k "https://$publicIp/v1/api?action=login&username=admin&password=$password" 2>/dev/null)
        if [ $? -eq 0 ]; then
            echo "    output: $output"
            echo "$output" | grep "authorized successfully" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                success=1
            fi
        else
            echo "    output: $output"
            sleep 10
        fi
        tries=$((tries + 1))
    done
    if [ $success -eq 0 ]; then
        echo "Unable to connect to controller on https://$publicIp using admin:$password"
        return 2
    fi
    return 0
}

#-----------------------------------------------------------------------------
# Sends an email to let user know demo has been destroyed
#-----------------------------------------------------------------------------
function send_demo_destroyed_email() {
    curl -s --user "$MAILGUN_API_KEY" \
         https://api.mailgun.net/v3/mailgun.aviatrix.live/messages \
         -F from='Aviatrix Demo <mike@aviatrix.com>' \
         -F to=${DEMOUSER}@aviatrix.com \
         -F subject='[AVIATRIX DEMO] Your demo environment has been destroyed' \
         -F html="${DEMOUSER} -<br><br>Your demo environment has been destroyed.  Login (via SSH) to ${DEMO_RUNNER} and run 'aviatrix-demo build' to rebuild it."
}

#-----------------------------------------------------------------------------
# Sends an email to let user know demo is ready
# Arguments:
#   current_password - $1 - the admin password for this environment
#-----------------------------------------------------------------------------
function send_demo_ready_email() {
    local current_password="$1"
    if [ "$current_password" == "" ]; then
        current_password="-not set-"
    fi
    curl -s --user "$MAILGUN_API_KEY" \
         https://api.mailgun.net/v3/mailgun.aviatrix.live/messages \
         -F from='Aviatrix Demo <mike@aviatrix.com>' \
         -F to=${DEMOUSER}@aviatrix.com \
         -F subject='[AVIATRIX DEMO] Your demo environment is ready' \
         -F html="${DEMOUSER} -<br><br>Your demo environment is ready at https://${CONTROLLER}.<br><br>You can login with username <b>admin</b> and password <b>${current_password}</b>.<br><br>If you would like to make any changes, please SSH (with Putty on Windows or via Terminal on Mac) to ${DEMO_RUNNER} with username ubuntu.<br><br>Please remember this demo environment will be automatically destroyed in 8 hours.<br>"
}
