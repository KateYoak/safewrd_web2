import datetime
from sqlalchemy import Table, ForeignKey, Column, Integer, String, CHAR, Enum, DateTime, TEXT, BLOB, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    id = Column(CHAR(36), primary_key=True, nullable=False)
    username = Column(String(32), unique=True, nullable=False)
    password = Column(TEXT, nullable=False)
    email = Column(String(128), nullable=False)
    active = Column(Boolean, default=False)
    first_name = Column(String(32), nullable=False)
    last_name = Column(String(32), nullable=False)
    gender = Column(Enum('male', 'female'), nullable=True)
    picture = Column(BLOB, nullable=True)
    email_verified = Column(Boolean, nullable=True, default=False)
    created = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    oauth_tokens = relationship('OAuth', backref='user')
    contacts = relationship('Contact', primaryjoin='Contact.user_id==User.id', backref='user')
    owned_contacts = relationship('Contact', primaryjoin='Contact.owner_id==User.id', backref='owner')


class OAuth(Base):
    __tablename__ = 'oauth_tokens'
    id = Column(CHAR(36), primary_key=True, nullable=False)
    user_id = Column(CHAR(36), ForeignKey('users.id'), index=True, nullable=False)
    persona_id = Column(CHAR(36), nullable=True)
    token = Column(String(4096), nullable=False)
    secret = Column(String(4096), nullable=True)
    service = Column(Enum('google', 'twitter', 'facebook', 'yahoo', 'linkedin'), nullable=False)
    created = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    expires = Column(String(64), nullable=True)

    def __repr__(self):
        return "<OAuthToken(id='%s', user_id='%s', service='%s')>" % (self.id, self.user_id, self.service)


class Contact(Base):
    __tablename__ = 'contacts'
    id = Column(String(36), nullable=False, primary_key=True)
    user_id = Column(CHAR(36), ForeignKey('users.id'), index=True, nullable=True)
    owner_id = Column(String(36), ForeignKey('users.id'), nullable=False, index=True)
    handle = Column(String(300), nullable=False)
    c_hash = Column('hash', String(35), nullable=True)
    service = Column(Enum('google', 'twitter', 'facebook', 'yahoo', 'linkedin', 'manual'), nullable=False)
    screen_name = Column(String(75), nullable=True)
    name = Column(String(50), nullable=True)
    email = Column(String(50), nullable=True)
    phone = Column(String(15), nullable=True)
    website = Column(String(200), nullable=True)
    image = Column(String(255), nullable=True)
    gender = Column(Enum('male', 'female'), nullable=True)
    org_name = Column(String(75), nullable=True)
    org_title = Column(String(75), nullable=True)
    location = Column(String(200), nullable=True)
    timezone = Column(String(75), nullable=True)
    language = Column(String(10), nullable=True)
    optedin = Column(Boolean, nullable=False, default=False)
    created = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)


contact_kliq_assoc = Table('kliq_contact_map', Base.metadata, Column('kliq_id', CHAR(36), ForeignKey('kliqs.id')), Column('contact_id', CHAR(36), ForeignKey('contacts.id')))

class Kliq(Base):

    def __init__(self, *a, **kw):
        super(Kliq, self).__init__(*a, **kw)

    __tablename__ = 'kliqs'
    id = Column(CHAR(36), primary_key=True, nullable=False)
    user_id = Column(CHAR(36), primary_key=True, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    image = Column(String(150), nullable=True)
    created = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    contacts = relationship('Contact', secondary=contact_kliq_assoc, backref='kliqs')
