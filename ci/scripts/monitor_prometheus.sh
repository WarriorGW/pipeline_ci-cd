#!/usr/bin/env bash
set -euo pipefail

PROM_URL="${PROM_URL:-http://prometheus.monitoring.svc:9090}"
NAMESPACE="app-prod"
DEPLOYMENT="myservice"
WINDOW="5m"   # ventana de evaluación

# thresholds
ERROR_RATE_THRESHOLD=0.02     # 2% -> as fraction
P95_THRESHOLD_MS=500

# PromQL queries (assumes instrumentation exposing http_requests_total and request_duration_seconds)
# Ajusta según tus métricas reales
ERROR_RATE_QUERY='sum(rate(http_requests_total{job="myservice",status=~"5.."}[5m])) / sum(rate(http_requests_total{job="myservice"}[5m]))'
P95_QUERY='histogram_quantile(0.95, sum(rate(request_duration_seconds_bucket{job="myservice"}[5m])) by (le))'

# fetch value function
fetch_prometheus() {
  local q="$1"
  curl -sG --data-urlencode "query=${q}" "${PROM_URL}/api/v1/query" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0"
}

error_rate=$(fetch_prometheus "${ERROR_RATE_QUERY}")
p95_seconds=$(fetch_prometheus "${P95_QUERY}")

# convert p95 to ms
p95_ms=$(awk "BEGIN {print ${p95_seconds} * 1000}")

echo "Prometheus read: error_rate=${error_rate}, p95_ms=${p95_ms}"

# compare (floating)
error_exceeded=$(awk "BEGIN {print (${error_rate} > ${ERROR_RATE_THRESHOLD}) ? 1 : 0}")
p95_exceeded=$(awk "BEGIN {print (${p95_ms} > ${P95_THRESHOLD_MS}) ? 1 : 0}")

if [ "${error_exceeded}" -eq 1 ] || [ "${p95_exceeded}" -eq 1 ]; then
  echo "Threshold breached -> triggering rollback"
  ./rollback.sh
  exit 0
else
  echo "Metrics ok"
fi

