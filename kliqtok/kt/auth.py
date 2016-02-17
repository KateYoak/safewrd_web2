from bottle import request, HTTPError
import json
import redis
from kt.models import User

def get_redis_connection(app):
    return redis.StrictRedis(host=app.config['redis']['host'], port=int(app.config['redis']['port']), db=int(app.config['redis']['db']))


class Session(object):

    def __init__(self, db, key, prefix = ''):
        self.db = db
        self.key = '%s%s' % (prefix, key)
        rdb_data = self._get_from_rdb()
        if rdb_data:
            self.data = json.loads(rdb_data)
        else:
            self.data = {}

    def _get_from_rdb(self):
        return self.db.get(self.key)

    def __getitem__(self, key):
        return self.data[key]

    def get(self, key, default = None):
        return self.data.get(key, default)

    def __setitem__(self, key, val):
        self.data[key] = val

    def save(self):
        self.db.set(self.key, json.dumps(self.data))


def check_authentication(app):
    """
    This is the proper decorator for getting session, etc.
    """

    def wrapper(fun):

        def inner(*a, **kw):
            rdb = request.rdb
            db_sess = request.db
            err = HTTPError(403, body='Not authorized')
            if 'access_token' not in request.cookies.keys():
                raise err
            else:
                request.session = Session(rdb, request.get_cookie('access_token'), prefix=app.config['kliqtok']['session_prefix'])
                user_id = request.session.get('user_id')
                if not user_id:
                    raise err
                request.user = db_sess.query(User).filter(User.id == user_id).first()
            return fun(*a, **kw)

        return inner

    return wrapper


def check_authentication_get_param(app):
    """
    This is the proper decorator for getting session, etc.
    """

    def wrapper(fun):

        def inner(*a, **kw):
            rdb = request.rdb
            db_sess = request.db
            err = HTTPError(403, body='Not authorized')
            if 'access_token' not in request.GET.keys():
                raise err
            else:
                request.session = Session(rdb, request.GET.get('access_token'), prefix=app.config['kliqtok']['session_prefix'])
                user_id = request.session.get('user_id')
                if not user_id:
                    raise err
                request.user = db_sess.query(User).filter(User.id == user_id).first()
            return fun(*a, **kw)

        return inner

    return wrapper
