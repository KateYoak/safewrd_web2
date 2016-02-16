from setuptools import setup, find_packages

setup(
    name = "KliqTok",
    version = "0.1",
    packages = find_packages(),
    install_requires = (
        'bottle',
        'opentok',
        'sqlalchemy',
        'oauthlib',
        'mysql-python',
        'redis',
        'futures',
        'marrow.mailer',
        'jinja2',
        ),
    setup_requires = (
        'nose',
        'webtest',
        'pinocchio',
        'coverage',
        ),
    test_suite = 'nose.collector',
)
