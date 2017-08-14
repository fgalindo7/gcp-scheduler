#!/bin/sh

# script that starts stops machines depending on their schedule
# Input: list of active environment names with their respective UTC schedule, e.g.:
# vm-fgalindo-windowsserver-datafabric-631-00055555,start;stop;<active_days>

# by default, the script pulls the current names of environments from GCP, depending on the time zone, it generates the start and the stop times (the active days are by default Monday through Friday)

# date +"[option]"
#
# [option]	result
# %T     	time; same as %H:%M:%S
# %u     	day of week (1..7); 1 is Monday
# %H     	hour (00..23)
# %I     	hour (01..12)

day_of_week = date -u +"%u" # get the day of the week (in UTC)
day_hour = date -u +"H" # get the current hour (in UTC) 

GCP_env_list = /home/fgalindo/GCP_envs.txt 

for i in $GCP_env_list ; 
	do 
		
			
