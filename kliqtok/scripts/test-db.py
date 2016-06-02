from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from kt.models import User

db_uri = 'postgresql://tranzmt_api:express88hotels59thimble@localhost/tranzmt_api'
db_engine = create_engine( db_uri )

Session = sessionmaker(bind=db_engine)
db_session = Session()

for user_result in db_session.query(User):
  print user_result.username
