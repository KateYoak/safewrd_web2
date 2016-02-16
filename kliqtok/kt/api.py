import os
import sys
import ConfigParser
import OpenTokSDK
import uuid
import bottle
from bottle import Bottle, request, response, run, HTTPError, hook
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from kt.auth import check_authentication_get_param, check_authentication, get_redis_connection
from kt.notifier import Notifier
import json
from sqlalchemy.orm.exc import NoResultFound
from models import User, OAuth, Contact, Kliq
from marrow.mailer import Mailer
from kt.urlformatter import make_url
CONFIG_ENV_VAR = 'KLIQTOK_SETTINGS'
DEFAULT_CONFIG = 'kliq.ini'

def instantiate_app():
    """
    Reads configuration from ini file, instantiates app and sets
    config settings to what's defined in ini file.
    """
    config_file_name = os.environ.get(CONFIG_ENV_VAR, DEFAULT_CONFIG)
    file_loc = os.path.join(os.path.dirname(__file__), os.pardir, config_file_name)
    cc = ConfigParser.ConfigParser()
    cc.read(file_loc)
    app = Bottle()
    for section in cc.sections():
        app.config[section] = dict(cc.items(section))

    debug = True if app.config['kliqtok']['debug'] == 'true' else False
    app.config['kliqtok']['debug'] = debug
    db_engine = create_engine(app.config['kliqtok']['db_url'])
    app.config['dbsession'] = sessionmaker(bind=db_engine)
    app.config['project_dir'] = os.path.dirname(__file__)
    app.mailer = Mailer(dict(transport=dict(use='smtp', host=app.config['smtp']['host'], username=app.config['smtp']['user'], password=app.config['smtp']['pass'], port=app.config['smtp']['port'], tls='ssl', timeout=int(app.config['smtp']['timeout'])), manager='immediate'))
    app.mailer.start()
    bottle.debug(debug)
    return app


app = instantiate_app()

@app.hook('before_request')
def setup_dbs():
    request.db = app.config['dbsession']()
    request.rdb = get_redis_connection(app)


def generic_error_handler(err):
    response.content_type = 'application/json'
    response.body = json.dumps({'error': response.body})
    return response


@app.error(500)
def server_error(err):
    if app.config['kliqtok']['debug']:
        response.content_type = 'text/plain'
        response.body = err.traceback
        try:
            sys.stderr.write(err.traceback)
        except TypeError:
            pass

    else:
        response.content_type = 'text/heml'
        response.body = 'Server error'
        sys.stderr.write(err.traceback)
    return response


@app.error(400)
def bad_request(err):
    return generic_error_handler(err)


@app.error(404)
def not_found(err):
    return generic_error_handler(err)


@app.error(403)
def forbidden(err):
    return generic_error_handler(err)


@app.post('/v1/tok_sessions/')
@check_authentication_get_param(app)
def create_sessions():
    """
    Received a cliq json structure, and returns the opentok session
    and tokens.
    """
    sys.stderr.write('\n\n')
    sys.stderr.write('\n\nRequest POST: %s' % str(request.POST.__dict__))
    sys.stderr.write('\n\nRequest GET: %s' % str(request.GET.__dict__))
    api_key = app.config['tokbox']['api_key']
    api_secret = app.config['tokbox']['api_secret']
    try:
        data = json.loads(request.body.read())
        sys.stderr.write('\n\nRequest body: in json %s' % data)
    except ValueError:
        raise HTTPError(400, body='Body should be a JSON Hash')

    if len(data) > 1:
        raise HTTPError(400, body='Only one session ID can be provided at this point.')
    cliq = data[0]
    sys.stderr.write('\n\nKlics found in request body: %s' % str(cliq))
    try:
        kliq = request.db.query(Kliq).filter(Kliq.id == cliq['id']).one()
        uuid.UUID(cliq['id'])
    except (NoResultFound, KeyError, ValueError):
        raise HTTPError(400, body='Invalid cliq ID(s)')

    if not cliq.get('contacts', None):
        raise HTTPError(400, body='No contact in Cliq')
    for user in cliq['contacts']:
        try:
            uuid.UUID(user['id'])
        except (KeyError, ValueError):
            raise HTTPError(400, body='Invalid user ID(s)')

    sessions = []
    opentok_sdk = OpenTokSDK.OpenTokSDK(api_key, api_secret)
    tok_session = opentok_sdk.create_session()
    session_obj = {'cliq_id': cliq['id'],
     'tok_session_id': tok_session.session_id,
     'tok_tokens': [{'user_id': request.user.id,
                     'token': opentok_sdk.generate_token(tok_session.session_id)}]}
    sessions.append(session_obj)
    source_contact = request.db.query(Contact).filter(Contact.user_id == request.user.id).order_by(Contact.id.asc()).first()

    def url_machine(contact):
        ntkn = opentok_sdk.generate_token(tok_session.session_id)
        return make_url(contact.id, tok_session.session_id, ntkn)

    notifier = Notifier(kliq)
    sys.stderr.write('\n\nCliq, cliq id and name: %s, %s: %s' % (kliq.id, kliq.name, str([ (x.name,
      x.id,
      x.user_id,
      x.owner_id,
      x.email) for x in kliq.contacts ])))
    sys.stderr.write('\n\nSending nofication, user is %s' % request.user.id)
    sys.stderr.write('\n\nContact used: (first contact that is in this kliq and has the user ID of the session) %s' % getattr(source_contact, 'name', 'NOTHING'))
    notifier.notify_share(source_contact, '%(sender_name)s wants to video-chat with you', 'video_share_email.txt', 'video_share_email.html', {'sender_name': getattr(source_contact, 'name', 'None'),
     'sender_email': getattr(source_contact, 'email', 'kliq@kliqmobile.com'),
     'message': 'CLQ Connect Request'}, url_machine)
    sys.stderr.write('\n\nDATA: %s' % json.dumps(sessions))
    return {'sessions': sessions}


if __name__ == '__main__':
    run(app, host='localhost', port=8080, debug=True)
