#!/usr/bin/env python


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


"""
Scheduler to be run hourly as a cronjob under /etc/crontab
For more information, see the README.md under /compute.
"""


import os
from datetime import datetime
import googleapiclient.discovery

# import subprocess

# script that starts stops machines depending on their schedule
# Input: list of active environment names with their respective UTC schedule, e.g.:
# vm-fgalindo-windowsserver-datafabric-631-00055555,start;stop;<active_days>

# by default, the script pulls the current names of environments from GCP, depending on the time zone, it generates the start and the stop times (the active days are by default Monday through Friday)


# Bash equivalent
# date +"[option]"

# [option]	result
# %T     	time; same as %H:%M:%S
# %u     	day of week (1..7); 1 is Monday
# %H     	hour (00..23)
# %I     	hour (01..12)

'''
----------------------------------------------------------------------------------------
# GCP Zones Cities and UTC time zones
----------------------------------------------------------------------------------------
#
# Zones	                        GCP City		Talend City         on (UTC)  off (UTC)
----------------------------------------------------------------------------------------
# asia-east1-a                  Taiwan			Beijing             2200      1000
# asia-east1-c                  Taiwan			Beijing             2200      1000
# asia-east1-b                  Taiwan			Beijing             2200      1000
# asia-northeast1-c				Tokyo				                2100      0900
# asia-northeast1-a				Tokyo								2100      0900
# asia-northeast1-b				Tokyo								2100      0900
# asia-southeast1-b				Singapore		Bangalore			0030      1230
# asia-southeast1-a				Singapore		Bangalore			0030      1230
# australia-southeast1-a		Sydney								2000      0800
# australia-southeast1-c		Sydney			   					2000      0800
# australia-southeast1-b		Sydney	   							2000      0800
# europe-west1-d				Belgium		 	Suresnes			0400      1600
# europe-west1-c				Belgium			Suresnes			0400      1600
# europe-west1-b				Belgium			Suresnes			0400      1600
# europe-west2-c				London			London				0500      1700
# europe-west2-a				London			London				0500      1700
# europe-west2-b				London			London				0500      1700
# europe-west3-b				Frankfurt		Bonn				0400      1600
# europe-west3-c				Frankfurt		Bonn				0400      1600
# europe-west3-a				Frankfurt		Bonn				0400      1600
# us-central1-c					Iowa								1100      2300
# us-central1-a					Iowa								1100      2300
# us-central1-f					Iowa								1100      2300
# us-central1-b					Iowa								1100      2300
# us-east1-d					S.Carolina		Atlanta				1000      2200
# us-east1-c					S.Carolina		Atlanta				1000      2200
# us-east1-b		      		S.Carolina		Atlanta				1000      2200
# us-east4-b				    N.Virginia	 						1100      2300
# us-east4-a				    N.Virginia	 						1100      2300
# us-east4-c					N.Virginia	 						1100      2300
# us-west1-b					Oregon			Irvine				1300      0100
# us-west1-a                    Oregon			Irvine				1300      0100
# us-west1-c                    Oregon			Irvine				1300      0100
----------------------------------------------------------------------------------------
'''


# Find current time and day of the week in UTC
# [START current_time]
def current_time():
    current_utc_hour = datetime.utcnow().hour
    current_utc_week_day = datetime.utcnow().weekday() # Monday is 0, Sunday is 6

    ### Bash ################################################################
    ### current_utc_week_day = date +"%u"  # get the day of the week (in UTC)
    ### current_utc_hour = date +"H"  # get the current hour (in UTC)
    #########################################################################
    return current_utc_hour, current_utc_week_day
# [END current_time]


# function to retrieve current instances and its state (started or stopped)
# [START current_time]
def list_instances(compute, project):
    result = compute.instances().list(project=project).execute()
    return result['items']
# [START current_time]


def get_current_instances():
    # gcloud compute instances list | awk '{print $1, $2, $NF}' > gcp_instances_list.txt

    return

    ## TODO

    ## Separate instances by status


def is_instance_on():
    return
    ## create list of instances that need to be started

    ## create list of instances that need to be stopped


# function to stop instances that need to be stopped
def stop_instances():
    # gcloud compute instances stop $instancesThatAreUp
    return


# function to start instances that need to be started
def start_instances():
    # gcloud compute instances start $stoppedInstances


## Helper functions

def is_instance_on():
    return


def is_friday():
    return


# [START run]
def main():
    compute = googleapiclient.discovery.build('compute', 'v1')

    print('Creating instance.')

    operation = create_instance(compute, project, zone, instance_name, bucket)
    wait_for_operation(compute, project, zone, operation['name'])

    instances = list_instances(compute, project, zone)

    print('Instances in project %s and zone %s:' % (project, zone))
    for instance in instances:
        print(' - ' + instance['name'])

    print("""
Instance created.
It will take a minute or two for the instance to complete work.
Check this URL: http://storage.googleapis.com/{}/output.png
Once the image is uploaded press enter to delete the instance.
""".format(bucket))

    if wait:
        input()

    print('Deleting instance.')

    operation = delete_instance(compute, project, zone, instance_name)
    wait_for_operation(compute, project, zone, operation['name'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('project_id', help='Your Google Cloud project ID.')
    parser.add_argument(
        'bucket_name', help='Your Google Cloud Storage bucket name.')
    parser.add_argument(
        '--zone',
        default='us-central1-f',
        help='Compute Engine zone to deploy to.')
    parser.add_argument(
        '--name', default='demo-instance', help='New instance name.')

    args = parser.parse_args()

    main(args.project_id, args.bucket_name, args.zone, args.name)
# [END run]