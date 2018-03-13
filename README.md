# GCP-Scheduler

## Summary
Starts, stops, and deletes GCP instances based on their scheduler and archive-date labels: <br />

Label        | Key
------------ | -------------
scheduler    | start_time-stop_time-tz_identifier-days_of_the_week
archive-date | mm-dd-yyyy

The following values are acceptable for the scheduler key sections: <br />

Key sections | Values   
------------ | -------------
start_time       | 0000 to 2359
stop_time        | 0000 to 2359
tz_identifier    | *see table below*
days_of_the_week | mon, tue, wed, thu, fri, sat, sun, all, weekdays, weekends

**Note**: days of the week combinations can be made if separated by underscores.
<br />
The script pulls the current instances from GCP under the desired projects. Depending on their labels, it generates the start, stop, or snapshot and delete **gcloud compute** commands.

## Setup
This script is setup as a cronjob to be run every 3 minutes on an AWS t2.micro (free tier). <br />
<br />
\# Example of job definition: <br />
\# .---------------- minute (0 - 59) <br />
\# |  .------------- hour (0 - 23) <br />
\# |  |  .---------- day of month (1 - 31) <br />
\# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ... <br />
\# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat <br />
\# |  |  |  |  | <br />
\# *  *  *  *  * user-name  command to be executed <br />
\*/3  *  *  *  * ec2-user /home/ec2-user/gcp-scheduler/gcp_instances_start-stop-v2.sh css-apac <br />
\*/3  *  *  *  * ec2-user /home/ec2-user/gcp-scheduler/gcp_instances_start-stop-v2.sh css-emea <br />
\*/3  *  *  *  * ec2-user /home/ec2-user/gcp-scheduler/gcp_instances_start-stop-v2.sh css-us <br />
\*/3  *  *  *  * ec2-user /home/ec2-user/gcp-scheduler/gcp_instances_start-stop-v2.sh enablement-183818 <br />
<br />

## Zones
In accordance with the IANA, the scheduler uses the following TZ identifiers to
start, stop and remove instances: <br />

<br />
https://www.iana.org/time-zones  <br />
https://en.wikipedia.org/wiki/List_of_tz_database_time_zones  <br />
<br />
Only the following TZ identifiers can be used in the scheduler:

TZ Identifier | Meaning | Time offset from UTC  
--------------| ------- | ---------------
AEDT | Australian Eastern Daylight Time | UTC/GMT +11 hours (between Oct 1 and Apr 2)
AEST | Australian Eastern Standard Time | UTC/GMT +10 hours (between Apr 2 and Oct 1)
JST | Japan Standard Time | UTC/GMT +9 hours
CST | China Standard Time | UTC/GMT +8 hours
SGT | Singapore Time | UTC/GMT +8 hours
IST | India Standard Time | UTC/GMT +5:30 hours
CEST | Central European Summer Time | UTC/GMT +2 hours (between Mar 26 and Oct 29)
CET | Central European Time | UTC/GMT +1 hour (between Oct 29 and Mar 26)
BSM | British Summer Time | UTC/GMT +1 hour (between Mar 26 and Oct 29)
GMT | Greenwich Mean Time | UTC/GMT no offset (between Oct 29 and Mar 26)
BRST | Brasilia Summer Time | UTC/GMT -2 hours (Oct 14 to Feb 18)
BRT | Brasilia Time | UTC/GMT -3 hours (from Feb 18 to Oct 14)
EDT | Eastern Daylight Time | UTC/GMT -4 hours (from Mar 12 to Nov 5)
CDT | Central Daylight Time | UTC/GMT -5 hours (from Mar 12 to Nov 5)
EST | Eastern Standard Time | UTC/GMT -5 hours (from Nov 5 to Mar 12)
CT | Central Standard Time | UTC/GMT -6 hours (from Nov 5 to Mar 12)
PDT | Pacific Daylight Time | UTC/GMT -7 hours (from Mar 12 to Nov 5)
PST | Pacific Standard Time | UTC/GMT -8 hours (from Nov 5 to Mar 12)

**Note**: daylight saving times have their own TZ identifiers.

## Contributors
@franciscogd <br />
@fgalindo7
