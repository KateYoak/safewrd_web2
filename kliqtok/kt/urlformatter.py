import json
from bottle import request
import urllib

def make_url(contact_id, session_id, token_id):
    """
    To decode:
    get the referrer from the url parameters. It may look like this:
    
    contactId%3D1A9F1F2B-A297-1014-8D7F-A3F7C84F2656%26openTokPayload%3D%257B%2522tokTokenId%2522%253A%2Bnull%252C%2B%2522tokSessionId%2522%253A%2B%25221_MX40NDQxMDUwMn5-TW9uIE5vdiAxOCAwMDo1Mzo0NCBQU1QgMjAxM34wLjUzMzIwMDN-%2522%257D
    
    
    """
    url_base = 'https://play.google.com/store/apps/details?'
    payload = {'contactId': contact_id,
     'tokSessionId': session_id,
     'tokTokenId': token_id.replace('=', '|')}
    new_payload = [('id', request.app.config['kliqtok']['app_name']), ('referrer', urllib.urlencode(payload))]
    formatted_payload = urllib.urlencode(new_payload)
    url = '%s%s' % (url_base, formatted_payload)
    return url
