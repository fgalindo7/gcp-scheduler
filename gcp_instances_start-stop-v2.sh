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
# GCP scheduler - start, stop, snapshot and shutdown instances
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
source ~/.bash_profile

## Global variables
#projects=("css-us" "css-apac" "css-emea" "probable-sector-147517" "enablement-183818")
projects=("scheduler-test-181019")
scheduler_label="scheduler"
archive_label="archive-date"
exceptions=("devops" "support-docker-registry")
default_start_time="none"
default_stop_time="1800"
default_time_zone="est"
valid_time_zones=("cst" "jst" "ist" "sgt" "aedt" "aest" "cet" "cest" "gmt" "bsm" "brt" "brst" "ct" "cdt" "est" "edt" "pst" "pdt")
valid_days=("mon" "tue" "wed" "thu" "fri" "sat" "sun" "all" "weekdays" "weekends")

# [MAIN start]
function main() {
  make_directories
  get_current_time

  for project in "${projects[@]}"; do
    get_current_instances "$project"
    instances_control "$project"
  done
}
# [END]


# [START make_directories]
function make_directories () {

if [ ! -d "environments" ]; then
  mkdir environments
fi

if [ ! -d "logs" ]; then
  mkdir logs
fi
}
# [END make_directories]



# [START get_current_time]
function get_current_time () {
    # date +"[option]"
    # [option]  result
    # %T     time; same as %H:%M:%S
    # %H     hour (00..23)
    # %w     day of week (0..6); 0 is Sunday
    # %u     day of week (1..7); 1 is Monday
    local utc_week_day_num=`date -u +"%u"`  # get the day of the week (in UTC) Monday is 1

    case $utc_week_day_num in
      1)
        utc_week_day="mon"
      ;;
      2)
        utc_week_day="tue"
      ;;
      3)
        utc_week_day="wed"
      ;;
      4)
        utc_week_day="thu"
      ;;
      5)
        utc_week_day="fri"
      ;;
      6)
        utc_week_day="sat"
      ;;
      7)
        utc_week_day="sun"
      ;;
    esac

    local utc_hour=`date -u +"%H"`  # get the current hour (in UTC)
    local time_stamp=`date -u +"%m.%d.%Y-%H%M%S"`
}
# [END get_current_time]



# [START remove_exceptions]
function remove_exceptions () {
  # delete exceptions using sed
  # for exception in ${exceptions[@]}; do echo ${exception}; sed -i -e "/${exception}/d" environments/gcp_instances_list.txt; done
  for exception in "${exceptions[@]}"; do
    sed -i -e "/${exception}/d" environments/gcp_instances_list.txt;
  done
}
# [END remove_exceptions]



# [START create_instances_array]
function create_instances_array () {
  local instances_array
  while IFS=" " read -r line || [[ -n ${line} ]] ; do
    instances_array+=($(echo ${line} | awk '{print $1;}'))
  done < "environments/gcp_instances_list.txt"
  echo "${instances_array[@]}"
}
# [END create_instances_array]



# [START get_current_instances]
function get_current_instances () {
	local project=$1
  # list of NAME ZONE STATUS without header sorted by zone
  gcloud compute instances list --project $project | awk 'NR>1{print $1, $2, $NF}' > environments/gcp_instances_list.txt
  # call function to remove all instances that are exceptions to the scheduler
  remove_exceptions
	instances_array=($(create_instances_array))
  echo "${instances_array[@]}"
}
# [END get_current_instances]



# [START get_scheduler_label]
function get_scheduler_label () {
  #get_scheduler_label "testing-vagrant" "us-central1-f" "scheduler-test-181019"
  local instance_name="$1" # instance_name="testing-vagrant"
  local instance_zone="$2" # instance_zone="us-central1-f"
	local instance_project="$3" # instance_project="scheduler-test-181019"

  local scheduler_label_key_raw=$(gcloud compute instances describe "$instance_name" --zone "$instance_zone" --project "$instance_project" | grep "$scheduler_label: ")
  # scheduler_label_key_raw=$(gcloud compute instances describe $instance_name --zone "$instance_zone" --project "$instance_project" | grep "$scheduler_label: ")
  # echo $scheduler_label_key_raw
  if [[ -z "$scheduler_label_key_raw" ]]; then
    local scheduler_key="none"
  else
    local scheduler_label_key_no_spaces=$(echo "${scheduler_label_key_raw}" | tr -d "[:space:]") # remove spaces
    # scheduler_label_key=$(echo "${scheduler_label_key_raw}" | tr -d "[:space:]"); echo $scheduler_label_key
    local scheduler_key=$(echo "${scheduler_label_key_no_spaces}" | sed -e "s/${scheduler_label}://") # remove scheduler label and column, "scheduler:"
    #scheduler_key=$(echo "${scheduler_label_key}" | sed -e "s/${scheduler_label}://");
    # echo "$scheduler_key"
  fi

  # parse scheduler key into array with individual fields
  local scheduler_key_array
  IFS="-" read -r -a scheduler_key_array <<<"$scheduler_key"
  # echo "${scheduler_key_array[@]}"

  # Call check_scheduler_key to confirm a valid label key
  local is_scheduler_key_valid=$(check_scheduler_key_array scheduler_key_array[@])
  # echo "$is_scheduler_key_valid"

  if [[ $is_scheduler_key_valid == true ]]; then
    echo "${scheduler_key_array[@]}"
  else
    echo "none"
  fi
}
# [END get_scheduler_label]


# [START check_scheduler_key_array]
function check_scheduler_key_array () {
  local result
  local keys_array=("${!1}")
  #echo "${keys_array[2]}"
  local check1=true # check for valid length of array  (len(array) == 4)
  local check2=true # check for valid start time
  local check3=true # check for valid stop time
  local check4=true # check for valid time zone
  local check5=true # check for valid days of the week
  local start_time
  local stop_time
  local t_zone
  local days

  # check1: length of array is 4
  if [[ "${#keys_array[@]}" == 4 ]]; then
    local str1="${keys_array[0]}"
    local str2="${keys_array[1]}"
    local str3="${keys_array[2]}"
    local str4="${keys_array[3]}"
  else
    check1=false
  fi


  # check2: is str1 an integer between 0000-2359 or "default" or "none"?
  check2=$(check_time $str1)
  if [[ "$check3" ]]; then
    local start_time=$(remove_leading_zeros $str1)
  fi

  # check3: is str2 an integer between 0000-2359 or "default" or "none"?
  check3=$(check_time $str2)
  if [[ "$check3" ]]; then
    local stop_time=$(remove_leading_zeros $str2)
  fi

  # check4: valid time_zone
  check4=$(is_contained "$str3" "${valid_time_zones[@]}")
  #echo "$check4"

  # check5: valid day selection
  check5=$(is_contained "$str4" "${valid_days[@]}")

  if [[ "$check1" == true ]] && [[ "$check2" == true ]] && [[ "$check3" == true ]] && [[ "$check4" == true ]] && [[ "$check5" == true ]]; then
    result="true"
  else
    result="false"
  fi

  echo "$result"
}
# [END check_scheduler_key_array]


# [START check_day]
function check_day () {
  local result
  local reg_ex='^[0-9]+$'
  local day=$1

  if [[ $day =~ $reg_ex ]] && [[ $day -ge 1 ]] && [[ $day -le 31 ]]; then
    result="true"
  else
    result="false"
  fi
  echo "$result"
}
# [END check_day]


# [START check_month]
function check_month () {
  local result
  local reg_ex='^[0-9]+$'
  local month=$1

  if [[ $month =~ $reg_ex ]] && [[ $month -ge 1 ]] && [[ $month -le 31 ]]; then
    result="true"
  else
    result="false"
  fi
  echo "$result"
}
# [END check_month]


# [START check_year]
function check_year () {
  local result
  local reg_ex='^[0-9]+$'
  local year=$1

  if [[ $year =~ $reg_ex ]] && [[ $year -ge 2018 ]] && [[ $year -le 2999 ]]; then
    result="true"
  else
    result="false"
  fi
  echo "$result"
}
# [END check_year]


# [START check_time]
function check_time () {
  local result
  local reg_ex='^[0-9]+$'
  local time=$1

  if [[ $time =~ $reg_ex ]]; then
    result="true"
  elif [[ "$time" == "default" ]] || [[ "$time" == "none" ]]; then
    result="true"
  elif ! [[ $time -le 2359 ]] && ! [[ $time -ge 0 ]] ; then
    result="false"
  else
    result="false"
  fi
  echo "$result"
}
# [END check_time]


# [START remove_leading_zeros]
function remove_leading_zeros () {
  local num=$1
  if [[ "$num" == "0000" ]]; then
    num=0
    echo "$num"
  elif [[ "$num" == "0"* ]]; then
    num=$(echo "$time" | sed 's/^0*//') # remove leading zeros
    echo "$num"
  else
    echo "$num"
  fi
}
# [END remove_leading_zeros]


# [START is_contained]
function is_contained () {
  local result="false"
  local element array="$1"
  shift # http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_09_07.html
  for element; do
    if [[ "$element" == "$array" ]]; then
      result="true"
      break
    fi
  done
  echo "$result"
}
# [END is_contained]


# [START get_archive_label]
function get_archive_label () {
  #get_archive_label "testing-vagrant" "us-central1-f" "scheduler-test-181019"
  local instance_name="$1" # instance_name="testing-vagrant"
  local instance_zone="$2" # instance_zone="us-central1-f"
	local instance_project="$3" # instance_project="scheduler-test-181019"

  local archive_label_key_raw=$(gcloud compute instances describe "$instance_name" --zone "$instance_zone" --project "$instance_project" | grep "$archive_label: ")
  # archive_label_key_raw=$(gcloud compute instances describe "$instance_name" --zone "$instance_zone" --project "$instance_project" | grep "$archive_label: "); echo $archive_label_key_raw
  # echo $archive_label_key_raw
  if [[ -z $archive_label_key_raw ]]; then
    local archive_key="none"
  else
    local archive_label_key=$(echo "${archive_label_key_raw}" | tr -d "[:space:]") # remove white spaces
    # archive_label_key=$(echo "${archive_label_key_raw}" | tr -d "[:space:]"); echo $archive_label_key
    local archive_key=$(echo "${archive_label_key}" | sed -e "s/${archive_label}://") # remove archive label and column, "archive:"
    # archive_key=$(echo "${archive_label_key}" | sed -e "s/${archive_label}://"); echo $archive_key
    # echo "$archive_key"
  fi

  # parse archive key into array with individual fields
  local archive_key_array
  IFS="-" read -r -a archive_key_array <<<"$archive_key"
  # echo "${archive_key_array[@]}"

  # Call check_scheduler_key to confirm a valid label key
  local is_archive_key_valid=$(check_archive_key_array archive_key_array[@])
  # echo "$is_scheduler_key_valid"

  if [[ $is_archive_key_valid == true ]]; then
    echo "${archive_key_array[@]}"
  else
    echo "none"
  fi
}
# [END get_archive_label]


# # [START check_archive_key_array]
function check_archive_key_array () {
  local result
  local keys_array=("${!1}")
  local check1=true # check for valid length of array (len(array) == 3)
  local check2=true # check for valid day
  local check3=true # check for valid month
  local check4=true # check for valid year
  local archive_day
  local archive_month
  local archive_year

  # check1: length of array is 3
  if [[ "${#keys_array[@]}" == 3 ]]; then
    local str1="${keys_array[0]}"
    local str2="${keys_array[1]}"
    local str3="${keys_array[2]}"
  else
    check1=false
  fi

  # check2: str1 is an integer between 1 and 12
  check2=$(check_day $str1)
  if [[ "$check2" ]]; then
    local archive_day=$(remove_leading_zeros $str1)
  fi

  # check3: str2 is an integer between 1 and 31
  check3=$(check_month $str2)
  if [[ "$check3" ]]; then
    local archive_month=$(remove_leading_zeros $str2)
  fi

  # check4: str3 is an integer between 2018 and 2999
  check4=$(check_year $str3)
  if [[ "$check4" ]]; then
    local archive_year=$(remove_leading_zeros $str3)
  fi

  if [[ "$check1" == true ]] && [[ "$check2" == true ]] && [[ "$check3" == true ]] && [[ "$check4" == true ]]; then
    result="true"
  else
    result="false"
  fi

  echo "$result"
}
# # [END check_archive_key_array]


# [START get_instance_status]
function get_instance_status () {
  local instance_name=$1
  local instance_status=$(awk -v pat="$instance_name " '$0 ~ pat {print $3}' environments/gcp_instances_list.txt)
  echo "$instance_status"
}
# [END get_instance_status]



# [START get_zone_time]
function get_zone_time () {
  local instance_zone="$1"

  case "$instance_zone" in
    "cst" )
    # CST - China Standard Time, UTC/GMT +8 hours
      ;;
    "jst" )
    # JST - Japan Standard Time, UTC/GMT +9 hours
      ;;
    "ist" )
    # IST - India Standard Time, UTC/GMT +5:30 hours
      ;;
    "sgt" )
    # SGT - Singapore Time, UTC/GMT +8 hours
      ;;
    "aedt" )
    # AEDT - Australian Eastern Daylight Time, UTC/GMT +11 hours (between Oct 1 and Apr 2)
      ;;
    "aest" )
    # AEST - Australian Eastern Standard Time, UTC/GMT +10 hours (between Apr 2 and Oct 1)
      ;;
    "cet" )
    # CET - Central European Time, UTC/GMT +1 hour (between Oct 29 and Mar 26)
      ;;
    "cest" )
    # CEST - Central European Summer Time, UTC/GMT +2 hours (between Mar 26 and Oct 29)
      ;;
    "gmt" )
    # GMT - Greenwich Mean Time, UTC/GMT no offset (between Oct 29 and Mar 26)
    "bsm" )
    # BSM - British Summer Time, UTC/GMT +1 hour (between Mar 26 and Oct 29)
      ;;
    "cet" )
    # CET - Central European Time, UTC/GMT +1 hour (between Oct 29 and Mar 26)
      ;;
    "cest" )
    # CEST - Central European Summer Time, UTC/GMT +2 hours (between Mar 26 and Oct 29)
      ;;
    "brt" )
    # BRT- Brasilia Time, UTC/GMT -3 hours (from Feb 18 to Oct 14)
      ;;
    "brst" )
    # BRST - Brasilia Summer Time, UTC/GMT -2 hours (Oct 14 to Feb 18)
      ;;
    "ct" )
    # CT - Central Standard Time, UTC/GMT -6 hours (from Nov 5 to Mar 12)
      ;;
    "cdt" )
    # CDT - Central Daylight Time, UTC/GMT -5 hours (from Mar 12 to Nov 5)
      ;;
    "est" )
    # EST - Eastern Standard Time, UTC/GMT -5 hours (from Nov 5 to Mar 12)
      ;;
    "edt" )
    # EDT	- Eastern Daylight Time, UTC/GMT -4 hours (from Mar 12 to Nov 5)
      ;;
    "us-east4" )
    # EST - Eastern Standard Time, UTC/GMT -5 hours (from Nov 5 to Mar 12)
    # EDT	- Eastern Daylight Time, UTC/GMT -4 hours (from Mar 12 to Nov 5)
      ;;
    "us-west1" )
    # PST - Pacific Standard Time, UTC/GMT -8 hours (from Nov 5 to Mar 12)
    # PDT- Pacific Daylight Time, UTC/GMT -7 hours (from Mar 12 to Nov 5)
      ;;
  esac
}
# # [END get_zone_time]



# [START stop_instances]
function stop_instances () {
  local instance_name="$1"
  local instance_zone="$2"
  local instance_project="$3"
  gcloud compute instances stop "$instance_name" --zone "$instance_zone" --project "$instance_project" >> "logs/gpc_instance_stop_$time_stamp.log"
}
# [END stop_instances]



# [START start_instances]
function start_instances () {
  local instance_name="$1"
  local instance_zone="$2"
  local instance_project="$3"
  gcloud compute instances start "$instance_name" --zone "$instance_zone" --project "$instance_project" >> "logs/gpc_instance_start_$time_stamp.log"
}
# [END start_instances]



# [START delete_instances]
function delete_instances () {
  local instance_name="$1"
  local instance_zone="$2"
  local instance_project="$3"
  gcloud compute instances delete "$instance_name" --zone "$instance_zone" --project "$instance_project" >> "logs/gpc_instance_delete_$time_stamp.log"
}
# [END delete_instances]



# [START snapshot_instances]
function snapshot_instances () {
  local instance_name="$1"
  local instance_zone="$2"
  local instance_project="$3"
  local snapshot_name=$(echo "${instance_name}" | sed -e "s/vm-/ss-/") # snapshots share the instance name with a different prefix: "vm-instance" --> "ss-instance"
  gcloud compute disks snapshot "$instance_name" --zone "$instance_zone" --project "$instance_project" --snapshot-names="$snapshot_name" >> "logs/gpc_instance_snapshot_$time_stamp.log"
}
# [END snapshot_instances]



# [START action_on_instance]
function action_on_instance () {
  local city="$1"
  case "$city" in
    "singapore" )
            if [[ "10#${utc_hour}" -eq "10#00" ]]; then
              action="start"
            elif [[ "10#${utc_hour}" -eq "10#13" ]]; then
              action="stop"
            else
              action="none"
            fi
    ;;

    "belgium"|"frankfurt")
              if [[ "10#${utc_hour}" -eq "10#04" ]]; then
                action="start"
              elif [[ "10#${utc_hour}" -eq "10#16" ]]; then
                action="stop"
              else
                action="none"
              fi
    ;;

    "london" )
            if [[ "10#${utc_hour}" -eq "10#05" ]]; then
              action="start";
            elif [[ "10#${utc_hour}" -eq "10#17" ]]; then
              action="stop" ;
            else action="none" ; fi
    ;;

    "s_carolina" )
            if [[ "10#${utc_hour}" -eq "10#10" ]]; then
              action="start"
            elif [[ "10#${utc_hour}" -eq "10#22" ]]; then
              action="stop"
            else
              action="none"
            fi
    ;;

    "n_virginia" )
              if [[ "10#${utc_hour}" -eq "10#10" ]]; then
                action="start"
              elif [[ "10#${utc_hour}" -eq "10#22" ]]; then
                action="stop"
              else
                action="none"
              fi
    ;;

    "iowa" )
              if [[ "10#${utc_hour}" -eq "10#11" ]]; then
                action="start"
                action="none"
              elif [[ "10#${utc_hour}" -eq "10#23" ]]; then
                action="stop"
                action="none"
              else
                action="none"
              fi
    ;;

    "oregon" )
              if [[ "10#${utc_hour}" -eq "10#13" ]]; then
                action="start"
              elif [[ "10#${utc_hour}" -eq "10#01" ]]; then
                action="stop"
              else
                action="none"
              fi
    ;;

    "sydney" )
              if [[ "10#${utc_hour}" -eq "10#20" ]]; then
                action="start"
              elif [[ "10#${utc_hour}" -eq "10#08" ]]; then
                action="stop"
              else
                action="none"
              fi
    ;;

    "tokyo" )
              if [[ "10#${utc_hour}" -eq "10#21" ]]; then
                action="start"
              elif [[ "10#${utc_hour}" -eq "10#09" ]]; then
                action="stop"
              else
                action="none"
              fi
    ;;

    "taiwan" )
              if [[ "10#${utc_hour}" -eq "10#22" ]]; then
                action="start"
              elif [[ "10#${utc_hour}" -eq "10#10" ]]; then
                action="stop"
              else
                action="none"
              fi
    ;;
  esac
}
# [END action_on_instance]



# [START instances_control]
function instances_control () {
	local project="$1"
  instances_array=($(get_current_instances $project))
  # loop through instances to start or stop

  for instance in "${instances_array[@]}"; do
    local instance_name="$instance"
    echo "Instance: $instance_name"

    # get status of instance
    local status=$(get_instance_status "$instance_name")
    echo "Status: $status"

    # get scheduler label of instance
    local scheduler_array=($(get_scheduler_label "$instance_name" "$zone" "$project"))
    echo "scheduler: ${scheduler_array[@]}"
    if [[ "${#scheduler_array[@]}" -eq 4 ]]; then
      start_time="${scheduler_array[0]}"
      echo "start time: $start_time"
      stop_time="${scheduler_array[1]}"
      echo "stop time: $stop_time"
      time_zone="${scheduler_array[2]}"
      echo "time zone: $time_zone"
      days="${scheduler_array[3]}"
      echo "days: $days"
    else
      start_time="${scheduler_array[0]}"
      echo "start time: $start_time"
      stop_time="${scheduler_array[0]}"
      echo "stop time: $stop_time"
      time_zone="${scheduler_array[0]}"
      echo "time zone: $time_zone"
      days="${scheduler_array[0]}"
      echo "days: $days"
    fi

    # get time of the instance
    local instance_time=$(get_instance_time "$time_zone")
    echo "Instance time: $instance_time"


    # get archive-date of instance
    local archive_array=($(get_archive_label "$instance_name" "$zone" "$project"))
    echo "archive-date: ${archive_array[@]}"
    if [[ "${#archive_array[@]}" -eq 3 ]]; then
      month="${archive_array[0]}"
      echo "month: $month"
      day="${archive_array[1]}"
      echo "day: $day"
      year="${archive_array[2]}"
      echo "year: $year"
    else
      month="${archive_array[0]}"
      echo "month: $month"
      day="${archive_array[0]}"
      echo "day: $day"
      year="${archive_array[0]}"
      echo "year: $year"
    fi

    # get date of the instance
    local instance_date=$(get_instance_date "$time_zone")
    echo "Instance date: $instance_time"


    # action_on_instance function to see if instance should be started or stoppped
    action_on_instance "$time_zone"
    # echo "Action: $action"
    # echo ""

    # make sure it"s not a weekend before starting or stopping
    if [[ "$utc_week_day" != "sat" &&  "$utc_week_day" != "sun" ]] ; then
      if [[ ${status} == "TERMINATED" && ${action} == "start" ]] ; then
        echo "==============================" >> logs/gpc_instances_start-stop_$time_stamp.log
        echo " Action: START instance" >> logs/gpc_instances_start-stop_$time_stamp.log
        start_instances "$instance_name" "${zone}"
        echo " Instance: $instance_name" >> logs/gpc_instances_start-stop_$time_stamp.log
        echo " Zone: ${zone}" >> logs/gpc_instances_start-stop_$time_stamp.log
        echo " Status: ${status}" >> logs/gpc_instances_start-stop_$time_stamp.log
        echo "" >> logs/gpc_instances_start-stop_$time_stamp.log

      elif [[ ${status} == "RUNNING" && ${action} == "stop" ]]; then
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
  done
}
# [END instances_control]


main "$@"
