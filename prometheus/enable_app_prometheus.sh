#!/bin/bash

set -e
set -u
set -o pipefail
set -x

ALERTING=false

# Function to patch Prometheus Server ConfigMap
patch_prometheus_server() {
    echo "Patching Prometheus Server ConfigMap with new scrape job..."
    kubectl patch configmap prometheus-server -n monitoring --type=merge -p='
data:
  prometheus.yml: |
    global:
      scrape_interval: 10s
      evaluation_interval: 15s
    scrape_configs:
      - job_name: 'integral-app'
        static_configs:
          - targets: ['integral-app-service.integral-app.svc.cluster.local:5000']
        relabel_configs:
          - source_labels: [__address__]
            target_label: instance
          - source_labels: [__meta_kubernetes_pod_name]
            target_label: pod
          - source_labels: [__meta_kubernetes_namespace]
            target_label: namespace
'
}

# Function to patch Prometheus Adapter ConfigMap
patch_prometheus_adapter() {
    echo "Patching Prometheus Adapter ConfigMap with new metrics rule..."
    kubectl patch cm prometheus-adapter -n monitoring --type=merge -p='
data:
  config.yaml: |
    rules:
      - seriesQuery: 'requests_per_second{job="integral-app"}'
        resources:
          overrides:
            namespace: {resource: "namespace"}
            pod: {resource: "pod"}
        name:
          matches: "^requests_per_second$"
          as: "requests_per_second"
        metricsQuery: "sum(rate(requests_per_second{job="integral-app"}[1m])) by (namespace, pod)"
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
    kubectl rollout restart deployment prometheus-server -n monitoring
    kubectl rollout restart deployment prometheus-adapter -n monitoring
    if $ALERTING; then
        kubectl rollout restart deployment prometheus-alertmanager -n monitoring
    fi
}

# Main script execution
echo "Starting the Prometheus configuration update process..."

patch_prometheus_server
patch_prometheus_adapter
if $ALERTING; then
    patch_alertmanager_config
fi

# Uncomment to Restart Prometheus and Alertmanager to apply changes
restart_services

echo "Prometheus configuration update process completed."
