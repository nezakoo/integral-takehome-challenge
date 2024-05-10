import unittest
from app import app

class IntegralAppTestCase(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

    def test_health_check(self):
        response = self.app.get('/healthz')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"status": "OK"})

    def test_readiness_probe_initial(self):
        response = self.app.get('/readyz')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"status": "OK"})

    def test_enable_readiness(self):
        response = self.app.get('/readyz/enable')
        self.assertEqual(response.status_code, 202)
        followup = self.app.get('/readyz')
        self.assertDictEqual(followup.json, {"status": "OK"})

    def test_disable_readiness(self):
        response = self.app.get('/readyz/disable')
        self.assertEqual(response.status_code, 202)
        followup = self.app.get('/readyz')
        self.assertDictEqual(followup.json, {"status": "SERVICE UNAVAILABLE"})

    def test_get_env(self):
        response = self.app.get('/env')
        self.assertEqual(response.status_code, 200)

    def test_get_headers(self):
        response = self.app.get('/headers')
        self.assertEqual(response.status_code, 200)

    def test_delay_response(self):
        response = self.app.get('/delay/1')
        self.assertEqual(response.status_code, 200)
        self.assertDictEqual(response.json, {"delay": 1})

    def test_metrics_endpoint(self):
        response = self.app.get('/metrics')
        self.assertEqual(response.status_code, 200)
        # Verify the exact content type, including charset
        self.assertEqual(response.content_type, 'text/plain; charset=utf-8')
        # Check if the response contains the specific metric name
        self.assertIn('requests_per_second', response.data.decode('utf-8'))

if __name__ == '__main__':
    unittest.main()
