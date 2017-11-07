#!/bin/bash
export project='scheduler-test-181019'
export scheduler_label='scheduler'
export archive_label='archive-date'
export exceptions=('devops' 'support-docker-registry')

export instance_name="vm-devops-centos74-gui-jdk8u151-template"



# [START get_instance_zone]
function get_instance_zone() {
  local instance_name=$1
  local instance_zone=$(awk -v pat="$instance_name " '$0 ~ pat {print $2}' environments/gcp_instances_list.txt)
  echo "$instance_zone"
}
# [END get_instance_zone]
export zone=$(get_instance_zone "$instance_name")

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
  echo "${scheduler_key_array[*]}"
}


scheduler_array=$(get_scheduler_label "$instance_name" "$zone" "$project")
echo $scheduler_array

# echo "Scheduler: ${scheduler_array[@]}"
start_time="${scheduler_array[0]}"
echo $start_time
stop_time="${scheduler_array[1]}"
echo $stop_time
time_zone="${scheduler_array[2]}"
echo $time_zone
days="${scheduler_array[3]}"
echo $days
