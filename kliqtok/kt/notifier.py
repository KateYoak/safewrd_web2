"""
Services:
google
twitter
facebook
yahoo
linkedin
"""
import sys
import os
from collections import defaultdict
from bottle import request
from marrow.mailer import Message
from jinja2 import Template
from kt.models import Contact

class BaseNotifierBackend(object):

    def __init__(self, notifier_collection):
        self.notifier_collection = notifier_collection

    def notify_share(self, sender, contact, subject, plain_template, template, context):
        pass


class EmailBackend(BaseNotifierBackend):

    def load_template(self, tpl_name):
        template_dir = os.path.join(request.app.config['project_dir'], 'templates')
        return Template(open(os.path.join(template_dir, tpl_name), 'r').read())

    def notify_share(self, sender, contact, subject, plain_template, template, context):
        mailer = request.app.mailer
        html_message = self.load_template(template).render(**context)
        plain_message = self.load_template(plain_template).render(**context)
        from_email = request.app.config['smtp']['from_email']
        if request.app.config['kliqtok']['debug']:
            recipients = ['benoitcsirois@gmail.com', 'jr@clqmobile.com']
        else:
            recipients = [contact.email]
        message = Message(author=from_email, to=recipients)
        message.subject = subject % context
        message.plain = plain_message
        message.rich = html_message
        mailer.send(message)


class OAuthBackend(BaseNotifierBackend):

    def notify_share(self, sender, contact, subject, plain_template, template, context):
        pass


class TwitterBackend(BaseNotifierBackend):

    def notify_share(self, sender, contact, subject, plain_template, template, context):
        pass


class Notifier(object):

    def __init__(self, kliq):
        self.app = request.app
        self.kliq = kliq
        self.backends = defaultdict(lambda : EmailBackend(self), {'twitter': TwitterBackend(self)})

    def notify_share(self, sender, subject, plain_template, template, context, url_machine):
        """
        Send a notification to each contact.
        """
        for contact in self.kliq.contacts:
            sys.stderr.write('\n\nSending notigication to: %s, %s' % (contact.name, contact.email))
            cctx = context.copy()
            cctx['recipient_name'] = contact.name
            cctx['url'] = url_machine(contact)
            self.backends[contact.service].notify_share(sender, contact, subject, plain_template, template, cctx)
