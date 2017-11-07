# gcp_scheduler_step_by_step

- get date and hour from the system
  - iterate through projects
      - save list of instances (NAME | ZONE | STATUS) in a tmp file *gcp_instances_list.txt*
        - iterate though list
        - read archive-date label
          - if archive-date == current date
            - call snapshot function
              - if snapshot successful
                - call delete instance function
              - else write in log problem
            - else do nothing
          - read scheduler label
            - Based on time and date
            - if time to start
              - start,
            - if time to stop
              - stop
            - else do nothing
