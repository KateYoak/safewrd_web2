# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey has `on_delete` set to the desired behavior.
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from __future__ import unicode_literals

from django.db import models


class Ambassadors(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    nickname = models.CharField(max_length=50, blank=True, null=True)
    firstname = models.CharField(db_column='firstName', max_length=50)  # Field name made lowercase.
    lastname = models.CharField(db_column='lastName', max_length=50)  # Field name made lowercase.
    email = models.CharField(unique=True, max_length=50, blank=True, null=True)
    phone = models.CharField(max_length=15)
    photo = models.CharField(max_length=255, blank=True, null=True)
    status = models.CharField(max_length=9)
    created = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'ambassadors'


class AuthGroup(models.Model):
    name = models.CharField(unique=True, max_length=80)

    class Meta:
        managed = False
        db_table = 'auth_group'


class AuthGroupPermissions(models.Model):
    group = models.ForeignKey(AuthGroup, models.DO_NOTHING)
    permission = models.ForeignKey('AuthPermission', models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_group_permissions'
        unique_together = (('group', 'permission'),)


class AuthPermission(models.Model):
    name = models.CharField(max_length=255)
    content_type = models.ForeignKey('DjangoContentType', models.DO_NOTHING)
    codename = models.CharField(max_length=100)

    class Meta:
        managed = False
        db_table = 'auth_permission'
        unique_together = (('content_type', 'codename'),)


class AuthUser(models.Model):
    password = models.CharField(max_length=128)
    last_login = models.DateTimeField(blank=True, null=True)
    is_superuser = models.IntegerField()
    username = models.CharField(unique=True, max_length=150)
    first_name = models.CharField(max_length=30)
    last_name = models.CharField(max_length=30)
    email = models.CharField(max_length=254)
    is_staff = models.IntegerField()
    is_active = models.IntegerField()
    date_joined = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'auth_user'


class AuthUserGroups(models.Model):
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)
    group = models.ForeignKey(AuthGroup, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_user_groups'
        unique_together = (('user', 'group'),)


class AuthUserUserPermissions(models.Model):
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)
    permission = models.ForeignKey(AuthPermission, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'auth_user_user_permissions'
        unique_together = (('user', 'permission'),)


class CmsAsset(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    type = models.CharField(max_length=6)
    asset_format = models.ForeignKey('CmsAssetFormat', models.DO_NOTHING)
    media = models.ForeignKey('CmsMedia', models.DO_NOTHING, blank=True, null=True)
    upload = models.ForeignKey('Uploads', models.DO_NOTHING, blank=True, null=True)
    share = models.ForeignKey('Shares', models.DO_NOTHING, blank=True, null=True)
    name = models.CharField(max_length=255)
    url = models.CharField(max_length=255)
    signature = models.CharField(max_length=512, blank=True, null=True)
    width = models.SmallIntegerField(blank=True, null=True)
    height = models.SmallIntegerField(blank=True, null=True)
    is_preview = models.IntegerField()
    is_active = models.IntegerField()
    meta = models.TextField(blank=True, null=True)
    created = models.DateTimeField()
    last_modified = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'cms_asset'


class CmsAssetFormat(models.Model):
    name = models.CharField(max_length=64)
    label = models.CharField(unique=True, max_length=16)
    description = models.CharField(max_length=128)
    mime_type = models.CharField(max_length=64)
    file_extension = models.CharField(unique=True, max_length=16, blank=True, null=True)
    zencoder_params = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'cms_asset_format'


class CmsMedia(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    type = models.CharField(max_length=7)
    user = models.ForeignKey('Users', models.DO_NOTHING)
    name = models.CharField(max_length=256)
    title = models.CharField(max_length=256)
    description = models.CharField(max_length=512, blank=True, null=True)
    status = models.CharField(max_length=10)
    source_video = models.CharField(max_length=256)
    created = models.DateTimeField()
    last_modified = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'cms_media'


class Comments(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    user = models.ForeignKey('Users', models.DO_NOTHING)
    share = models.ForeignKey('Shares', models.DO_NOTHING)
    picture = models.CharField(max_length=500, blank=True, null=True)
    text = models.CharField(max_length=512)
    created = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'comments'


class Contacts(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    user = models.ForeignKey('Users', models.DO_NOTHING, blank=True, null=True, related_name='+')
    owner = models.ForeignKey('Users', models.DO_NOTHING, related_name='+')
    handle = models.CharField(max_length=255)
    hash = models.CharField(max_length=35, blank=True, null=True)
    service = models.CharField(max_length=8)
    screen_name = models.CharField(max_length=75, blank=True, null=True)
    name = models.CharField(max_length=50, blank=True, null=True)
    email = models.CharField(max_length=50, blank=True, null=True)
    phone = models.CharField(max_length=15, blank=True, null=True)
    website = models.CharField(max_length=200, blank=True, null=True)
    image = models.CharField(max_length=255, blank=True, null=True)
    gender = models.CharField(max_length=6, blank=True, null=True)
    org_name = models.CharField(max_length=75, blank=True, null=True)
    org_title = models.CharField(max_length=75, blank=True, null=True)
    location = models.CharField(max_length=200, blank=True, null=True)
    timezone = models.CharField(max_length=75, blank=True, null=True)
    language = models.CharField(max_length=10, blank=True, null=True)
    optedin = models.IntegerField()
    created = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'contacts'
        unique_together = (('owner', 'handle', 'service'),)


class DjangoAdminLog(models.Model):
    action_time = models.DateTimeField()
    object_id = models.TextField(blank=True, null=True)
    object_repr = models.CharField(max_length=200)
    action_flag = models.SmallIntegerField()
    change_message = models.TextField()
    content_type = models.ForeignKey('DjangoContentType', models.DO_NOTHING, blank=True, null=True)
    user = models.ForeignKey(AuthUser, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'django_admin_log'


class DjangoContentType(models.Model):
    app_label = models.CharField(max_length=100)
    model = models.CharField(max_length=100)

    class Meta:
        managed = False
        db_table = 'django_content_type'
        unique_together = (('app_label', 'model'),)


class DjangoMigrations(models.Model):
    app = models.CharField(max_length=255)
    name = models.CharField(max_length=255)
    applied = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'django_migrations'


class DjangoSession(models.Model):
    session_key = models.CharField(primary_key=True, max_length=40)
    session_data = models.TextField()
    expire_date = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'django_session'


class Drone(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    created = models.DateTimeField()
    location = models.TextField(blank=True, null=True)  # This field type is a guess.
    in_flight = models.IntegerField(blank=True, null=True)
    vehicle_id = models.CharField(max_length=100, blank=True, null=True)
    access_token = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'drone'


class Events(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    user = models.ForeignKey('Users', models.DO_NOTHING)
    kliq = models.ForeignKey('Kliqs', models.DO_NOTHING)
    title = models.CharField(max_length=64)
    image = models.CharField(max_length=150, blank=True, null=True)
    when_occurs = models.DateTimeField()
    location = models.CharField(max_length=64, blank=True, null=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    event_status = models.CharField(max_length=20)
    rtmp_url = models.CharField(max_length=150, blank=True, null=True)
    created = models.DateTimeField()
    drone_enabled = models.IntegerField()

    class Meta:
        managed = False
        db_table = 'events'


class KliqContactMap(models.Model):
    kliq = models.ForeignKey('Kliqs', models.DO_NOTHING, primary_key=True)
    contact = models.ForeignKey(Contacts, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'kliq_contact_map'
        unique_together = (('kliq', 'contact'),)


class Kliqs(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    user = models.ForeignKey('Users', models.DO_NOTHING)
    name = models.CharField(max_length=100)
    image = models.CharField(max_length=150, blank=True, null=True)
    is_emergency = models.IntegerField()
    safeword = models.CharField(max_length=255, blank=True, null=True)
    verification_pin = models.IntegerField()
    created = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'kliqs'


class Lead(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    handle = models.CharField(max_length=36)
    service = models.CharField(max_length=8)
    ambassador_id = models.CharField(max_length=36, blank=True, null=True)
    created = models.DateTimeField()
    persona = models.ForeignKey('Personas', models.DO_NOTHING, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'lead'
        unique_together = (('handle', 'service'),)


class Mission(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    created = models.DateTimeField()
    from_location = models.TextField(blank=True, null=True)  # This field type is a guess.
    to_location = models.TextField(blank=True, null=True)  # This field type is a guess.
    event = models.ForeignKey(Events, models.DO_NOTHING, blank=True, null=True)
    drone = models.ForeignKey(Drone, models.DO_NOTHING, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'mission'


class OauthTokens(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    user = models.ForeignKey('Users', models.DO_NOTHING)
    persona_id = models.CharField(max_length=36, blank=True, null=True)
    token = models.CharField(max_length=4096)
    secret = models.CharField(max_length=4096, blank=True, null=True)
    service = models.CharField(max_length=8)
    created = models.DateTimeField()
    expires = models.CharField(max_length=64, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'oauth_tokens'


class Pair(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    title = models.CharField(max_length=255, blank=True, null=True)
    parent_device_id = models.CharField(max_length=36, blank=True, null=True)
    child_device_id = models.CharField(max_length=36, blank=True, null=True)
    parent_user = models.ForeignKey('Users', models.DO_NOTHING, blank=True, null=True, related_name='+')
    child_user = models.ForeignKey('Users', models.DO_NOTHING, blank=True, null=True, related_name='+')
    kliq = models.ForeignKey(Kliqs, models.DO_NOTHING, blank=True, null=True)
    code = models.CharField(max_length=8, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'pair'


class Passphrases(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    passphrase = models.CharField(unique=True, max_length=255)
    created = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'passphrases'


class Payments(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    user = models.ForeignKey('Users', models.DO_NOTHING)
    payment_type = models.CharField(max_length=255)
    payment_promo = models.CharField(max_length=30, blank=True, null=True)
    cost = models.DecimalField(max_digits=9, decimal_places=2)
    status = models.CharField(max_length=30)
    transaction_id = models.CharField(max_length=100, blank=True, null=True)
    created = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'payments'


class Personas(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    user = models.ForeignKey('Users', models.DO_NOTHING, blank=True, null=True, related_name='+')
    ambassador = models.ForeignKey('Users', models.DO_NOTHING, blank=True, null=True, related_name='+')
    handle = models.CharField(max_length=255)
    service = models.CharField(max_length=8)
    screen_name = models.CharField(max_length=75, blank=True, null=True)
    name = models.CharField(max_length=50, blank=True, null=True)
    email = models.CharField(max_length=50, blank=True, null=True)
    profile_url = models.CharField(max_length=200, blank=True, null=True)
    website = models.CharField(max_length=200, blank=True, null=True)
    image = models.CharField(max_length=255, blank=True, null=True)
    gender = models.CharField(max_length=6, blank=True, null=True)
    location = models.CharField(max_length=200, blank=True, null=True)
    timezone = models.CharField(max_length=75, blank=True, null=True)
    language = models.CharField(max_length=10, blank=True, null=True)
    created = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'personas'


class ShareContactMap(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    share = models.ForeignKey('Shares', models.DO_NOTHING)
    contact = models.ForeignKey(Contacts, models.DO_NOTHING)
    hash = models.CharField(max_length=100, blank=True, null=True)
    link = models.CharField(max_length=200, blank=True, null=True)
    method = models.CharField(max_length=8)
    service = models.CharField(max_length=8)
    delivered = models.IntegerField()
    created = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'share_contact_map'


class ShareKliqMap(models.Model):
    share = models.ForeignKey('Shares', models.DO_NOTHING, primary_key=True)
    kliq = models.ForeignKey(Kliqs, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'share_kliq_map'
        unique_together = (('share', 'kliq'),)


class Shares(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    user = models.ForeignKey('Users', models.DO_NOTHING)
    media = models.ForeignKey(CmsMedia, models.DO_NOTHING, blank=True, null=True)
    upload = models.ForeignKey('Uploads', models.DO_NOTHING, blank=True, null=True)
    title = models.CharField(max_length=64, blank=True, null=True)
    message = models.CharField(max_length=1024, blank=True, null=True)
    geo_location = models.CharField(max_length=256, blank=True, null=True)
    offset = models.IntegerField()
    allow_reshare = models.IntegerField()
    allow_location_share = models.IntegerField()
    status = models.CharField(max_length=10)
    created = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'shares'


class Uploads(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    user = models.ForeignKey('Users', models.DO_NOTHING)
    title = models.CharField(max_length=64, blank=True, null=True)
    suffix = models.CharField(max_length=6)
    mime_type = models.CharField(max_length=64)
    path = models.CharField(max_length=500)
    status = models.CharField(max_length=10)
    created = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'uploads'


class Users(models.Model):
    id = models.CharField(primary_key=True, max_length=36)
    username = models.CharField(unique=True, max_length=32)
    password = models.TextField()
    email = models.CharField(max_length=128)
    active = models.IntegerField()
    first_name = models.CharField(max_length=32)
    last_name = models.CharField(max_length=32)
    gender = models.CharField(max_length=6, blank=True, null=True)
    profile_photo = models.TextField(blank=True, null=True)
    picture = models.CharField(max_length=500, blank=True, null=True)
    geo_location = models.CharField(max_length=255, blank=True, null=True)
    email_verified = models.IntegerField(blank=True, null=True)
    paid = models.IntegerField()
    paid_before = models.DateTimeField()
    swrve_user_id = models.CharField(max_length=255, blank=True, null=True)
    lang = models.CharField(max_length=255, blank=True, null=True)
    merged_chat_user_id = models.CharField(max_length=255, blank=True, null=True)
    aireos_user_id = models.CharField(max_length=255, blank=True, null=True)
    aireos_credit = models.IntegerField(blank=True, null=True)
    drone_enabled = models.IntegerField(blank=True, null=True)
    created = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'users'


class ZencoderOutputs(models.Model):
    user = models.ForeignKey(Users, models.DO_NOTHING)
    media = models.ForeignKey(CmsMedia, models.DO_NOTHING, blank=True, null=True)
    upload = models.ForeignKey(Uploads, models.DO_NOTHING, blank=True, null=True)
    share = models.ForeignKey(Shares, models.DO_NOTHING, blank=True, null=True)
    asset_format = models.ForeignKey(CmsAssetFormat, models.DO_NOTHING)
    zc_job_id = models.IntegerField()
    zc_output_id = models.IntegerField()
    state = models.CharField(max_length=11)
    created = models.DateTimeField()
    last_modified = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'zencoder_outputs'
