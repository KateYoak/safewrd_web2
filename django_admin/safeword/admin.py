# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.contrib import admin
from django.utils.safestring import mark_safe

# Register your models here.
from .models import (
    Ambassadors,
    AuthGroup,
    AuthGroupPermissions,
    AuthPermission,
    AuthUser,
    AuthUserGroups,
    AuthUserUserPermissions,
    CmsAsset,
    CmsAssetFormat,
    CmsMedia,
    Comments,
    Contacts,
    DjangoAdminLog,
    DjangoContentType,
    DjangoMigrations,
    DjangoSession,
    Drone,
    Events,
    Kliqs,
    Lead,
    Mission,
    OauthTokens,
    Pair,
    Passphrases,
    Payments,
    Personas,
    ShareContactMap,
    Shares,
    Uploads,
    Users,
    ZencoderOutputs,
    KliqContactMap,
    ShareKliqMap
)

m = (
#    Ambassadors,
    AuthGroup,
    AuthGroupPermissions,
    AuthPermission,
    AuthUser,
    AuthUserGroups,
    AuthUserUserPermissions,
    CmsAsset,
    CmsAssetFormat,
    CmsMedia,
    Comments,
    Contacts,
    DjangoAdminLog,
    DjangoContentType,
    DjangoMigrations,
    DjangoSession,
    Drone,
    Events,
    Kliqs,
    Lead,
    Mission,
    OauthTokens,
    Pair,
    Passphrases,
    Payments,
    Personas,
    ShareContactMap,
    Shares,
    Uploads,
    Users,
    ZencoderOutputs,
    KliqContactMap,
    ShareKliqMap
)

for model in m:
    admin.site.register(model)


@admin.register(Ambassadors)
class AmbassadorsAdmin(admin.ModelAdmin):
    list_display = ('firstname', 'lastname', '_photo')
    list_filter = ('status',)
    search_fields = ('firstname',)
    readonly_fields = ('_photo',)

    def _photo(self, obj):
        return mark_safe('<img src="http://159.203.169.170{}" style="max-height:50px" />'.format(obj.photo))


