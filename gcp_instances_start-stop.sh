#!/bin/sh

# script that starts stops machines depending on their schedule
# Input: list of active environment names with their respective UTC schedule, e.g.:
# vm-fgalindo-windowsserver-datafabric-631-00055555,start;stop;<active_days>

# by default, the script pulls the current names of environments from GCP, depending on the time zone, it generates the start and the stop times (the active days are by default Monday through Friday)

# date +"[option]"

# [option]	result
# %T     	time; same as %H:%M:%S
# %u     	day of week (1..7); 1 is Monday
# %H     	hour (00..23)
# %I     	hour (01..12)

# GCP Zones, Cities and UTC time zones
#
# Zones												GCP City				Talend City			Operating Hours (UTC)
# asia-east1-a								Taiwan					Beijing					2200-1000 UTC
# asia-east1-c								Taiwan					Beijing					2200-1000 UTC
# asia-east1-b								Taiwan					Beijing					2200-1000 UTC
# asia-northeast1-c						Tokyo														2100-0900 UTC
# asia-northeast1-a						Tokyo														2100-0900 UTC
# asia-northeast1-b						Tokyo														2100-0900 UTC
# asia-southeast1-b						Singapore				Bangalore				0030-1230 UTC
# asia-southeast1-a						Singapore				Bangalore				0030-1230 UTC
# australia-southeast1-a			Sydney													2000-0800 UTC
# australia-southeast1-c			Sydney													2000-0800 UTC
# australia-southeast1-b			Sydney													2000-0800 UTC
# europe-west1-d							Belgium			 		Suresnes				0400-1600 UTC
# europe-west1-c							Belgium				 	Suresnes				0400-1600 UTC
# europe-west1-b							Belgium			 		Suresnes				0400-1600 UTC
# europe-west2-c							London					London					0500-1700 UTC
# europe-west2-a							London					London					0500-1700 UTC
# europe-west2-b							London					London					0500-1700 UTC
# europe-west3-b							Frankfurt				Bonn						0400-1600 UTC
# europe-west3-c							Frankfurt				Bonn						0400-1600 UTC
# europe-west3-a							Frankfurt				Bonn						0400-1600 UTC
# us-central1-c								Iowa														1100-2300 UTC
# us-central1-a								Iowa														1100-2300 UTC
# us-central1-f								Iowa														1100-2300 UTC
# us-central1-b								Iowa														1100-2300 UTC
# us-east1-d									S.Carolina			Atlanta					1000-2200 UTC
# us-east1-c									S.Carolina			Atlanta					1000-2200 UTC
# us-east1-b									S.Carolina			Atlanta					1000-2200 UTC
# us-east4-b									N.Virginia	 										1100-2300 UTC
# us-east4-a									N.Virginia	 										1100-2300 UTC
# us-east4-c									N.Virginia	 										1100-2300 UTC
# us-west1-b									Oregon					Irvine					1300-0100 UTC
# us-west1-a									Oregon					Irvine					1300-0100 UTC
# us-west1-c									Oregon					Irvine					1300-0100 UTC


# function to find current time and day of the week

function currentTime () {
  day_of_week = date -u +"%u" # get the day of the week (in UTC)
  day_hour = date -u +"H" # get the current hour (in UTC)

}


# function to retrieve current instances and its state (started or stopped)
function currentInstances() {
  gcloud compute instances list | awk '{print $1, $2, $NF}' > gp_instances_list.txt

  ## TODO
  ## create list of instances that need to be started
  ## creaate list of instances that need to be stopped


}

# function to stop instances that need to be stopped
function stopInstances() {
  gcloud compute isntances start $stoppedInstances
  gcloud compute instances stop $startedIsntances
}

# function to start instances that need to be started
function startInstances() {
  gcloud compute isntances start $stoppedInstances
  gcloud compute instances stop $startedIsntances
}
