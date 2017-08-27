# talend-gpc-scheduler

## Summary
Starts and stops machines depending on their schedule and city.
Based on tags that are pulled from GCP: <br />

**<UTC-start-time>;<UTC-stop-time>;<active_days>** <br />
<br />
The script pulls the current names of environments from GCP under the CSS project. Depending on the time zone, it generates the start and stop **gcloud compute** commands (Monday through Friday).


## Setup
This script is setup as a cronjob to be run every hour. <br />
The environment that we are currently using is an AWS t2.micro (free tier): <br />
<br />

**10 0-23 * * 1-5 ec2-user /home/ec2-user/talend-gpc-scheduler/gcp_instances_start-stop.sh**


## Zones
**GCP zones, cities, and UTC start & stop times**

| **Zones** |	**GCP city**  |	**Talend city**	| **on (UTC)** | **off (UTC)** |
--------------------------|---------------|-------------|---------|----------|
| asia-southeast1-b	      |	singapore	    |	bangalore	  |	0030	  | 1200     |
| asia-southeast1-a	      |	singapore	    |	bangalore	  |	0030	  |	1230     |
| europe-west1-d	        |	belgium		    |	suresnes	  |	0400	  |	1600     |
| europe-west1-c		      |	belgium		    |	suresnes	  |	0400	  |	1600     |
| europe-west1-b		      |	belgium		    |	suresnes	  |	0400	  |	1600     |
| europe-west3-b		      |	frankfurt	    |	bonn		    |	0400	  |	1600	   |
| europe-west3-c		      |	frankfurt	    |	bonn		    |	0400	  |	1600     |
| europe-west3-a		      |	frankfurt	    |	bonn		    |	0400	  |	1600     |
| europe-west2-c		      |	london		    |	london		  |	0500	  |	1700     |
| europe-west2-a		      |	london		    |	london		  |	0500	  |	1700     |
| europe-west2-b	       	|	london		    |	london		  |	0500	  |	1700     |
| us-east1-d		          |	s_carolina	  |	atlanta	    |	1000	  |	2200     |
| us-east1-c		          |	s_carolina	  |	atlanta	    |	1000	  |	2200     |
| us-east1-b 	   	        |	s_carolina	  |	atlanta	    |	1000	  |	2200     |		
| us-central1-c		        |	iowa          |	           	|	1100	  |	2300     |
| us-central1-a		        |	iowa		      |			        |	1100	  |	2300     |
| us-central1-f		        |	iowa		      |			        |	1100	  |	2300     |
| us-central1-b		        |	iowa		      |		          |	1100	  |	2300  	 |
| us-east4-b		          |	n_virginia	  |			        |	1100	  |	2300     |
| us-east4-a		          |	n_virginia	  |	     		    |	1100	  |	2300 	   |
| us-east4-c		          |	n_virginia	  |			        |	1100	  |	2300  	 |
| us-west1-b		          |	oregon		    |	irvine		  |	1300	  |	0100  	 |
| us-west1-a		          | oregon		    |	irvine		  |	1300	  |	0100     |
| us-west1-c		          | oregon		    |	irvine		  |	1300	  |	0100     |
| australia-southeast1-a	|	sydney		    |			        |	2000	  |	0800     |
| australia-southeast1-c	|	sydney		    |			        |	2000	  |	0800	   |
| australia-southeast1-b	|	sydney		    |             |	2000	  |	0800	   |
| asia-northeast1-c	      |	tokyo		      |			        |	2100	  |	0900	   |
| asia-northeast1-a	      |	tokyo		      |			        |	2100	  |	0900	   |
| asia-northeast1-b	      |	tokyo		      |			        |	2100	  |	0900	   |
| asia-east1-a		        | taiwan		    |	beijing     |	2200	  |	1000	   |
| asia-east1-c		        | taiwan		    |	beijing     |	2200	  |	1000	   |
| asia-east1-b          	| taiwan		    |	beijing     |	2200	  |	1000	   |


## Contributors

@fgalindo7 <br />
