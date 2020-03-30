#!/bin/bash

levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)
script_logging_level="INFO"

logThis() {
    local log_message=$1
    local log_priority=$2

    #check if level exists
    [[ ${levels[$log_priority]} ]] || return 1

    #check if level is enough
    (( ${levels[$log_priority]} < ${levels[$script_logging_level]} )) && return 2

    #log here
    echo "$(date) - ${log_message}"
}


function show_help {
   echo "\
   -p Pushgateway url like http://127.0.0.1:9091/metrics/job/healthcheck
   -u Check URLS like https://www.google.com,https://www.yahoo.com
   -w Get URLS from WEB like 'curl http://www.example.com'
      https://www.google.com
      https://www.yahoo.com
   "
}

while getopts "h?p:u:w:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    p)  PUSHGATEWAY_URL=$OPTARG
        ;;
    u)  URLS=(${OPTARG//,/ })
        ;;
    w)  WEB_URLS_URI=${OPTARG}
        ;;
    *)  show_help
        exit 0
    esac
done

BODY=()
METRICS_NAME="healthcheck_http_request_duration_seconds"

if [ ${WEB_URLS_URI} ]; then
   URLS_TEMP=$(curl ${WEB_URLS_URI})
   if [[ ${URLS_TEMP} =~ .*http.* ]]; then
        URLS+=( "${URLS_TEMP[@]//\\n/ }" )
   fi
fi

# dedup URLS
for url in $(echo "${URLS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
do
    logThis "start curl ${url}"
    health_metric=$(curl --connect-timeout ${CURL_CONNECT_TIMEOUT:-10}  --max-time ${CURL_MAX_TIME:-10} -o /dev/null -s -w "%{time_total}" ${url})
    health_metric=$(printf %.10f "${health_metric}")
    domain_name=(${url//\// })
    if [[ "${domain_name[0]}" == *"http"* ]];then
        url_temp=${domain_name[1]}
    else
        url_temp=${domain_name[0]}
    fi
    url_temp1=${url_temp//./_}
    url_temp1=${url_temp1//:/_}
    if [ ${PUSHGATEWAY_URL} ];then
        BODY+=("${METRICS_NAME}{name=\"${url_temp}\",id=\"${url}\"} ${health_metric}
        ")
    fi
        echo "${url_temp} ${health_metric}"
done

if [ ${PUSHGATEWAY_URL} ];then
echo "Start send metrics to prometheus push gateway"
cat <<EOF | curl --data-binary @- ${PUSHGATEWAY_URL}
# HELP ${METRICS_NAME}
# TYPE ${METRICS_NAME} gauge
${BODY[@]}
EOF
fi
