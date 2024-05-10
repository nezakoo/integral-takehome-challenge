#!/bin/bash

set -e
set -u
set -o pipefail
set -x

# Function to patch Prometheus Server ConfigMap
patch_prometheus_server() {
    echo "Patching Prometheus Server ConfigMap with new scrape job..."
    kubectl patch cm prometheus-server -n monitoring --type=json -p='[
        {
            "op": "add",
            "path": "/data/prometheus.yml/scrape_configs/-",
            "value": {
                "job_name": "integral-app",
                "scrape_interval": "10s",
                "static_configs": [
                    {
                        "targets": ["integral-app-service.integral-app.svc.cluster.local:5000"]
                    }
                ]
            }
        }
    ]'
}

# Function to patch Prometheus Adapter ConfigMap
patch_prometheus_adapter() {
    echo "Patching Prometheus Adapter ConfigMap with new metrics rule..."
    kubectl patch cm prometheus-adapter -n monitoring --type=merge -p='
data:
  config.yaml: |
    rules:
      - seriesQuery: "requests_per_second{job=\"integral-app\"}"
        resources:
          overrides:
            namespace: {resource: "namespace"}
            pod: {resource: "pod"}
        name:
          matches: "^requests_per_second$"
          as: "requests_per_second"
        metricsQuery: "sum(rate(requests_per_second{job=\"integral-app\"}[1m])) by (namespace, pod)"
    '
}

# Function to patch Alertmanager ConfigMap with email configuration
patch_alertmanager_config() {
    echo "Patching Alertmanager ConfigMap with email configuration..."
    kubectl patch configmap alertmanager-prometheus-alertmanager -n monitoring --type=merge -p='
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
        subject: "Alert - {{ "{{" }} .Status {{ "}}" }}"
        html: "<h2>{{ "{{" }} .Status | toTitle {{ "}}" }}</h2><p>{{ "{{" }} .CommonAnnotations.summary {{ "}}" }}</p>"
'
}

# Function to restart Prometheus and Alertmanager deployments to apply changes
restart_services() {
    echo "Restarting Prometheus and Alertmanager to apply changes..."
    kubectl rollout restart deployment prometheus-kube-prometheus-stack-prometheus -n monitoring
    kubectl rollout restart deployment prometheus-kube-prometheus-stack-alertmanager -n monitoring
}

# Main script execution
echo "Starting the Prometheus configuration update process..."

patch_prometheus_server
patch_prometheus_adapter
patch_alertmanager_config

# Uncomment to Restart Prometheus and Alertmanager to apply changes
# restart_services

echo "Prometheus configuration update process completed."
