from flask_restx import Api, Namespace, Resource, fields

integral_app_ns = Namespace('integral_app', description='integral_app operations')

status_model = integral_app_ns.model('Status', {
    'status': fields.String,
})

env_model = integral_app_ns.model('EnvironmentVariables', {
    'key': fields.String,
    'value': fields.String,
})

header_model = integral_app_ns.model('Headers', {
    'header': fields.String,
    'value': fields.String,
})

metrics_model = integral_app_ns.model('Metrics', {
    'requests_per_second': fields.Integer(description='The number of requests per second')
})


@integral_app_ns.route('/healthz')
class HealthCheck(Resource):
    @integral_app_ns.marshal_with(status_model)
    def get(self):
        return {'status': 'OK'}


@integral_app_ns.route('/readyz')
class ReadinessProbe(Resource):
    def get(self):
        try:
            is_ready = True
            if is_ready:
                return {'status': 'OK'}
            else:
                return {'status': 'SERVICE UNAVAILABLE'}, 503
        except Exception as e:
            print(f"Error occurred: {e}")
            return {"message": "An error occurred while processing your request."}, 500


@integral_app_ns.route('/readyz/enable')
class EnableReadiness(Resource):
    def get(self):
        return {'message': 'Readiness enabled'}, 202


@integral_app_ns.route('/readyz/disable')
class DisableReadiness(Resource):
    def get(self):
        return {'message': 'Readiness disabled'}, 202


@integral_app_ns.route('/env')
class GetEnv(Resource):
    @integral_app_ns.marshal_list_with(env_model)
    def get(self):
        return [{'key': 'example_key', 'value': 'example_value'}]


@integral_app_ns.route('/headers')
class GetHeaders(Resource):
    @integral_app_ns.marshal_list_with(header_model)
    def get(self):
        return [{'header': 'example_header', 'value': 'example_value'}]


@integral_app_ns.route('/delay/<int:seconds>')
class DelayResponse(Resource):
    def get(self, seconds):
        return {'delay': seconds}


@integral_app_ns.route('/metrics')
class Metrics(Resource):
    @integral_app_ns.marshal_with(metrics_model)
    def get(self):
        global request_count
        request_count += 1  # Increment on each call
        return {'requests_per_second': request_count}


def init_api(app):
    api = Api(app, version='1.0', title='integral_app API',
        description='A simple integral_app API for demonstration purposes')
    api.add_namespace(integral_app_ns, path='/integral_app')
