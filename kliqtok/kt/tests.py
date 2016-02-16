from unittest import TestCase
from webtest import TestApp
from Cookie import SimpleCookie
import json

class ApiTest(TestCase):

    def setUp(self):
        from .api import app
        self.app = TestApp(app, extra_environ={'HTTP_HOST': 'api.kliqmobile.com'})

    def test_create_session_accepts_only_post(self):
        """
        Verify status code for unsupported methods.
        """
        assert self.app.get('/v1/tok_sessions/?access_token=c8018dff63fbac899e6a785b559912e43780dfdf', status=405)
        assert self.app.put('/v1/tok_sessions/?access_token=c8018dff63fbac899e6a785b559912e43780dfdf', status=405)
        assert self.app.delete('/v1/tok_sessions/?access_token=c8018dff63fbac899e6a785b559912e43780dfdf', status=405)

    def test_404(self):
        """
        Check 404 format
        """
        resp = self.app.get('/dontexist/', status=404)
        expected_response = {'error': "Not found: '/dontexist/'"}
        self.assertEquals(json.loads(resp.body), expected_response)

    def test_bad_request(self):
        """
        Check 400 Format
        """
        payload = 'bad json'
        resp = self.app.post('/v1/tok_sessions/?access_token=c8018dff63fbac899e6a785b559912e43780dfdf', payload, status=400, headers={'Cookie': 'access_token=c8018dff63fbac899e6a785b559912e43780dfdf'})
        expected_response = {'error': 'Body should be a JSON Hash'}
        self.assertEquals(json.loads(resp.body), expected_response)

    def test_create_session_and_tokens(self):
        """
        Tests that when supplied with a cliq JSON structure, the
        application makes the proper API calls to TokBox to create a
        discussion, and add participants.
        
        
        """
        payload = '[\n            {\n                "id": "1F7E6878-4A16-11E3-BCD6-1DA09ECA3188",\n                "name": "Cool kliq",\n                "image": null,\n                "created": "2012-08-31T02:49:20",\n                "contacts": [\n                    {\n                        "id": "1A12295A-4350-11E3-8B7B-1DA09ECA3188",\n                        "userId": null,\n                        "name": "Arie Kanarie",\n                        "service": "google",\n                        "email": "arie@gmail.com",\n                        "image": "http://a0.twimg.com/sticky/default_profile_images/default_profile_5_normal.png",\n                        "created": "2012-08-31T02:49:20"\n                        }\n                    ]\n                }\n            ]'
        resp = self.app.post('/v1/tok_sessions/?access_token=c8018dff63fbac899e6a785b559912e43780dfdf', payload, headers={'Cookie': 'access_token=c8018dff63fbac899e6a785b559912e43780dfdf'})
        self.assertEquals(resp.status_code, 200)
        data = json.loads(resp.body)
        sessions = data['sessions']
        self.assertEquals(type(data), dict)
        self.assertEquals(type(sessions), list)
        self.assertEquals(sessions[0]['cliq_id'], '1F7E6878-4A16-11E3-BCD6-1DA09ECA3188')
        self.assertEquals(len(sessions[0]['tok_tokens']), 1)
        self.assertEquals(sessions[0]['tok_tokens'][0]['user_id'], '1A12295A-4350-11E3-8B7B-1DA09ECA3188')

    def test_bad_uuid(self):
        """
        Tests a bad UUID.
        """
        payload = '[\n            {\n                "id": "31269EE000-",\n                "name": "Cool kliq",\n                "image": null,\n                "created": "2012-08-31T02:49:20",\n                "contacts": [\n                    {\n                        "id": "1A9F1F2B-A297-1014-8D7F-A3F7C84F2656",\n                        "userId": null,\n                        "name": "Arie Kanarie",\n                        "service": "google",\n                        "email": "arie@gmail.com",\n                        "image": "http://a0.twimg.com/sticky/default_profile_images/default_profile_5_normal.png",\n                        "created": "2012-08-31T02:49:20"\n                        },\n                    {\n                        "id": "ABCDEF12-A297-1014-8D7F-A3F7C84F2656",\n                        "userId": null,\n                        "name": "John Doe",\n                        "service": "google",\n                        "email": "john@gmail.com",\n                        "image": "http://a0.twimg.com/sticky/default_profile_images/default_profile_5_normal.png",\n                        "created": "2012-09-03T02:49:20"\n                        }\n                    ]\n                }\n            ]'
        resp = self.app.post('/v1/tok_sessions/?access_token=c8018dff63fbac899e6a785b559912e43780dfdf', payload, status=400, headers={'Cookie': 'access_token=c8018dff63fbac899e6a785b559912e43780dfdf'})
        self.assertEquals(json.loads(resp.body), {u'error': u'Invalid cliq ID(s)'})
        payload = '[\n            {\n                "id": "31269EE0-A297-1014-BB8E-A3F7C84F2656",\n                "name": "Cool kliq",\n                "image": null,\n                "created": "2012-08-31T02:49:20",\n                "contacts": [\n                    {\n                        "id": "Hello world.",\n                        "userId": null,\n                        "name": "Arie Kanarie",\n                        "service": "google",\n                        "email": "arie@gmail.com",\n                        "image": "http://a0.twimg.com/sticky/default_profile_images/default_profile_5_normal.png",\n                        "created": "2012-08-31T02:49:20"\n                        },\n                    {\n                        "id": "ABCDEF12-A297-1014-8D7F-A3F7C84F2656",\n                        "userId": null,\n                        "name": "John Doe",\n                        "service": "google",\n                        "email": "john@gmail.com",\n                        "image": "http://a0.twimg.com/sticky/default_profile_images/default_profile_5_normal.png",\n                        "created": "2012-09-03T02:49:20"\n                        }\n                    ]\n                }\n            ]'
        resp = self.app.post('/v1/tok_sessions/?access_token=c8018dff63fbac899e6a785b559912e43780dfdf', payload, status=400, headers={'Cookie': 'access_token=c8018dff63fbac899e6a785b559912e43780dfdf'})
        self.assertEquals(json.loads(resp.body), {u'error': u'Invalid user ID(s)'})
        payload = '[\n            {\n                "id": "31269EE0-A297-1014-BB8E-A3F7C84F2656",\n                "name": "Cool kliq",\n                "image": null,\n                "created": "2012-08-31T02:49:20",\n                "contacts": []\n                }\n            ]'
        resp = self.app.post('/v1/tok_sessions/?access_token=c8018dff63fbac899e6a785b559912e43780dfdf', payload, status=400, headers={'Cookie': 'access_token=c8018dff63fbac899e6a785b559912e43780dfdf'})
        self.assertEquals(json.loads(resp.body), {u'error': u'No contact in Cliq'})

    def test_auth_token(self):
        pass
