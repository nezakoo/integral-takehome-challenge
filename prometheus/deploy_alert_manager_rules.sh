#!/bin/bash

set -e
set -u
set -o pipefail
set -x

# Function to apply Prometheus alerting rules
apply_prometheus_alert_rules() {
    echo "Applying Prometheus alert rules..."
    kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: requests-per-second-alert
  namespace: monitoring
spec:
  groups:
  - name: example-rules
    rules:
    - alert: HighRequestRate
      expr: sum(rate(requests_per_second{job="integral-app"}[1m])) by (namespace, pod) > 100
      for: 1m
      labels:
        severity: warning
      annotations:
        summary: High request rate in {{ '{{' }} $labels.namespace {{ '}}' }}
        description: "Request rate is high, more than 100 req/s (current value: {{ '{{' }} $value {{ '}}' }} req/s)"
EOF
}

# Function to update Alertmanager config with email notifications
update_alertmanager_config() {
    echo "Updating Alertmanager config for email notifications..."
    kubectl patch configmap alertmanager-prometheus-alertmanager -n monitoring --type merge -p='
data:
  alertmanager.yml: |
    global:
      smtp_smarthost: "smtp.example.com:587"
      smtp_from: "alertmanager@example.com"
      smtp_auth_username: "alertmanager@example.com"
      smtp_auth_password: "password"
    route:
      group_by: ["alertname"]
      group_wait: 10s
      group_interval: 10m
      repeat_interval: 1h
      receiver: "email-notifications"
    receivers:
    - name: "email-notifications"
      email_configs:
      - to: "your-email@example.com"
        send_resolved: true
        subject: "Alert - {{ '{{' }} .Status {{ '}}' }}"
        html: "<h2>{{ '{{' }} .Status | toTitle {{ '}}' }}</h2><p>{{ '{{' }} .CommonAnnotations.summary {{ '}}' }}</p>"
'
}

# Function to restart Prometheus and Alertmanager to apply changes
restart_services() {
    echo "Restarting Prometheus and Alertmanager to apply changes..."
    kubectl rollout restart deployment prometheus-kube-prometheus-stack-prometheus -n monitoring
    kubectl rollout restart deployment prometheus-kube-prometheus-stack-alertmanager -n monitoring
}

# Main script execution
echo "Starting the alerting configuration process..."

apply_prometheus_alert_rules
update_alertmanager_config
restart_services

echo "Alerting configuration process completed."
