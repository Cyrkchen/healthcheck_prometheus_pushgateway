#!/bin/bash
declare -p | grep -E 'URLS|WEB_URLS_URI|PUSHGATEWAY_URL|CURL_CONNECT_TIMEOUT|CURL_MAX_TIME' > /container.env

if [ ! "${CRON_TIME}" ];then
    CRON_TIME="*/5 * * * *"
fi

cat <<EOF > /healthcheck.cron
SHELL=/bin/bash
BASH_ENV=/container.env
${CRON_TIME} /health_metrics.sh >> /var/log/cron.log 2>&1
EOF
chmod 0644 /healthcheck.cron
crontab /healthcheck.cron
touch /var/log/cron.log
cron && tail -f /var/log/cron.log
