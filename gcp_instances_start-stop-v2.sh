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
projects=("$1")
#projects=("scheduler-test-181019")
#projects=("css-us" "css-apac" "css-emea" "probable-sector-147517" "batch-volume-testing" "enablement-183818")
owner_label="owner"
owner_label_ifs="-"
email_time="1000" #10am
archive_time="2200" #10pm
scheduler_label="scheduler"
scheduler_label_ifs="-"
weekdays_ifs="_"
archive_label="archive-date"
archive_label_ifs="-"
default_start_time="none"
default_stop_time="1800"
default_time_zone="est"
valid_time_zones=("aedt" "aest" "jst" "cst" "sgt" "ist" "cest" "cet" "bsm" "gmt" "brst" "brt" "edt" "cdt" "est" "ct" "pdt" "pst")
valid_days=("mon" "tue" "wed" "thu" "fri" "sat" "sun" "all" "weekdays" "weekends")
tmp_dir="environments"
logs_dir="logs"
logs_file="gcp-logs"
logs_file_format="log"
envs_list="gcp"
envs_list_format="txt"
export time_stamp


# [MAIN start]
function main() {
  make_directories
  for project in "${projects[@]}"; do
    envs_list="$envs_list-$project"
    instances_control "$project"
    #rm -rf "$tmp_dir/$envs_list-$time_stamp.$envs_list_format"
  done
}
# [END]


# [START make_directories]
function make_directories () {

  if [ ! -d "$tmp_dir" ]; then
    mkdir "$tmp_dir"
  fi

  if [ ! -d "$logs_dir" ]; then
    mkdir "$logs_dir"
  fi
}
# [END make_directories]


# [START get_current_instances]
function get_current_instances () {
	local project="$1"
  local time_stamp="$2"
  # list of NAME ZONE STATUS without header in a file
  gcloud compute instances list --project $project | awk 'NR>1{print $1, $2, $NF}' > "$tmp_dir/$envs_list-$time_stamp.$envs_list_format"
  # return as echo an array of instances
  instances_array=$(gcloud compute instances list --project $project | awk 'NR>1{print $1}')
  echo "${instances_array[@]}"
}
# [END get_current_instances]


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
  local t_zone
  local days_of_the_week_array

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
  # check3: is str2 an integer between 0000-2359 or "default" or "none"?
  check3=$(check_time $str2)
  # check4: valid time_zone
  check4=$(is_contained "$str3" "${valid_time_zones[@]}")
  # check5: valid day selection
  days_of_the_week_array=($(parse_string_into_array "-" "$str4"))
  # echo "$days_of_the_week_array"

  check5=$(check_days_key_array "${days_of_the_week_array[@]}")

  if [[ "$check1" == true ]] && [[ "$check2" == true ]] && [[ "$check3" == true ]] && [[ "$check4" == true ]] && [[ "$check5" == true ]]; then
    result="true"
  else
    result="false"
  fi

  echo "$result"
}
# [END check_scheduler_key_array]


# [START check_days_key_array]
function check_days_key_array () {
  local result="false"
  local days_array=("${!1}")

  if [[ "${#days_array[@]}" -ge 0 ]]; then
    if [[ "${days_array[@]}" == "weekdays" ]] || [[ "${days_array[@]}" == "weekend" ]] || [[ "${days_array[@]}" == "weekends" ]] || [[ "${days_array[@]}" == "all" ]]; then
      result="true"
    else
      for day in "${days_array[@]}"; do
        result=$(is_contained "$day" "${valid_days[@]}")
        result="true"
      done
    fi
  fi
  echo "$result"
}
# [END check_days_key_array]


# [START check_start_stop_today
function check_start_stop_today () {
  local result="false"
  local day_of_the_week="$1"
  # Shift all arguments to the left ($1 gets lost)
  shift # http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_09_07.html
  local days_array=("$@")

  # convert day of the week to lowercase string
  day_of_the_week=$(echo "$day_of_the_week" | tr '[:upper:]' '[:lower:]')

  for day in "${days_array[@]}"; do

    if [[ "$day" == "all" ]]; then
      result="true"
    else
      if [[ ( "$day" == "weekend" ||  "$day" == "weekends" ) && ( "$day_of_the_week" == "sat" || "$day_of_the_week" == "sun" ) ]]; then
        result="true"
        break
      elif [[ ( "$day" == "weekday" ||  "$day" == "weekdays" ) && ( "$day_of_the_week" == "mon" || "$day_of_the_week" == "tue" || "$day_of_the_week" == "wed" || "$day_of_the_week" == "thu" || "$day_of_the_week" == "fri" ) ]]; then
        result="true"
        break
      elif [[ ( "$day" == "mon" ) && ( "$day_of_the_week" == "mon") ]]; then
        result="true"
        break
      elif [[ ( "$day" == "tue" ) && ( "$day_of_the_week" == "tue") ]]; then
        result="true"
        break
      elif [[ ( "$day" == "wed" ) && ( "$day_of_the_week" == "wed") ]]; then
        result="true"
        break
      elif [[ ( "$day" == "thu" ) && ( "$day_of_the_week" == "thu") ]]; then
        result="true"
        break
      elif [[ ( "$day" == "fri" ) && ( "$day_of_the_week" == "fri") ]]; then
        result="true"
        break
      elif [[ ( "$day" == "sat" ) && ( "$day_of_the_week" == "sat") ]]; then
        result="true"
        break
      elif [[ ( "$day" == "sun" ) && ( "$day_of_the_week" == "sun") ]]; then
        result="true"
        break
      else
        result="false"
      fi
    fi
  done

  echo "$result"

}
# [END check_start_stop_today]



# [START check_archive_today
# check_archive_today "$instance_zone_date" "$instance_archive_date"
function check_archive_today () {
  local date1="$1"
  local date2="$2"
  result="false"

  if [[ "$date1" == "$date2" ]]; then
    result="true"
  else
    result="false"
  fi

  echo "$result"
}
# [END check_archive_today]


# [START check_archive_key_array]
function check_archive_key_array () {
  local result
  local keys_array=("${!1}")
  local check1=true # check for valid length
  local check2=true # check for valid day
  local check3=true # check for valid month
  local check4=true # check for valid year

  # check for valid length of array (len(array) == 3)
  if [[ "${#keys_array[@]}" == 3 ]]; then
    local str1="${keys_array[0]}"
    local str2="${keys_array[1]}"
    local str3="${keys_array[2]}"
  else
    check1=false
  fi

  # check2: str1 is an integer between 1 and 12
  check2=$(check_day $str1)
  # check3: str2 is an integer between 1 and 31
  check3=$(check_month $str2)
  # check4: str3 is an integer between 2018 and 2999
  check4=$(check_year $str3)

  if [[ "$check1" == true ]] && [[ "$check2" == true ]] && [[ "$check3" == true ]] && [[ "$check4" == true ]]; then
    result="true"
  else
    result="false"
  fi

  echo "$result"
}
# [END check_archive_key_array]


# [START get_label_values]
function get_label_values () {
  local instance_name="$1" # instance_name="testing-vagrant"
  local instance_zone="$2" # instance_zone="us-central1-f"
	local instance_project="$3" # instance_project="scheduler-test-181019"
  local label="$4"
  local label_ifs="$5"

  local label_and_key_raw=$(gcloud compute instances describe "$instance_name" --zone "$instance_zone" --project "$instance_project" | grep "$label: ")
  # echo $label_and_key_raw

  if [[ -z $label_and_key_raw ]]; then
    local label_key="none"
  else
    # remove white spaces
    local label_and_key_wo_spaces=$(echo "${label_and_key_raw}" | tr -d "[:space:]")
    # remove label and column, e.g.: "label:"
    local label_key=$(echo "${label_and_key_wo_spaces}" | sed -e "s/${label}://")
    # echo "$label_key"
  fi

  # parse archive key into array with individual fields
  local label_key_array
  label_key_array=($(parse_string_into_array "$label_ifs" "$label_key"))
  # echo "${label_key_array[@]}"

  case "$label" in
      "$archive_label" )
      # Call check_archive_key_array function to confirm a valid keys
      local is_label_key_valid=$(check_archive_key_array label_key_array[@])
      # echo "$is_label_key_valid"
      ;;
      "$scheduler_label" )
      # Call check_scheduler_key_array function to confirm a valid keys
      local is_label_key_valid=$(check_scheduler_key_array label_key_array[@])
      # echo "$is_label_key_valid"
      ;;
      "$owner_label" )
      local is_label_key_valid="true"
      ;;
  esac

  if [[ $is_label_key_valid == true ]]; then
    echo "${label_key_array[@]}"
  else
    echo "none"
  fi
}
# [END get_label_values]


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

  if [[ $year =~ $reg_ex ]] && [[ $year -ge 2000 ]] && [[ $year -le 2999 ]]; then
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


# [START parse_string_into_array]
function parse_string_into_array () {
  local custom_ifs="$1"
  local string_to_parse="$2"

  local scheduler_key_array
  IFS="$custom_ifs" read -r -a parsed_array <<<"$string_to_parse"

  echo "${parsed_array[@]}"
}
# [END parse_string_into_array]


# [START get_instance_status]
function get_instance_status () {
  local instance_name="$1"
  local time_stamp="$2"
  local instance_status=$(awk -v pat="$instance_name " '$0 ~ pat {print $3}' "$tmp_dir/$envs_list-$time_stamp.$envs_list_format")
  echo "$instance_status"
}
# [END get_instance_status]


# [START get_instance_zone]
function get_instance_zone () {
  local instance_name="$1"
  local time_stamp="$2"
  local instance_zone=$(awk -v pat="$instance_name " '$0 ~ pat {print $2}' "$tmp_dir/$envs_list-$time_stamp.$envs_list_format")
  echo "$instance_zone"
}
# [END get_instance_zone]


# [START get_zone_time]
function get_zone_time () {
  local instance_zone="$1"
  local time_format="%H%M" # e.g. "1600"
  local TZ

  TZ=$(get_tz_identifier "$instance_zone")
  zone_time=($(TZ=$TZ date +"$time_format"))
  echo "${zone_time[@]}"
}
# [END get_zone_time]


# [START get_zone_weekday]
function get_zone_weekday () {
  local instance_zone="$1"
  local date_format="%a" # e.g. "Sat"
  local TZ

  TZ=$(get_tz_identifier "$instance_zone")
  zone_weekday=$(TZ=$TZ date +"$date_format")
  echo "$zone_weekday"
}
# [END zone_weekday]


# [START get_zone_date]
function get_zone_date () {
  local instance_zone="$1"
  local date_format="%m %d %Y" # e.g. "03 08 2018"
  local TZ

  TZ=$(get_tz_identifier "$instance_zone")
  zone_date=($(TZ=$TZ date +"$date_format"))
  echo "${zone_date[@]}"
}
# [END zone_date]


# [START get_tz_identifier]
function get_tz_identifier () {
  local tz_idenfitier   # https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
  local instance_zone=$1
  case "$instance_zone" in

    "aedt" )
      # AEDT - Australian Eastern Daylight Time, UTC/GMT +11 hours (between Oct 1 and Apr 2)
      tz_idenfitier="Etc/GMT-11"
    ;;
    "aest" )
      # AEST - Australian Eastern Standard Time, UTC/GMT +10 hours (between Apr 2 and Oct 1)
      tz_idenfitier="Etc/GMT-10"
    ;;
    "jst" )
      # JST - Japan Standard Time, UTC/GMT +9 hours
      tz_idenfitier="Etc/GMT-9"
    ;;
    "cst" | "sgt" )
      # CST - China Standard Time, UTC/GMT +8 hours
      # SGT - Singapore Time, UTC/GMT +8 hours
      tz_idenfitier="Etc/GMT-8"
    ;;
    "ist" )
      # IST - India Standard Time, UTC/GMT +5:30 hours
      tz_idenfitier="Asia/Kolkata"
    ;;
    "cest" )
      # CEST - Central European Summer Time, UTC/GMT +2 hours (between Mar 26 and Oct 29)
      tz_idenfitier="Etc/GMT-2"
    ;;
    "cet" | "bsm" )
      # CET - Central European Time, UTC/GMT +1 hour (between Oct 29 and Mar 26)
      # BSM - British Summer Time, UTC/GMT +1 hour (between Mar 26 and Oct 29)
      tz_idenfitier="Etc/GMT-1"
    ;;
    "gmt" )
      # GMT - Greenwich Mean Time, UTC/GMT no offset (between Oct 29 and Mar 26)
      tz_idenfitier="Etc/GMT"
    ;;
    "brst" )
      # BRST - Brasilia Summer Time, UTC/GMT -2 hours (Oct 14 to Feb 18)
      tz_idenfitier="Etc/GMT+2"
    ;;
    "brt" )
      # BRT- Brasilia Time, UTC/GMT -3 hours (from Feb 18 to Oct 14)
      tz_idenfitier="Etc/GMT+3"
    ;;
    "edt" )
      # EDT	- Eastern Daylight Time, UTC/GMT -4 hours (from Mar 12 to Nov 5)
      tz_idenfitier="Etc/GMT+4"
    ;;
    "cdt" | "est" )
      # CDT - Central Daylight Time, UTC/GMT -5 hours (from Mar 12 to Nov 5)
      # EST - Eastern Standard Time, UTC/GMT -5 hours (from Nov 5 to Mar 12)
      tz_idenfitier="Etc/GMT+5"
    ;;
    "ct" )
      # CT - Central Standard Time, UTC/GMT -6 hours (from Nov 5 to Mar 12)
      tz_idenfitier="Etc/GMT+6"
    ;;
    "pdt" )
      # PDT- Pacific Daylight Time, UTC/GMT -7 hours (from Mar 12 to Nov 5)
      tz_idenfitier="Etc/GMT+7"
    ;;
    "pst" )
      # PST - Pacific Standard Time, UTC/GMT -8 hours (from Nov 5 to Mar 12)
      tz_idenfitier="Etc/GMT+8"
    ;;
  esac

  echo "$tz_idenfitier"
}
# [END get_tz_identifier]


# [START stop_instance]
function stop_instance () {
  local instance_name="$1"
  local instance_zone="$2"
  local instance_project="$3"
  local time_stamp="$4"
  gcloud compute instances stop "$instance_name" --zone "$instance_zone" --project "$instance_project" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
}
# [END stop_instance]


# [START start_instance]
function start_instance () {
  local instance_name="$1"
  local instance_zone="$2"
  local instance_project="$3"
  local time_stamp="$4"
  gcloud compute instances start "$instance_name" --zone "$instance_zone" --project "$instance_project" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
}
# [END start_instance]


# [START delete_instance]
function delete_instance () {
  local instance_name="$1"
  local instance_zone="$2"
  local instance_project="$3"
  local time_stamp="$4"
  gcloud compute instances delete "$instance_name" --zone "$instance_zone" --project "$instance_project" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
}
# [END delete_instance]


# [START delete_instance]
function delete_instance () {
  local instance_name="$1"
  local instance_zone="$2"
  local instance_project="$3"
  local time_stamp="$4"
  local snapshot_name=$(echo "${instance_name}" | sed -e "s/vm-/ss-/") # snapshots share the instance name with a different prefix: "vm-instance" --> "ss-instance"
  gcloud compute disks snapshot "$instance_name" --zone "$instance_zone" --project "$instance_project" --snapshot-names="$snapshot_name" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
}
# [END delete_instance]


# [START instances_control]
function instances_control () {
	local project="$1"
  local instance_name
  local instance_owner
  local instance_status
  local instance_zone

  local scheduler_array
  local instance_scheduler_start_time
  local instance_scheduler_stop_time
  local instance_scheduler_time_zone
  local instance_scheduler_days

  local archive_date_array
  local instance_archive_date
  local instance_archive_day
  local instance_archive_month
  local instance_archive_year

  local instance_zone_date
  local instance_zone_weekday
  local instance_zone_time

  local time_stamp=`date -u +"%m.%d.%Y-%H%M%S"`
  local is_start_stop_today="false"
  local is_archive_today="false"

  local instances_array=($(get_current_instances "$project" "$time_stamp"))
  #echo "${instances_array[@]}"

  # loop through instances to start/stop or to archive
  for instance in "${instances_array[@]}"; do

    instance_name="$instance"
    instance_status=$(get_instance_status "$instance_name" "$time_stamp")
    instance_zone=$(get_instance_zone "$instance_name" "$time_stamp")
    instance_owner=$(get_label_values "$instance_name" "$instance_zone" "$project" "$owner_label" "$owner_label_ifs")
    scheduler_array=($(get_label_values "$instance_name" "$instance_zone" "$project" "$scheduler_label" "$scheduler_label_ifs"))

    if [[ "${#scheduler_array[@]}" -eq 4 ]]; then
      instance_scheduler_start_time="${scheduler_array[0]}"
      instance_scheduler_stop_time="${scheduler_array[1]}"
      instance_scheduler_time_zone="${scheduler_array[2]}"
      instance_scheduler_days=($(parse_string_into_array "$weekdays_ifs" "${scheduler_array[3]}"))
    else
      instance_scheduler_start_time="${scheduler_array[0]}"
      instance_scheduler_stop_time="${scheduler_array[0]}"
      instance_scheduler_time_zone="${scheduler_array[0]}"
      instance_scheduler_days="${scheduler_array[0]}"
    fi

    if [[ "$instance_scheduler_start_time" == "default" ]]; then
      instance_scheduler_start_time="$default_start_time"
    fi

    if [[ "$instance_scheduler_stop_time" == "default" ]]; then
      instance_scheduler_start_time="$default_stop_time"
    fi

    archive_date_array=($(get_label_values "$instance_name" "$instance_zone" "$project" "$archive_label" "$archive_label_ifs"))
    instance_archive_date=$(get_label_values "$instance_name" "$instance_zone" "$project" "$archive_label" "$archive_label_ifs")
    if [[ "${#archive_date_array[@]}" -eq 3 ]]; then
      instance_archive_month="${archive_date_array[0]}"
      instance_archive_day="${archive_date_array[1]}"
      instance_archive_year="${archive_date_array[2]}"
    else
      instance_archive_month="${archive_date_array[0]}"
      instance_archive_day="${archive_date_array[0]}"
      instance_archive_year="${archive_date_array[0]}"
    fi

    instance_zone_date=$(get_zone_date "$instance_scheduler_time_zone")
    instance_zone_weekday=$(get_zone_weekday "$instance_scheduler_time_zone")
    instance_zone_time=$(get_zone_time "$instance_scheduler_time_zone")

    is_start_stop_today=$(check_start_stop_today "$instance_zone_weekday" "${instance_scheduler_days[@]}")
    is_archive_today=$(check_archive_today "$instance_zone_date" "$instance_archive_date")


    function print_info () {
      echo ""
      echo "------------------------------------------------"
      echo "project: $project"
      echo "------------------------------------------------"
      echo "instance: $instance_name"
      echo "status: $instance_status"
      echo "owner: $instance_owner"
      echo "zone: $instance_zone"
      echo ""
      echo "scheduler values: ${scheduler_array[@]}"
      echo "start time: $instance_scheduler_start_time"
      echo "stop time: $instance_scheduler_stop_time"
      echo "time zone: $instance_scheduler_time_zone"
      echo "days: ${instance_scheduler_days[@]}"
      echo ""
      echo "archive-date values: $instance_archive_date"
      echo "archive month: $instance_archive_month"
      echo "archive day: $instance_archive_day"
      echo "archive year: $instance_archive_year"
      echo ""
      echo "zone date: $instance_zone_date"
      echo "zone day: $instance_zone_weekday"
      echo "zone time: $instance_zone_time"
      echo ""
      echo "start/stop today?: $is_start_stop_today"
      echo "archive today?: $is_archive_today"
    }
    print_info


    if [[ "$is_archive_today" == "true" ]]; then
        if [[ $((10#$instance_zone_time)) -le $((10#$email_time+3)) ]] && [[ $((10#$instance_zone_time)) -ge $((10#$email_time-3)) ]]; then
          # email user
          echo "Instance $instance will be archived today at 22:00"
        elif [[ $((10#$instance_zone_time)) -le $((10#$archive_time+3)) ]] && [[ $((10#$instance_zone_time)) -ge $((10#$archive_time-3)) ]]; then
          echo "==============================" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
          echo " Action: ARCHIVE instance" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
          echo " Project: $project" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
          echo " Instance: $instance" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
          echo " Zone: $instance_zone" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
          echo "" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
          if [[ "$instance_status" == "RUNNING" ]]; then
            stop_instance "$instance" "$instance_zone" "$project" "$time_stamp"
          else
            snapshot_instance "$instance" "$instance_zone" "$project" "$time_stamp"
            delete_instance "$instance" "$instance_zone" "$project" "$time_stamp"
          fi
        fi
    elif [[ "$is_start_stop_today" == "true" ]]; then

      if [[ "$instance_scheduler_start_time" != "none" ]] && [[ ( $((10#$instance_zone_time)) -le $((10#$instance_scheduler_start_time+3)) ) && ( $((10#$instance_zone_time)) -ge $((10#$instance_scheduler_start_time-3)) ) ]] && [[ "$instance_status" == "TERMINATED" ]]; then
        echo "==============================" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        echo " Action: START instance" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        start_instance "$instance" "$instance_zone" "$project" "$time_stamp"
        echo " Project: $project" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        echo " Instance: $instance" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        echo " Zone: $instance_zone" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        echo "" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        echo " Instance $instance is starting"
      elif [[ "$instance_scheduler_stop_time" != "none"  ]] && [[ ( $((10#$instance_zone_time)) -le $((10#$instance_scheduler_stop_time+3)) ) && ( $((10#$instance_zone_time)) -ge $((10#$instance_scheduler_stop_time-3)) ) ]] && [[ "$instance_status" == "RUNNING" ]]; then
        echo "==============================" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        echo " Action: STOP instance" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        stop_instance "$instance" "$instance_zone" "$project" "$time_stamp"
        echo " Project: $project" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        echo " Instance: $instance" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        echo " Zone: $instance_zone" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        echo "" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        echo " Instance $instance is stopping."
      else
        echo "==============================" >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        echo " Nothing to do at $time_stamp " >> "$logs_dir/$logs_file-$time_stamp.$logs_file_format"
        echo ""
      fi
    fi

  done

  rm -rf "$tmp_dir/$envs_list-$time_stamp.$envs_list_format"
}
# [END instances_control]


main "$@"
