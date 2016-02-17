INFO

The url /v1/tok_sessions/:

* Takes POST method.
* Body should be a json string.
* Json data should be an array of Cliqs (one or more).
* The format should be as defined in the API here: http://developers.kliqmobile.com/v1/kliqs/
* The response will contain the created TOK Sessions, and the Token keys.
* The API is currently NOT PROTECTED. Keep the URL a secret for now.

Sample usage:

curl --data '[{"id": "31269EE0-A297-1014-BB8E-A3F7C84F2656","contacts": [{"id": "1A9F1F2B-A297-1014-8D7F-A3F7C84F2656"},{"id": "ABCDEF12-A297-1014-8D7F-A3F7C84F2656"}]}]' http://api.kliqmobile.com/v1/tok_sessions/


TO BUILD

$ cd <location of kliqtok>
$ virtualenv --no-site-packages env
$ source env/bin/activate
$ python setup.py develop


TO TEST

$ cd <location of kliqtok>
$ source env/bin/activate
$ python setup.py nosetests
