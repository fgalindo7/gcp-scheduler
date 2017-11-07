#!/bin/bash
export project='scheduler-test-181019'
export scheduler_label='scheduler'
export archive_label='archive-date'
export exceptions=('devops' 'support-docker-registry')

export instance_name="vm-fgalindo-debian9-test-3"


# [START remove_exceptions]
function remove_exceptions() {
  # delete exceptions using sed
  # for exception in ${exceptions[@]}; do echo ${exception}; sed -i -e "/${exception}/d" environments/gcp_instances_list.txt; done
  for exception in "${exceptions[@]}"; do
    sed -i -e "/${exception}/d" environments/gcp_instances_list.txt
  done
}
# [STOP remove_exceptions]



# [START create_instances_array]
function create_instances_array() {
  while IFS=' ' read -r line || [[ -n ${line} ]] ; do
    instances_arr+=($(echo ${line} | awk '{print $1;}'))
  done < "environments/gcp_instances_list.txt"
}
# [STOP create_instances_array]



# [START get_current_instances]
function get_current_instances() {
	local project=$1
  # list of NAME ZONE STATUS without header sorted by zone
  gcloud compute instances list --project $project | awk 'NR>1{print $1, $2, $NF}' > environments/gcp_instances_list.txt
  # call function to remove all instances that are exceptions to the scheduler
  remove_exceptions
	create_instances_array
}

get_current_instances $project
# [STOP get_current_instances]



# [START get_instance_zone]
function get_instance_zone() {
  local instance_name=$1
  local instance_zone=$(awk -v pat="$instance_name " '$0 ~ pat {print $2}' environments/gcp_instances_list.txt)
  echo "$instance_zone"
}
export zone=$(get_instance_zone "$instance_name")
# [END get_instance_zone]



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
  echo "${scheduler_key_array[*]}"
}

scheduler_array=($(get_scheduler_label "$instance_name" "$zone" "$project"))

echo "Scheduler: ${scheduler_array[@]}"
start_time="${scheduler_array[0]}"
echo "start time: $start_time"
stop_time="${scheduler_array[1]}"
echo "stop time: $stop_time"
time_zone="${scheduler_array[2]}"
echo "time zone: $time_zone"
days="${scheduler_array[3]}"
echo "days: $days"

# [END get_scheduler_label]




# [START get_archive_label]
function get_archive_label() {
  local instance_name=$1
  local instance_zone=$2
	local instance_project=$3

  local archive_label_key_raw=$(gcloud compute instances describe "$instance_name" --zone "$instance_zone" --project "$instance_project" | grep "$archive_label: ")
  # export archive_label_key_raw=$(gcloud compute instances describe "$instance_name" --zone "$instance_zone" --project "$instance_project" | grep "$archive_label: "); echo $archive_label_key_raw
  if [[ -z $archive_label_key_raw ]]; then
    local archive_key='none'
  else
    local archive_label_key=$(echo "${archive_label_key_raw}" | tr -d '[:space:]') # remove white spaces
    # export archive_label_key=$(echo "${archive_label_key_raw}" | tr -d '[:space:]'); echo $archive_label_key
    local archive_key=$(echo "${archive_label_key}" | sed -e "s/${archive_label}://") # remove archive label and column, "archive:"
    # export archive_key=$(echo "${archive_label_key}" | sed -e "s/${archive_label}://"); echo $archive_key
  fi
  # parse archive key
  local archive_key_array
  IFS='-' read -r -a archive_key_array <<< "$archive_key"
  echo "${archive_key_array[*]}"
}

# get archive-date of instance
archive_array=($(get_archive_label "$instance_name" "$zone" "$project"))
echo "Archive-date: ${archive_array[@]}"

# [END get_archive_label]
