#!/bin/sh

#-------------------------------------------------------------------------
# This script should be run fron cron to cleanup the demo environment after
# the configured number of hours since started.
# the build-demo.sh script creates a file demo.running once the demo is built
# successfully.
# this script uses the timestamp of that file to wait up to x hours after
# the creation time of that file before destroying it.
#-------------------------------------------------------------------------

TOP="$( cd "$(dirname $(readlink -f $0))/.." ; pwd -P )"

# if the demo is not running then we don't need to tear it down
if [ ! -f ${TOP}/demo.running ]; then
    exit 0
fi

now=$(date +%s)
demo_created=$(date -r ${TOP}/demo.running +%s)
diff=$(( ${now} - ${demo_created} ))
max_run_time=$(( 8 * 3600 ))

if [ ${diff} -gt ${max_run_time} ]; then
    OUTPUT=${TOP}/logs/destroy-all.$(date +%Y%m%d.%H%M).log
    ${TOP}/scripts/destroy-all.sh > ${OUTPUT} 2>&1
    rtn=$?
    if [ $rtn -ne 0 ]; then
        if [ $rtn -ne 5 ]; then # locked if exit value is 5
            curl -s --user 'api:key-af33146f1b7bbda4e72993549946698e' \
                 https://api.mailgun.net/v3/mailgun.aviatrix.live/messages \
                 -F from='Aviatrix Demo Destroyer <mike@aviatrix.com>' \
                 -F to=mike@aviatrix.com \
                 -F subject='Failed to destroy environment' \
                 -F text="hostname = $(hostname)"
            # keep the log file around so we can look at it later
            # keep demo.running around so we can try again
        else
            # delete the output file since it should just contain a note
            # about the file being locked
            rm -f ${OUTPUT}
        fi
    else
        rm -f ${TOP}/demo.running
        # move the output file to a "success" log file
        mv ${OUTPUT} ${TOP}/logs/destroy-all.log
    fi
fi
