FROM ubuntu:latest
RUN apt-get update && apt-get -y install cron curl
COPY entrypoint.sh /entrypoint.sh
COPY health_metrics.sh /health_metrics.sh
ENTRYPOINT ["bash","entrypoint.sh"]