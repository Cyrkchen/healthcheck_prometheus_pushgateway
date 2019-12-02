# healthcheck_prometheus_pushgateway
ENV URLS="http://xxx.yyy.zzz/healthcheck,http://aaa.bbb.ccc/healthcheck"
- Which you want check http duration request

ENV CURL_CONNECT_TIMEOUT=15
- set curl connect timeout

ENV CURL_MAX_TIME=15
- set curl max timeout

ENV PUSHGATEWAY_URL="http://pushgateway.example.org:9091/metrics/job/some_job"
- Prometheus Pushgateway URL
