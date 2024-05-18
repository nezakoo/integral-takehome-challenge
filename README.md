[![Linter & Unittests & Deploy](https://github.com/nezakoo/integral-takehome-challenge/actions/workflows/ci.yml/badge.svg)](https://github.com/nezakoo/integral-takehome-challenge/actions/workflows/ci.yml)
# Platform Engineering Takehome Challenge: Q2 2024

## Overview

This project demonstrates the deployment and scaling of a simple web application on Kubernetes, showcasing auto-scaling capabilities to handle varying load conditions. The application is containerized using Docker and deployed on a Kubernetes cluster with configurations for auto-scaling based on CPU usage and custom metrics.

## Prerequisites

- Docker
- Kubernetes cluster (Minikube, Kind, or any cloud provider's Kubernetes service)
- kubectl configured to interact with your Kubernetes cluster
- Prometheus and Alertmanager for monitoring and metrics (optional for advanced metrics and alerts)

## Project Structure

```
.
├── .github
│   └── workflows
│       └── ci.yml
├── app
│   ├── Dockerfile
│   ├── api.py
│   ├── app.py
│   ├── requirements.txt
│   └── unittests.py
├── app-manifests.yaml
├── load-tests
│   └── Dockerfile
└── prometheus
    ├── deploy_alert_manager_rules.sh
    └── enable_app_prometheus.sh
```

## Setup Instructions

### 1. Building the Docker Image

Navigate to the `app` directory and build the Docker image:

```bash
cd app
docker build -t integral-app:1.0 .
```

### 2. Deploying the Application

Apply the Kubernetes manifests to create the deployment, service, and auto-scaling configurations:

```bash
kubectl apply -f app-manifests.yaml
```

### 3. Monitoring Setup (Optional)

If you are setting up monitoring with Prometheus, execute the scripts in the `prometheus` directory to configure alerting rules and scrape configurations:

```bash
../prometheus/deploy_alert_manager_rules.sh
../prometheus/enable_app_prometheus.sh
```

### 4. Performing Load Tests

Navigate to the `load-tests` directory and build the Docker image for the load testing tool:

```bash
cd load-tests
docker build -t load-tester .
```

Run the load testing tool using:

```bash
docker run --rm load-tester -n 1000 -c 10 http://integral-app-service.integral-app.svc.cluster.local:5000/
```

## Auto-Scaling Verification

To verify that auto-scaling is working, monitor the number of pods during the load test:

```bash
kubectl get hpa -n integral-app --watch
```

## Additional Information

- **Custom Metrics for Auto-Scaling:** The application is configured to scale based on custom metrics (`requests_per_second`), which is monitored by Prometheus.
- **CI/CD Integration:** Instructions to integrate with CI/CD pipelines (like Jenkins, GitHub Actions, etc.) can be added as needed.
- **Logging and Monitoring Solution:** Set up using Prometheus and Alertmanager, scripts provided in the `prometheus` folder.

## Testing

To run unit tests for the application, navigate back to the `app` directory and execute:

```bash
python -m unittest unittests.py
```

## CI/CD Integration

This project is integrated with GitHub Actions to automate linting, unit tests, and deployment.
Here's a brief overview of the CI/CD workflows:

- Linter: Checks the code for style and complexity issues.
- Unittests: Runs unit tests to ensure functionality.
- Deploy: Deploys the application to Kubernetes, triggered manually via workflow dispatch.
