instance#!/bin/bash

source ~/.bashrc

# Copyright 2017 Talend Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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

## Global variables
projects=('css-us' 'css-apac' 'css-emea' 'probable-sector-147517')
scheduler_label='scheduler'
archive_date_label='archive-date'
exceptions=('devops' 'fgalindo' 'support-docker-registry')
default_start_time='none'
default_stop_time='1800'
default_time_zone='est'
valid_time_zones=('CST' 'JST' 'IST' 'SGT' 'AEDT' 'AEST' 'CET' 'CEST' 'GMT' 'BSM' 'BRT' 'BRST' 'CST' 'CDT' 'EST' 'EDT' 'PST' 'PDT')
valid_days=('mon' 'tue' 'wed' 'thu' 'fri' 'sat' 'sun' 'all' 'weekdays' 'weekends')
#valid_hours=('0000' '0100' '0200' '0300' '0400' '0500' '0600' '0700' '0800' '0900' '1000' '1100' '1200' '1200' '1400' '1500' '1600' '1700' '1800' '1900' '2000' '2100' '2200' '2300')

# [MAIN start]
function main() {
  make_directories
  get_current_time
  get_current_instances
  instances_control
}
# [END]



# [START make_directories]
function make_directories() {

if [ ! -d 'environments' ]; then
  mkdir environments
fi

if [ ! -d 'logs' ]; then
  mkdir logs
fi
}
# [END make_directories]



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



# [START remove_exceptions]
function remove_exceptions() {
  # delete exceptions using sed
  # for exception in ${exceptions[@]}; do echo ${exception}; sed -i -e "/${exception}/d" environments/gcp_instances_list.txt; done
  for exception in "${exceptions[@]}"; do
    sed -i -e "/${exception}/d" environments/gcp_instances_list.txt;
  done
}
# [STOP remove_exceptions]



# [START create_instances_array]
function create_instances_array() {
  local instances_array
  while IFS=' ' read -r line || [[ -n ${line} ]] ; do
    instances_array+=($(echo ${line} | awk '{print $1;}'))
  done < "environments/gcp_instances_list.txt"
  echo "${instances_array[@]}"
}
# [STOP create_instances_array]


# [START get_current_instances]
function get_current_instances() {
	local project=$1
  # list of NAME ZONE STATUS without header sorted by zone
  gcloud compute instances list --project $project | awk 'NR>1{print $1, $2, $NF}' > environments/gcp_instances_list.txt
  # call function to remove all instances that are exceptions to the scheduler
  remove_exceptions
	instances_array=($(create_instances_array))
  echo "${instances_array[@]}"
}
# [STOP get_current_instances]



# [START get_scheduler_label]
function get_scheduler_label() {
	local instance_name=$1
  local instance_zone=$2
	local instance_project=$3

  local scheduler_label_key_raw=$(gcloud compute instances describe "$instance_name" --zone "$instance_zone" --project "$instance_project" | grep "$scheduler_label: ")
  # export scheduler_label_key_raw=$(gcloud compute instances describe $instance_name --zone "$instance_zone" --project "$instance_project" | grep "$scheduler_label: "); echo $scheduler_label_key_raw
  if [[ -z $scheduler_label_key_raw ]]; then
    local scheduler_key='none'
  else
    local scheduler_label_key=$(echo "${scheduler_label_key_raw}" | tr -d '[:space:]') # remove white spaces
    # export scheduler_label_key=$(echo "${scheduler_label_key_raw}" | tr -d '[:space:]'); echo $scheduler_label_key
    local scheduler_key=$(echo "${scheduler_label_key}" | sed -e "s/${scheduler_label}://") # remove scheduler label and column, "scheduler:"
    # export scheduler_key=$(echo "${scheduler_label_key}" | sed -e "s/${scheduler_label}://"); echo $scheduler_key
  fi
  # parse scheduler key
  local scheduler_key_array
  IFS='-' read -r -a scheduler_key_array <<< "$scheduler_key"

  # Call check_scheduler_key to confirm a valid label key
  is_scheduler_key_ok=$(check_scheduler_key "${scheduler_key_array[@]}")

  if [[ is_scheduler_key_valid == true ]]; then
    echo "${scheduler_key_array[@]}"
  else
    echo "none"
  fi
}
# [END get_scheduler_label]


# [START check_scheduler_label]
function check_scheduler_key(){
  local scheduler_key=$1
  local scheduler_key_length=${#scheduler_key[@]}

  # check1: length of array is 4
  if [[ "$scheduler_key_length" == 4 ]]; then
    local check1=true
    local str1="${scheduler_key[0]}"
    local str2="${scheduler_key[1]}"
    local str3="${scheduler_key[2]}"
    local str4="${scheduler_key[3]}"
  else
    local check1=false
  fi
  # check2: first string is number between 0-23 or 'default' or 'none'
  #TODO

  # check3: second string is number between 0-23 or 'default' or 'none'
  #TODO

  # check4: valid time_zone
  $check4=$(is_contained "$str3" "${valid_time_zones[@]}")

  # check5: valid day selection
  $check5=$(is_contained "$str4" "${valid_days[@]}")

  if [[ "$check1" == true ]] && [[ "$check2" == true ]] && [[ "$check3" == true ]] && [[ "$check4" == true ]] && [[ "$check5" == true ]]; then
     return 0 # 0 = true
  else
    return 1 # 1 = false
  fi
}
# [STOP check_scheduler_label]


# [START get_archive_date_label]
function get_archive_date_label() {
  local instance_name=$1
  local instance_zone=$2
	local instance_project=$3

  local archive_date_label_key_raw=$(gcloud compute instances describe "$instance_name" --zone "$instance_zone" --project "$instance_project" | grep "$archive_date_label: ")
  # export archive_date_label_key_raw=$(gcloud compute instances describe "$instance_name" --zone "$instance_zone" --project "$instance_project" | grep "$archive_date_label: "); echo $archive_date_label_key_raw
  if [[ -z $archive_date_label_key_raw ]]; then
    local archive_date_key='none'
  else
    local archive_date_label_key=$(echo "${archive_date_label_key_raw}" | tr -d '[:space:]') # remove white spaces
    # export archive_date_label_key=$(echo "${archive_date_label_key_raw}" | tr -d '[:space:]'); echo $archive_date_label_key
    local archive_date_key=$(echo "${archive_date_label_key}" | sed -e "s/${archive_date_label}://") # remove archive label and column, "archive:"
    # export archive_date_key=$(echo "${archive_date_label_key}" | sed -e "s/${archive_date_label}://"); echo $archive_date_key
  fi
  # parse archive key
  local archive_date_key_array
  IFS='-' read -r -a archive_date_key_array <<< "$archive_date_key"
  echo "${archive_date_key_array[@]}"
}
# [END get_archive_date_label]



# [START is_contained]
is_contained () {
  local element array="$1"
  shift
  for element; do [[ "$element" == "$array" ]] && return 0; done
  return 1
}
# [END is_contained]



# [START check_archive_date_label]
function check_archive_date_key(){
 # TODO
}
# [STOP check_archive_date_label]


# [START get_instance_status]
function get_instance_status() {
  local instance_name=$1
  local instance_status=$(awk -v pat="$instance_name " '$0 ~ pat {print $3}' environments/gcp_instances_list.txt)
  echo "$instance_status"
}
# [END get_instance_status]



# [START get_instance_zone]
function get_instance_zone() {
  local instance_name=$1
  local instance_zone=$(awk -v pat="$instance_name " '$0 ~ pat {print $2}' environments/gcp_instances_list.txt)
  echo "$instance_zone"
}
# [END get_instance_zone]



# [START get_instance_region]
function get_instance_region() {
  local instance_name=$1
  local instance_zone=$(get_instance_zone "$instance_name")

  case "$instance_zone" in
    "asia-east1"* )
    local instance_city="taiwan"
    # CST - China Standard Time, UTC/GMT +8 hours
    echo "$instance_city"
      ;;
    "asia-northeast1"* )
    local instance_city="tokyo"
    # JST - Japan Standard Time, UTC/GMT +9 hours
    echo "$instance_city"
      ;;
    "asia-south1"* )
    local instance_city="mumbai"
    # IST - India Standard Time, UTC/GMT +5:30 hours
    echo "$instance_city"
      ;;
    "asia-southeast1"* )
    local instance_city="singapore"
    # SGT - Singapore Time, UTC/GMT +8 hours
    echo "$instance_city"
      ;;
    "australia-southeast1"* )
    local instance_city="sydney"
    # AEDT - Australian Eastern Daylight Time, UTC/GMT +11 hours (between Oct 1 and Apr 2)
    # AEST - Australian Eastern Standard Time, UTC/GMT +10 hours (between Apr 2 and Oct 1)
    echo "$instance_city"
      ;;
    "europe-west1"* )
    local instance_city="belgium"
    # CET - Central European Time, UTC/GMT +1 hour (between Oct 29 and Mar 26)
    # CEST - Central European Summer Time, UTC/GMT +2 hours (between Mar 26 and Oct 29)
    echo "$instance_city"
      ;;
    "europe-west2"* )
    local instance_city="london"
    # GMT - Greenwich Mean Time, UTC/GMT no offset (between Oct 29 and Mar 26)
    # BSM - British Summer Time, UTC/GMT +1 hour (between Mar 26 and Oct 29)
    echo "$instance_city"
      ;;
    "europe-west3"* )
    local instance_city="frankfurt"
    # CET - Central European Time, UTC/GMT +1 hour (between Oct 29 and Mar 26)
    # CEST - Central European Summer Time, UTC/GMT +2 hours (between Mar 26 and Oct 29)
    echo "$instance_city"
      ;;
    "southamerica-east1"* )
    local instance_city="sao_paulo"
    # BRT- Brasilia Time, UTC/GMT -3 hours (from Feb 18 to Oct 14)
    # BRST - Brasilia Summer Time, UTC/GMT -2 hours (Oct 14 to Feb 18)
    echo "$instance_city"
      ;;
    "us-central1"* )
    local instance_city="iowa"
    # CST - Central Standard Time, UTC/GMT -6 hours (from Nov 5 to Mar 12)
    # CDT - Central Daylight Time, UTC/GMT -5 hours (from Mar 12 to Nov 5)
    echo "$instance_city"
      ;;
    "us-east1"* )
    local instance_city="s_carolina"
    # EST - Eastern Standard Time, UTC/GMT -5 hours (from Nov 5 to Mar 12)
    # EDT	- Eastern Daylight Time, UTC/GMT -4 hours (from Mar 12 to Nov 5)
    echo "$instance_city"
      ;;
    "us-east4"* )
    local instance_city="n_virginia"
    # EST - Eastern Standard Time, UTC/GMT -5 hours (from Nov 5 to Mar 12)
    # EDT	- Eastern Daylight Time, UTC/GMT -4 hours (from Mar 12 to Nov 5)
    echo "$instance_city"
      ;;
    "us-west1"* )
    local instance_city="oregon"
    # PST - Pacific Standard Time, UTC/GMT -8 hours (from Nov 5 to Mar 12)
    # PDT- Pacific Daylight Time, UTC/GMT -7 hours (from Mar 12 to Nov 5)
    echo "$instance_city"
      ;;
  esac
}
# [END get_instance_region]



# [START stop_instances]
function stop_instances() {
  local instance_name="$1"
  local instance_zone="$2"
  local instance_project="$3"
  gcloud compute instances stop "$instance_name" --zone "$instance_zone" --project "$instance_project" >> "logs/gpc_instance_stop_$time_stamp.log"
}
# [END stop_instances]



# [START start_instances]
function start_instances() {
  local instance_name="$1"
  local instance_zone="$2"
  local instance_project="$3"
  gcloud compute instances start "$instance_name" --zone "$instance_zone" --project "$instance_project" >> "logs/gpc_instance_start_$time_stamp.log"
}
# [END start_instances]



# [START delete_instances]
function delete_instances() {
  local instance_name="$1"
  local instance_zone="$2"
  local instance_project="$3"
  gcloud compute instances delete "$instance_name" --zone "$instance_zone" --project "$instance_project" >> "logs/gpc_instance_delete_$time_stamp.log"
}
# [END delete_instances]



# [START snapshot_instances]
function snapshot_instances() {
  local instance_name="$1"
  local instance_zone="$2"
  local instance_project="$3"
  local snapshot_name=$(echo "${instance_name}" | sed -e 's/vm-/ss-/') # remove instance and substitute for ss, "vm-"
  gcloud compute disks snapshot "$instance_name" --zone "$instance_zone" --project "$instance_project" --snapshot-names="$snapshot_name" >> "logs/gpc_instance_snapshot_$time_stamp.log"
}
# [END snapshot_instances]



# [START action_on_instance]
function action_on_instance() {
  local city=$1
  case $city in
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



# [START instances_control]
function instances_control() {
	local project=$1
  instances_array=($(get_current_instances $project))
  # loop through instances to start or stop

  for instance in "${instances_array[@]}"; do {
    local instance_name="$instance"
    # echo "Instance: $instance_name"

    # get status of instance
    local status=$(get_instance_status "$instance_name")
    # echo "Status: $status"

    # get zone of instance
    local zone=$(get_instance_zone "$instance_name")
    # echo "Zone: $zone"

    # get city of instance
    local region=$(get_instance_region "$instance_name")
    # echo "City: $city"

    # get scheduler label of instance
    local scheduler_array=($(get_scheduler_label "$instance_name" "$zone" "$project"))
    # echo "Scheduler: ${scheduler_array[@]}"
    start_time="${scheduler_array[0]}"
    # echo "start time: $start_time"
    stop_time="${scheduler_array[1]}"
    # echo "stop time: $stop_time"
    time_zone="${scheduler_array[2]}"
    # echo "time zone: $time_zone"
    days="${scheduler_array[3]}"
    # echo "days: $days"


    # get archive-date of instance
    local archive_array=($(get_archive_date_label "$instance_name" "$zone" "$project"))
    # echo "Archive-date: ${archive_array[@]}"
    month="${archive_array[0]}"
    # echo "month: $month"
    day="${archive_array[1]}"
    # echo "day: $day"
    year="${archive_array[2]}"
    # echo "year: $year"


    # action_on_instance function to see if instance should be started or stoppped
    action_on_instance "$time_zone"
    # echo "Action: $action"
    # echo ""

    # make sure it's not a weekend before starting or stopping
    if [[ "$utc_week_day" != 'sat' &&  "$utc_week_day" != 'sun' ]] ; then
      if [[ ${status} == 'TERMINATED' && ${action} == 'start' ]] ; then
        echo "==============================" >> logs/gpc_instances_start-stop_$time_stamp.log
        echo " Action: START instance" >> logs/gpc_instances_start-stop_$time_stamp.log
        start_instances "$instance_name" "${zone}"
        echo " Instance: $instance_name" >> logs/gpc_instances_start-stop_$time_stamp.log
        echo " Zone: ${zone}" >> logs/gpc_instances_start-stop_$time_stamp.log
        echo " Status: ${status}" >> logs/gpc_instances_start-stop_$time_stamp.log
        echo "" >> logs/gpc_instances_start-stop_$time_stamp.log

      elif [[ ${status} == 'RUNNING' && ${action} == 'stop' ]]; then
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
    else
      echo "It's $utc_week_day, crontab takes weekends off."
      echo "Instances will keep their current state"
      exit 0
    fi
  } done
}
# [END instances_control]


main "$@"
