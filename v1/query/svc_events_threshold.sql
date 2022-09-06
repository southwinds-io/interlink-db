-- shows the list of service up/down events with
--   the count of facets which are up and
--   the time interval when the number of total facets is below a specified threshold count
SELECT *
FROM link_ses_events_threshold('{{PLATFORM}}', '{{SERVICE}}', '{{FACET}}', '{{THRESHOLD}}')