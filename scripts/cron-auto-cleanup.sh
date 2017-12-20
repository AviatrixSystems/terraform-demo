#!/bin/sh

#-------------------------------------------------------------------------
# This script should be run fron cron to cleanup the demo environment after
# the configured number of hours since started.
# the build-demo.sh script creates a file demo.running once the demo is built
# successfully.
# this script uses the timestamp of that file to wait up to x hours after
# the creation time of that file before destroying it.
#-------------------------------------------------------------------------

TOP="$( cd "$(dirname "$0")/.." ; pwd -P )"

if [ ! -f ${TOP}/demo.running ]; then
    exit 0
fi

now=$(date +%s)
demo_created=$(date -r ${TOP}/demo.running +%s)
diff=$(( ${now} - ${demo_created} ))
max_run_time=$(( 8 * 3600 ))
echo "diference is ${diff}s (maximum run time is ${max_run_time}s)"
if [ ${diff} -gt ${max_run_time} ]; then
    ${TOP}/scripts/destroy-all.sh > ${TOP}/logs/destroy-all.log 2>&1
    rtn=$?
    if [ $rtn -ne 0 ]; then
        curl -s --user 'api:key-af33146f1b7bbda4e72993549946698e' \
             https://api.mailgun.net/v3/mailgun.aviatrix.live/messages \
             -F from='Aviatrix Demo Destroyer <mike@aviatrix.com>' \
             -F to=mike@aviatrix.com \
             -F subject='Failed to destroy environment' \
             -F text="hostname = $(hostname)"
    fi
fi
