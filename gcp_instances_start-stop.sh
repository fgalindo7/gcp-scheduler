#!/bin/bash
#
# Copyright 2017 fgalindo@talend.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#
#
################################################################################
#
# GCP scheduler - start, stop instances
#
################################################################################
#
#
#Scheduler to be run hourly as a cronjob under /etc/crontab
#Starts stops machines depending on their schedule and zone
#List of active environment names with their respective UTC schedule, e.g.:
#vm-fgalindo-windowsserver-datafabric-631-00055555,start;stop;<active_days>
#
#the script pulls the current names of environments from GCP,
#depending on the time zone, it generates the start and stop
#gcloud commands (Monday through Friday)
#
#For more information, see the README.md
#
source ~/.bashrc

## Global variables
#
# start_time=06
# stop_time=18
# weekends='off'
# weekdays='on'
# mon='on'
# tue='on'
# wed='on'
# thu='on'
# fri='on'

# [START make_directories]
function make_directories() {

if [ ! -d 'environments' ]; then
  mkdir environments
fi

if [ ! -d 'logs' ]; then
  mkdir logs
fi
}
# [STOP make_directories]


# [START get_current_time]
function get_current_time() {
    # date +"[option]"

    # [option]  result
    # %T     time; same as %H:%M:%S
    # %H     hour (00..23)
    # %w     day of week (0..6); 0 is Sunday
    # %u     day of week (1..7); 1 is Monday
    local utc_week_day_num=`date -u +"%u"`  # get the day of the week (in UTC) Monday is 1

    case $utc_week_day_num in
      1)
        utc_week_day='mon'
      ;;
      2)
        utc_week_day='tue'
      ;;
      3)
        utc_week_day='wed'
      ;;
      4)
        utc_week_day='thu'
      ;;
      5)
        utc_week_day='fri'
      ;;
      6)
        utc_week_day='sat'
      ;;
      7)
        utc_week_day='sun'
      ;;
    esac

    utc_hour=`date -u +"%H"`  # get the current hour (in UTC)
    time_stamp=`date -u +"%m.%d.%Y-%H%M%S"`
}
# [END get_current_time]



# [START get_current_instances]
function get_current_instances() {
    # list of NAME ZONE STATUS without header sorted by zone
    gcloud compute instances list | awk 'NR>1{print $1, $2, $NF}' > environments/gcp_instances_list.txt
}
# [END get_current_instances]


# [START replace_zone_with_city]
function replace_zone_with_city() {
    if [[ -f environments/gcp_instances_list.txt ]] ; then
        # make copy to keep zones
        cp environments/gcp_instances_list.txt environments/gcp_instances_list_raw.txt

        # replace zones with cities
        sed -i -e 's/asia-east1-a/taiwan/g' environments/gcp_instances_list.txt
        sed -i -e 's/asia-east1-c/taiwan/g' environments/gcp_instances_list.txt
        sed -i -e 's/asia-east1-b/taiwan/g' environments/gcp_instances_list.txt
        sed -i -e 's/asia-northeast1-c/tokyo/g' environments/gcp_instances_list.txt
        sed -i -e 's/asia-northeast1-a/tokyo/g' environments/gcp_instances_list.txt
        sed -i -e 's/asia-northeast1-b/tokyo/g' environments/gcp_instances_list.txt
        sed -i -e 's/asia-southeast1-b/singapore/g' environments/gcp_instances_list.txt
        sed -i -e 's/asia-southeast1-a/singapore/g' environments/gcp_instances_list.txt
        sed -i -e 's/australia-southeast1-a/sydney/g' environments/gcp_instances_list.txt
        sed -i -e 's/australia-southeast1-c/sydney/g' environments/gcp_instances_list.txt
        sed -i -e 's/australia-southeast1-b/sydney/g' environments/gcp_instances_list.txt
        sed -i -e 's/europe-west1-d/belgium/g' environments/gcp_instances_list.txt
        sed -i -e 's/europe-west1-c/belgium/g' environments/gcp_instances_list.txt
        sed -i -e 's/europe-west1-b/belgium/g' environments/gcp_instances_list.txt
        sed -i -e 's/europe-west2-c/london/g' environments/gcp_instances_list.txt
        sed -i -e 's/europe-west2-a/london/g' environments/gcp_instances_list.txt
        sed -i -e 's/europe-west2-b/london/g' environments/gcp_instances_list.txt
        sed -i -e 's/europe-west3-b/frankfurt/g' environments/gcp_instances_list.txt
        sed -i -e 's/europe-west3-c/frankfurt/g' environments/gcp_instances_list.txt
        sed -i -e 's/europe-west3-a/frankfurt/g' environments/gcp_instances_list.txt
        sed -i -e 's/us-central1-c/iowa/g' environments/gcp_instances_list.txt
        sed -i -e 's/us-central1-a/iowa/g' environments/gcp_instances_list.txt
        sed -i -e 's/us-central1-f/iowa/g' environments/gcp_instances_list.txt
        sed -i -e 's/us-central1-b/iowa/g' environments/gcp_instances_list.txt
        sed -i -e 's/us-east1-d/s_carolina/g' environments/gcp_instances_list.txt
        sed -i -e 's/us-east1-c/s_carolina/g' environments/gcp_instances_list.txt
        sed -i -e 's/us-east1-b/s_carolina/g' environments/gcp_instances_list.txt
        sed -i -e 's/us-east4-b/n_virginia/g' environments/gcp_instances_list.txt
        sed -i -e 's/us-east4-a/n_virginia/g' environments/gcp_instances_list.txt
        sed -i -e 's/us-east4-c/n_virginia/g' environments/gcp_instances_list.txt
        sed -i -e 's/us-west1-b/oregon/g' environments/gcp_instances_list.txt
        sed -i -e 's/us-west1-a/oregon/g' environments/gcp_instances_list.txt
        sed -i -e 's/us-west1-c/oregon/g' environments/gcp_instances_list.txt
      else
        echo "environments/gcp_instances_list.txt not found"
        exit 0
    fi
}
# [END replace_zone_with_city]



# [START create_instances_array]
function create_instances_array() {
  while IFS=' ' read -r line || [[ -n ${line} ]] ; do
    instances_arr+=(`echo ${line} | awk '{print $1;}'`)
  done < "environments/gcp_instances_list.txt"
}
# [END create_instances_array]



# [START stop_instances]
function stop_instances() {
  gcloud compute instances stop "$1" --zone "$2" >> logs/gpc_instances_start-stop_$time_stamp.log
}
# [END stop_instances]



# [START start_instances]
function start_instances() {
  #gcloud compute instances start "$1" --zone "$2" >> logs/gpc_instances_start-stop_$time_stamp.log
  echo ""
}
# [END start_instances]


# [START action_on_instance]
function action_on_instance() {
  local gcp_city=$1
  case $gcp_city in
    'singapore' )
            if [[ "10#${utc_hour}" -eq '10#00' ]]; then
              action='start'
            elif [[ "10#${utc_hour}" -eq '10#13' ]]; then
              action='stop'
            else
              action='none'
            fi
    ;;

    'belgium'|'frankfurt')
              if [[ "10#${utc_hour}" -eq '10#04' ]]; then
                action='start'
              elif [[ "10#${utc_hour}" -eq '10#16' ]]; then
                action='stop'
              else
                action='none'
              fi
    ;;

    'london' )
            if [[ "10#${utc_hour}" -eq '10#05' ]]; then
              action='start';
            elif [[ "10#${utc_hour}" -eq '10#17' ]]; then
              action='stop' ;
            else action='none' ; fi
    ;;

    's_carolina' )
            if [[ "10#${utc_hour}" -eq '10#10' ]]; then
              action='start'
            elif [[ "10#${utc_hour}" -eq '10#22' ]]; then
              action='stop'
            else
              action='none'
            fi
    ;;

    'n_virginia' )
              if [[ "10#${utc_hour}" -eq '10#10' ]]; then
                action='start'
              elif [[ "10#${utc_hour}" -eq '10#22' ]]; then
                action='stop'
              else
                action='none'
              fi
    ;;

    'iowa' )
              if [[ "10#${utc_hour}" -eq '10#11' ]]; then
                action='start'
                action='none'
              elif [[ "10#${utc_hour}" -eq '10#23' ]]; then
                action='stop'
                action='none'
              else
                action='none'
              fi
    ;;

    'oregon' )
              if [[ "10#${utc_hour}" -eq '10#13' ]]; then
                action='start'
              elif [[ "10#${utc_hour}" -eq '10#01' ]]; then
                action='stop'
              else
                action='none'
              fi
    ;;

    'sydney' )
              if [[ "10#${utc_hour}" -eq '10#20' ]]; then
                action='start'
              elif [[ "10#${utc_hour}" -eq '10#08' ]]; then
                action='stop'
              else
                action='none'
              fi
    ;;

    'tokyo' )
              if [[ "10#${utc_hour}" -eq '10#21' ]]; then
                action='start'
              elif [[ "10#${utc_hour}" -eq '10#09' ]]; then
                action='stop'
              else
                action='none'
              fi
    ;;

    'taiwan' )
              if [[ "10#${utc_hour}" -eq '10#22' ]]; then
                action='start'
              elif [[ "10#${utc_hour}" -eq '10#10' ]]; then
                action='stop'
              else
                action='none'
              fi
    ;;
  esac
}
# [END action_on_instance]



# [START instances_start_stop]
  function instances_start_stop() {
    # loop through instances to start or stop
    for i in "${instances_arr[@]}"; do {
      instance_name=${i}
      # echo "Instance: $instance_name"

      # get status of instance i
      status=`awk -v pat="$instance_name " '$0 ~ pat {print $3}' environments/gcp_instances_list_raw.txt`;
      # echo "Status: $status"

      # get city of instance i
      city=`awk -v pat="$instance_name " '$0 ~ pat {print $2}' environments/gcp_instances_list.txt`;
      # echo "City: $city"

      # get zone of instance i
      zone=`awk -v pat="$instance_name " '$0 ~ pat {print $2}' environments/gcp_instances_list_raw.txt`

      # action_on_instance function to see if instance should be started or stoppped
      action_on_instance $city
      # echo "Action: $action"
      # echo ""


      # make sure it's not a weekend before starting or stopping and it's not a repository
      if [[ $utc_week_day == 'sat' ]] || [[ $utc_week_day == 'sun' ]]; then
        echo "It is $utc_week_day, instance $instance_name will keep status $status."
        exit 0
      elif [[ $instance_name == *"support-docker-registry" ]]; then
        echo "Instance $instance_name is a support-docker-registry and should always keep status $status."
        exit 0
      elif [[ $instance_name == *"-00080135"* ]] || [[ $instance_name == *"-00086431"* ]]; then
        echo "Instance $instance_name has been hardcoded to stay up."
        exit 0
      else
        if [[ ${status} == 'TERMINATED' ]] && [[ ${action} == 'start' ]] ; then
          echo "==============================" >> logs/gpc_instances_start-stop_$time_stamp.log
          echo " Action: START instance" >> logs/gpc_instances_start-stop_$time_stamp.log
          start_instances "$instance_name" "${zone}"
          echo " Instance: $instance_name" >> logs/gpc_instances_start-stop_$time_stamp.log
          echo " Zone: ${zone}" >> logs/gpc_instances_start-stop_$time_stamp.log
          echo " Status: ${status}" >> logs/gpc_instances_start-stop_$time_stamp.log
          echo "" >> logs/gpc_instances_start-stop_$time_stamp.log

        elif [[ ${status} == 'RUNNING' ]] && [[ ${action} == 'stop' ]]; then
          echo "==============================" >> logs/gpc_instances_start-stop_$time_stamp.log
          echo " Action: STOP instance" >> logs/gpc_instances_start-stop_$time_stamp.log
          stop_instances "$instance_name" "${zone}"
          echo " Instance: $instance_name" >> logs/gpc_instances_start-stop_$time_stamp.log
          echo " Zone: ${zone}" >> logs/gpc_instances_start-stop_$time_stamp.log
          echo " Status: ${status}" >> logs/gpc_instances_start-stop_$time_stamp.log
          echo "" >> logs/gpc_instances_start-stop_$time_stamp.log

        else
          echo "==============================" >> logs/gpc_instances_start-stop_$time_stamp.log
          echo " Action: none" >> logs/gpc_instances_start-stop_$time_stamp.log
          echo " Instance: $instance_name" >> logs/gpc_instances_start-stop_$time_stamp.log
          echo " Zone: ${zone}" >> logs/gpc_instances_start-stop_$time_stamp.log
          echo " Status: ${status}" >> logs/gpc_instances_start-stop_$time_stamp.log
          echo "" >> logs/gpc_instances_start-stop_$time_stamp.log
        fi
      fi
  } done
}
# [START instances_start_stop]



# [MAIN start]
make_directories
get_current_time
get_current_instances
create_instances_array
replace_zone_with_city
instances_start_stop
# [END]
