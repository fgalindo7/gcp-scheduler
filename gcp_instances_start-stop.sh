#!/bin/sh

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
#----------------------------------------------------------------------------
#GCP zones, cities, and UTC start and stop times
#----------------------------------------------------------------------------
#zones	                    GCP city		Talend city   on (UTC)  off (UTC)
#----------------------------------------------------------------------------
#asia-southeast1-b		    singapore	    bangalore		0030      1230
#asia-southeast1-a			singapore		bangalore		0030      1230
#europe-west1-d				belgium		 	suresnes		0400      1600
#europe-west1-c				belgium			suresnes		0400      1600
#europe-west1-b				belgium			suresnes		0400      1600
#europe-west3-b				frankfurt		bonn			0400      1600
#europe-west3-c				frankfurt	    bonn			0400      1600
#europe-west3-a				frankfurt		bonn			0400      1600
#europe-west2-c				london			london			0500      1700
#europe-west2-a				london			london			0500      1700
#europe-west2-b				london		    london			0500      1700
#us-east1-d					s_carolina	    atlanta			1000      2200
#us-east1-c					s_carolina	    atlanta			1000      2200
#us-east1-b		      		s_carolina	    atlanta			1000      2200
#us-central1-c				iowa							             1100      2300
#us-central1-a				iowa							             1100      2300
#us-central1-f				iowa							             1100      2300
#us-central1-b				iowa							             1100      2300
#us-east4-b				    n_virginia	 					          1100      2300
#us-east4-a				    n_virginia	 					          1100      2300
#us-east4-c					n_virginia	 					           1100      2300
#us-west1-b		            oregon			irvine			1300      0100
#us-west1-a                 oregon			irvine  		1300      0100
#us-west1-c                 oregon			irvine	    	1300      0100
#australia-southeast1-a		sydney							2000      0800
#australia-southeast1-c		sydney			   		        2000      0800
#australia-southeast1-b		sydney	   						2000      0800
#asia-northeast1-c			tokyo				            2100      0900
#asia-northeast1-a			tokyo					        2100      0900
#asia-northeast1-b			tokyo							2100      0900
#asia-east1-a               taiwan			beijing         2200      1000
#asia-east1-c               taiwan			beijing         2200      1000
#asia-east1-b               taiwan			beijing         2200      1000
#----------------------------------------------------------------------------


## Global variables
#
# start_time=06
# stop_time=20
#
# weekends='off'
# weekdays='on'
# mon='on'
# tue='on'
# wed='on'
# thu='on'
# fri='on'


# [START get_current_time]
function get_current_time() {
    # date +"[option]"

    # [option]	result
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
    gcloud compute instances list | awk 'NR>1{print $1, $2, $NF}' > gcp_instances_list.txt
}
# [END get_current_instances]


# [START replace_zone_with_city]
function replace_zone_with_city() {
    if [[ -f gcp_instances_list.txt ]] ; then
        # make copy to keep zones
        cp gcp_instances_list.txt gcp_instances_list_raw.txt

        # replace zones with cities
        sed -i -e 's/asia-east1-a/taiwan/g' gcp_instances_list.txt
        sed -i -e 's/asia-east1-c/taiwan/g' gcp_instances_list.txt
        sed -i -e 's/asia-east1-b/taiwan/g' gcp_instances_list.txt
        sed -i -e 's/asia-northeast1-c/tokyo/g' gcp_instances_list.txt
        sed -i -e 's/asia-northeast1-a/tokyo/g' gcp_instances_list.txt
        sed -i -e 's/asia-northeast1-b/tokyo/g' gcp_instances_list.txt
        sed -i -e 's/asia-southeast1-b/singapore/g' gcp_instances_list.txt
        sed -i -e 's/asia-southeast1-a/singapore/g' gcp_instances_list.txt
        sed -i -e 's/australia-southeast1-a/sydney/g' gcp_instances_list.txt
        sed -i -e 's/australia-southeast1-c/sydney/g' gcp_instances_list.txt
        sed -i -e 's/australia-southeast1-b/sydney/g' gcp_instances_list.txt
        sed -i -e 's/europe-west1-d/belgium/g' gcp_instances_list.txt
        sed -i -e 's/europe-west1-c/belgium/g' gcp_instances_list.txt
        sed -i -e 's/europe-west1-b/belgium/g' gcp_instances_list.txt
        sed -i -e 's/europe-west2-c/london/g' gcp_instances_list.txt
        sed -i -e 's/europe-west2-a/london/g' gcp_instances_list.txt
        sed -i -e 's/europe-west2-b/london/g' gcp_instances_list.txt
        sed -i -e 's/europe-west3-b/frankfurt/g' gcp_instances_list.txt
        sed -i -e 's/europe-west3-c/frankfurt/g' gcp_instances_list.txt
        sed -i -e 's/europe-west3-a/frankfurt/g' gcp_instances_list.txt
        sed -i -e 's/us-central1-c/iowa/g' gcp_instances_list.txt
        sed -i -e 's/us-central1-a/iowa/g' gcp_instances_list.txt
        sed -i -e 's/us-central1-f/iowa/g' gcp_instances_list.txt
        sed -i -e 's/us-central1-b/iowa/g' gcp_instances_list.txt
        sed -i -e 's/us-east1-d/s_carolina/g' gcp_instances_list.txt
        sed -i -e 's/us-east1-c/s_carolina/g' gcp_instances_list.txt
        sed -i -e 's/us-east1-b/s_carolina/g' gcp_instances_list.txt
        sed -i -e 's/us-east4-b/n_virginia/g' gcp_instances_list.txt
        sed -i -e 's/us-east4-a/n_virginia/g' gcp_instances_list.txt
        sed -i -e 's/us-east4-c/n_virginia/g' gcp_instances_list.txt
        sed -i -e 's/us-west1-b/oregon/g' gcp_instances_list.txt
        sed -i -e 's/us-west1-a/oregon/g' gcp_instances_list.txt
        sed -i -e 's/us-west1-c/oregon/g' gcp_instances_list.txt
      else
        echo "gcp_instances_list.txt not found"
        exit 0
    fi
}
# [END replace_zone_with_city]



# [START create_instances_array]
function create_instances_array() {
  while IFS=' ' read -r line || [[ -n ${line} ]] ; do
    instances_arr+=(`echo ${line} | awk '{print $1;}'`)
  done < "gcp_instances_list.txt"
}
# [END create_instances_array]



# [START stop_instances]
function stop_instances() {
  gcloud compute instances stop "$1" --zone "$2" >> logs/gpc_instances_start-stop_$time_stamp.log
}
# [END stop_instances]



# [START start_instances]
function start_instances() {
  gcloud compute instances start "$1" --zone "$2" >> logs/gpc_instances_start-stop_$time_stamp.log
}
# [END start_instances]


# [START action_on_instance]
function action_on_instance() {
  local gcp_city=$1
  case $gcp_city in
    'singapore' )
            if [[ ${utc_hour} -eq 00 ]]; then
              action='start'
            elif [[ ${utc_hour} -eq 13 ]]; then
              action='stop'
            else
              action='none'
            fi
    ;;

    'belgium'|'frankfurt')
              if [[ ${utc_hour} -eq 04 ]]; then
                action='start'
              elif [[ ${utc_hour} -eq 16 ]]; then
                action='stop'
              else
                action='none'
              fi
    ;;

    'london' )
            if [[ $utc_hour -eq 05 ]]; then
              action='start';
            elif [[ $utc_hour -eq 17 ]]; then
              action='stop' ;
            else action='none' ; fi
    ;;

    's_carolina' )
            if [[ ${utc_hour} -eq 01 ]]; then
              action='start'
            elif [[ ${utc_hour} -eq 13 ]]; then
              action='stop'
            else
              action='none'
            fi
    ;;

    'iowa' )
              if [[ ${utc_hour} -eq 10 ]]; then
                # action='start'
                action='none'
              elif [[ u${utc_hour} -eq 22 ]]; then
                # action='stop'
                action='none'
              else
                action='none'
              fi
    ;;

    'n_virginia' )
              if [[ ${utc_hour} -eq 11 ]]; then
                action='start'
              elif [[ ${utc_hour} -eq 23 ]]; then
                action='stop'
              else
                action='none'
              fi
    ;;

    'oregon' )
              if [[ ${utc_hour} -eq 13 ]]; then
                action='start'
              elif [[ ${utc_hour} -eq 01 ]]; then
                action='stop'
              else
                action='none'
              fi
    ;;

    'sydney' )
              if [[ ${utc_hour} -eq 20 ]]; then
                action='start'
              elif [[ ${utc_hour} -eq 08 ]]; then
                action='stop'
              else
                action='none'
              fi
    ;;

    'tokyo' )
              if [[ ${utc_hour} -eq 21 ]]; then
                action='start'
              elif [[ ${utc_hour} -eq 09 ]]; then
                action='stop'
              else
                action='none'
              fi
    ;;

    'taiwan' )
              if [[ ${utc_hour} -eq 22 ]]; then
                action='start'
              elif [[ ${utc_hour} -eq 10 ]]; then
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
        status=`awk -v pat="$instance_name " '$0 ~ pat {print $3}' gcp_instances_list_raw.txt`;
        # echo "Status: $status"

        # get city of instance i
        city=`awk -v pat="$instance_name " '$0 ~ pat {print $2}' gcp_instances_list.txt`;
        # echo "City: $city"

        # get zone of instance i
        zone=`awk -v pat="$instance_name " '$0 ~ pat {print $2}' gcp_instances_list_raw.txt`

        # action_on_instance function to see if instance should be started or stoppped
        action_on_instance $city
        # echo "Action: $action"
        # echo ""



        # make sure it's not a weekend before starting or stopping
        if [ $instance_name != 'vm-aarnoult-wserver2016-tac-studio-611-mysql5719-00074686' ] && [ $instance_name != 'vm-wserver2016-jobserver611-svn517-mysql5719' ] ; then
		echo "$instance_name"
	if [ $utc_week_day != 'sat' ] && [ $utc_week_day != 'sun' ] ; then
          if [[ ${status} == 'TERMINATED' && ${action} == 'start' ]] ; then
              echo "INSTANCE $instance_name with STATUS ${status} in ZONE ${zone} will start" >> logs/gpc_instances_start-stop_$time_stamp.log
              start_instances "$instance_name" "${zone}"
            elif [[ ${status} == 'RUNNING' && ${action} == 'stop' ]]; then
              echo "INSTANCE $instance_name with STATUS ${status} in ZONE ${zone} will stop" >> logs/gpc_instances_start-stop_$time_stamp.log
              stop_instances "$instance_name" "${zone}"
            else
              echo "INSTANCE $instance_name with STATUS ${status} in ZONE ${zone} will stay ${status}" >> logs/gpc_instances_start-stop_$time_stamp.log
          fi
        else
          echo "$utc_week_day crontab takes weekdays off."
          echo "Instances will stay as their current state"
        fi
	fi 
      } done
}
# [START instances_start_stop]



# [MAIN start]
get_current_time
get_current_instances
create_instances_array
replace_zone_with_city
instances_start_stop
# [END]
