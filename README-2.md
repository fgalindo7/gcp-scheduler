# talend-gpc-scheduler

## Summary
Starts and stops machines depending on their schedule and city.
Based on tag and status that are pulled from GCP: <br />
**UTC-start-time;UTC-stop-time;active-days** <br />
<br />
The script pulls the current names of environments from GCP under the CSS project. Depending on the time zone, it generates the start and stop **gcloud compute** commands (Monday through Friday).

## Setup
This script is setup as a cronjob to be run every hour. <br />
**10 0-23 * * 1-5 ec2-user /home/ec2-user/talend-gpc-scheduler/gcp_instances_start-stop.sh** <br />
<br />
The environment that we are currently using is an AWS t2.micro (free tier).

## Zones
**GCP Zones, Cities, UTC start & stop times**

In accordance with the IANA, we will use the following TZ to
start, stop and remove instances:
https://www.iana.org/time-zones
https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

All of the the following time zones can be used in the scheduler:

 **Talend Code** | **Meaning** | **Time Zone**  
-----------------|-----------------
CST | China Standard Time | UTC/GMT +8 hours
JST | Japan Standard Time | UTC/GMT +9 hours
IST | India Standard Time | UTC/GMT +5:30 hours
SGT | Singapore Time | UTC/GMT +8 hours
AEDT | Australian Eastern Daylight Time | UTC/GMT +11 hours (between Oct 1 and Apr 2)
AEST | Australian Eastern Standard Time | UTC/GMT +10 hours (between Apr 2 and Oct 1)
CET | Central European Time | UTC/GMT +1 hour (between Oct 29 and Mar 26)
CEST | Central European Summer Time | UTC/GMT +2 hours (between Mar 26 and Oct 29)
GMT | Greenwich Mean Time | UTC/GMT no offset (between Oct 29 and Mar 26)
BSM | British Summer Time | UTC/GMT +1 hour (between Mar 26 and Oct 29)
CET | Central European Time | UTC/GMT +1 hour (between Oct 29 and Mar 26)
CEST | Central European Summer Time | UTC/GMT +2 hours (between Mar 26 and Oct 29)
BRT | Brasilia Time | UTC/GMT -3 hours (from Feb 18 to Oct 14)
BRST | Brasilia Summer Time | UTC/GMT -2 hours (Oct 14 to Feb 18)
CT | Central Standard Time | UTC/GMT -6 hours (from Nov 5 to Mar 12)
CDT | Central Daylight Time | UTC/GMT -5 hours (from Mar 12 to Nov 5)
EST | Eastern Standard Time | UTC/GMT -5 hours (from Nov 5 to Mar 12)
EDT | Eastern Daylight Time | UTC/GMT -4 hours (from Mar 12 to Nov 5)
PST | Pacific Standard Time | UTC/GMT -8 hours (from Nov 5 to Mar 12)
PDT | Pacific Daylight Time | UTC/GMT -7 hours (from Mar 12 to Nov 5)
-----------------|-----------------

## Contributors

@fgalindo7 <br />
