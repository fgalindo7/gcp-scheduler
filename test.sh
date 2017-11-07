#!/bin/bash
export projects=('css-us' 'css-apac' 'css-emea' 'probable-sector-147517')
export scheduler_label='scheduler'
export archive_label='archive-date'
export exceptions=('devops' 'fgalindo' 'support-docker-registry')
export instance_name="vm-devops-centos74-gui-jdk8u151-template"

export zone=$(get_instance_zone "$instance_name")



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



# [START get_instance_city]
function get_instance_city() {
  local instance_name=$1
  local zone=$(get_instance_zone "$instance_name")

  case $zone in
    "asia-east1"* )
    local instance_city="taiwan"
    echo "$instance_city"
      ;;
    "asia-northeast1"* )
    local instance_city="tokyo"
    echo "$instance_city"
      ;;
    "asia-southeast1"* )
    local instance_city="singapore"
    echo "$instance_city"
      ;;
    "australia-southeast1"* )
    local instance_city="sydney"
    echo "$instance_city"
      ;;
    "europe-west1"* )
    local instance_city="belgium"
    echo "$instance_city"
      ;;
    "europe-west2"* )
    local instance_city="london"
    echo "$instance_city"
      ;;
    "europe-west3"* )
    local instance_city="frankfurt"
    echo "$instance_city"
      ;;
    "us-central1"* )
    local instance_city="iowa"
    echo "$instance_city"
      ;;
    "us-east1"* )
    local instance_city="s_carolina"
    echo "$instance_city"
      ;;
    "us-east4"* )
    local instance_city="n_virginia"
    echo "$instance_city"
      ;;
    "us-west1"* )
    local instance_city="oregon"
    echo "$instance_city"
      ;;
  esac
}
# [END get_instance_city]
