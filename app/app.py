import os
import time

from api import init_api
from flask import Flask, Response, request, jsonify
from collections import deque
from prometheus_client import Gauge, generate_latest

app = Flask(__name__)

# Initialize the API
init_api(app)

is_ready = True
request_times = deque()

# Environment variables from Downward API
NAMESPACE = os.getenv('POD_NAMESPACE', 'default')
POD_NAME = os.getenv('POD_NAME', 'unknown')

# Set up Prometheus metrics
requests_per_second = Gauge('requests_per_second', 'The number of requests per second.', ['namespace', 'pod'])

# Queue to store request timestamps for calculating requests per second
request_times = deque()


# Probes section
@app.route('/healthz', methods=['GET'])
def health_check():
    return jsonify(status='OK'), 200


@app.route('/readyz', methods=['GET', 'POST'])
def readiness_probe():
    global is_ready
    if is_ready:
        return jsonify(status='OK'), 200
    else:
        return jsonify(status='SERVICE UNAVAILABLE'), 503


@app.route('/readyz/enable', methods=['GET'])
def enable_readiness():
    global is_ready
    is_ready = True
    return 'Readiness enabled', 202


@app.route('/readyz/disable', methods=['GET'])
def disable_readiness():
    global is_ready
    is_ready = False
    return 'Readiness disabled', 202


@app.route('/env', methods=['GET'])
def get_env():
    env_list = {key: value for key, value in os.environ.items()}
    return jsonify(env_list), 200


@app.route('/headers', methods=['GET'])
def get_headers():
    headers_list = {key: value for key, value in request.headers.items()}
    return jsonify(headers_list), 200


@app.route('/delay/<int:seconds>', methods=['GET'])
def delay_response(seconds):
    time.sleep(seconds)
    return jsonify(delay=seconds), 200

@app.route('/metrics', methods=['GET'])
def metrics():
    # Update the requests_per_second metric
    rps_count = update_request_metrics()
    requests_per_second.labels(namespace=NAMESPACE, pod=POD_NAME).set(rps_count)
    # Generate and return all registered Prometheus metrics
    return Response(generate_latest(), mimetype='text/plain')

def update_request_metrics():
    now = time.time()
    request_times.append(now)
    # Remove requests older than 1 second from the deque
    while request_times and request_times[0] < now - 1:
        request_times.popleft()
    return len(request_times)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
