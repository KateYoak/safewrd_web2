from setuptools import setup, find_packages

setup(
    name = "KliqTok",
    version = "0.1",
    packages = find_packages(),
    install_requires = (
        'bottle',
        'opentok-python-sdk',
        'sqlalchemy',
        'oauthlib',
        'psycopg2',
        'redis',
        'futures',
        'marrow.mailer==4.0.0',
        'jinja2',
        'uwsgi',
        ),
    setup_requires = (
        'nose',
        'webtest',
        'pinocchio',
        'coverage',
        ),
    test_suite = 'nose.collector',
)
