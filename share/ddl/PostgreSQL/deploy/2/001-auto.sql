-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Thu May 26 19:19:48 2016
-- 
;
--
-- Table: cms_asset_format
--
CREATE TABLE "cms_asset_format" (
  "id" serial NOT NULL,
  "name" character varying(64) NOT NULL,
  "label" character varying(16) NOT NULL,
  "description" character varying(128) NOT NULL,
  "mime_type" character varying(64) NOT NULL,
  "file_extension" character varying(16),
  "zencoder_params" text,
  PRIMARY KEY ("id"),
  CONSTRAINT "file_extension" UNIQUE ("file_extension"),
  CONSTRAINT "label" UNIQUE ("label")
);
CREATE INDEX "idx_label" on "cms_asset_format" ("label");

;
--
-- Table: users
--
CREATE TABLE "users" (
  "id" character(36) NOT NULL,
  "username" character varying(32) NOT NULL,
  "password" text NOT NULL,
  "email" character varying(128) NOT NULL,
  "active" smallint DEFAULT 0 NOT NULL,
  "first_name" character varying(32) DEFAULT '' NOT NULL,
  "last_name" character varying(32) DEFAULT '' NOT NULL,
  "gender" character varying,
  "profile_photo" bytea,
  "picture" character varying(500),
  "geo_location" character varying(255),
  "email_verified" smallint DEFAULT 0,
  "created" timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "username" UNIQUE ("username")
);

;
--
-- Table: cms_media
--
CREATE TABLE "cms_media" (
  "id" character(36) NOT NULL,
  "type" character varying DEFAULT 'movie' NOT NULL,
  "user_id" character(36) NOT NULL,
  "name" character varying(256) NOT NULL,
  "title" character varying(256) NOT NULL,
  "description" character varying(512),
  "status" character varying DEFAULT 'new' NOT NULL,
  "source_video" character varying(256) NOT NULL,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "cms_media_idx_user_id" on "cms_media" ("user_id");

;
--
-- Table: contacts
--
CREATE TABLE "contacts" (
  "id" character(36) NOT NULL,
  "user_id" character(36),
  "owner_id" character(36) NOT NULL,
  "handle" character varying(300) NOT NULL,
  "hash" character varying(35),
  "service" character varying NOT NULL,
  "screen_name" character varying(75),
  "name" character varying(50),
  "email" character varying(50),
  "phone" character varying(15),
  "website" character varying(200),
  "image" character varying(255),
  "gender" character varying,
  "org_name" character varying(75),
  "org_title" character varying(75),
  "location" character varying(200),
  "timezone" character varying(75),
  "language" character varying(10),
  "optedin" smallint DEFAULT 0 NOT NULL,
  "created" timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "owner_service_contact" UNIQUE ("owner_id", "handle", "service")
);
CREATE INDEX "contacts_idx_owner_id" on "contacts" ("owner_id");
CREATE INDEX "contacts_idx_user_id" on "contacts" ("user_id");

;
--
-- Table: kliqs
--
CREATE TABLE "kliqs" (
  "id" character(36) NOT NULL,
  "user_id" character(36) NOT NULL,
  "name" character varying(100) NOT NULL,
  "image" character varying(150),
  "is_emergency" smallint DEFAULT 0 NOT NULL,
  "created" timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "kliqs_idx_user_id" on "kliqs" ("user_id");

;
--
-- Table: oauth_tokens
--
CREATE TABLE "oauth_tokens" (
  "id" character(36) NOT NULL,
  "user_id" character(36) NOT NULL,
  "persona_id" character(36),
  "token" character varying(4096) NOT NULL,
  "secret" character varying(4096),
  "service" character varying NOT NULL,
  "created" timestamp DEFAULT current_timestamp NOT NULL,
  "expires" character varying(64),
  PRIMARY KEY ("id")
);
CREATE INDEX "oauth_tokens_idx_user_id" on "oauth_tokens" ("user_id");

;
--
-- Table: personas
--
CREATE TABLE "personas" (
  "id" character(36) NOT NULL,
  "user_id" character(36),
  "handle" character varying(300) NOT NULL,
  "service" character varying NOT NULL,
  "screen_name" character varying(75),
  "name" character varying(50),
  "email" character varying(50),
  "profile_url" character varying(200),
  "website" character varying(200),
  "image" character varying(255),
  "gender" character varying,
  "location" character varying(200),
  "timezone" character varying(75),
  "language" character varying(10),
  "created" timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "personas_idx_user_id" on "personas" ("user_id");

;
--
-- Table: uploads
--
CREATE TABLE "uploads" (
  "id" character(36) NOT NULL,
  "user_id" character(36) NOT NULL,
  "title" character varying(64),
  "suffix" character varying(6) NOT NULL,
  "mime_type" character varying(64) NOT NULL,
  "path" character varying(500) NOT NULL,
  "status" character varying DEFAULT 'new' NOT NULL,
  "created" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "uploads_idx_user_id" on "uploads" ("user_id");

;
--
-- Table: events
--
CREATE TABLE "events" (
  "id" character(36) NOT NULL,
  "user_id" character(36) NOT NULL,
  "kliq_id" character(36) NOT NULL,
  "title" character varying(64) NOT NULL,
  "image" character varying(150),
  "when_occurs" timestamp NOT NULL,
  "location" character varying(64),
  "price" numeric(10,2) NOT NULL,
  "event_status" character varying(20) DEFAULT 'new' NOT NULL,
  "created" timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "events_idx_kliq_id" on "events" ("kliq_id");
CREATE INDEX "events_idx_user_id" on "events" ("user_id");

;
--
-- Table: pair
--
CREATE TABLE "pair" (
  "id" character(36) NOT NULL,
  "title" character varying(255),
  "parent_device_id" character varying(36),
  "child_device_id" character varying(36),
  "parent_user_id" character(36),
  "child_user_id" character(36),
  "kliq_id" character(36),
  "code" character(8),
  PRIMARY KEY ("id")
);
CREATE INDEX "pair_idx_child_user_id" on "pair" ("child_user_id");
CREATE INDEX "pair_idx_kliq_id" on "pair" ("kliq_id");
CREATE INDEX "pair_idx_parent_user_id" on "pair" ("parent_user_id");

;
--
-- Table: kliq_contact_map
--
CREATE TABLE "kliq_contact_map" (
  "kliq_id" character(36) NOT NULL,
  "contact_id" character(36) NOT NULL,
  PRIMARY KEY ("kliq_id", "contact_id")
);
CREATE INDEX "kliq_contact_map_idx_contact_id" on "kliq_contact_map" ("contact_id");
CREATE INDEX "kliq_contact_map_idx_kliq_id" on "kliq_contact_map" ("kliq_id");

;
--
-- Table: shares
--
CREATE TABLE "shares" (
  "id" character(36) NOT NULL,
  "user_id" character(36) NOT NULL,
  "media_id" character(36),
  "upload_id" character(36),
  "title" character varying(64),
  "message" character varying(1024),
  "geo_location" character varying(256),
  "offset" integer DEFAULT 0 NOT NULL,
  "allow_reshare" smallint DEFAULT 0 NOT NULL,
  "allow_location_share" smallint DEFAULT 0 NOT NULL,
  "status" character varying DEFAULT 'new' NOT NULL,
  "created" timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "shares_idx_media_id" on "shares" ("media_id");
CREATE INDEX "shares_idx_upload_id" on "shares" ("upload_id");
CREATE INDEX "shares_idx_user_id" on "shares" ("user_id");

;
--
-- Table: comments
--
CREATE TABLE "comments" (
  "id" character(36) NOT NULL,
  "user_id" character(36) NOT NULL,
  "share_id" character(36) NOT NULL,
  "picture" character varying(500),
  "text" character varying(512) NOT NULL,
  "created" timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "comments_idx_share_id" on "comments" ("share_id");
CREATE INDEX "comments_idx_user_id" on "comments" ("user_id");

;
--
-- Table: cms_asset
--
CREATE TABLE "cms_asset" (
  "id" character(36) NOT NULL,
  "type" character varying DEFAULT 'video' NOT NULL,
  "asset_format_id" integer NOT NULL,
  "media_id" character(36),
  "upload_id" character(36),
  "share_id" character(36),
  "name" character varying(255) NOT NULL,
  "url" character varying(255) NOT NULL,
  "signature" character varying(512),
  "width" smallint DEFAULT 0,
  "height" smallint DEFAULT 0,
  "is_preview" smallint DEFAULT 0 NOT NULL,
  "is_active" smallint DEFAULT 1 NOT NULL,
  "meta" text,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "cms_asset_idx_asset_format_id" on "cms_asset" ("asset_format_id");
CREATE INDEX "cms_asset_idx_share_id" on "cms_asset" ("share_id");
CREATE INDEX "cms_asset_idx_media_id" on "cms_asset" ("media_id");
CREATE INDEX "cms_asset_idx_upload_id" on "cms_asset" ("upload_id");

;
--
-- Table: share_contact_map
--
CREATE TABLE "share_contact_map" (
  "id" character(36) NOT NULL,
  "share_id" character(36) NOT NULL,
  "contact_id" character(36) NOT NULL,
  "hash" character varying(100),
  "link" character varying(200),
  "method" character varying NOT NULL,
  "service" character varying NOT NULL,
  "delivered" smallint DEFAULT 0 NOT NULL,
  "created" timestamp DEFAULT current_timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "share_contact_map_idx_contact_id" on "share_contact_map" ("contact_id");
CREATE INDEX "share_contact_map_idx_share_id" on "share_contact_map" ("share_id");

;
--
-- Table: share_kliq_map
--
CREATE TABLE "share_kliq_map" (
  "share_id" character(36) NOT NULL,
  "kliq_id" character(36) NOT NULL,
  PRIMARY KEY ("share_id", "kliq_id")
);
CREATE INDEX "share_kliq_map_idx_kliq_id" on "share_kliq_map" ("kliq_id");
CREATE INDEX "share_kliq_map_idx_share_id" on "share_kliq_map" ("share_id");

;
--
-- Table: zencoder_outputs
--
CREATE TABLE "zencoder_outputs" (
  "id" serial NOT NULL,
  "user_id" character(36) NOT NULL,
  "media_id" character(36),
  "upload_id" character(36),
  "share_id" character(36),
  "asset_format_id" integer NOT NULL,
  "zc_job_id" integer NOT NULL,
  "zc_output_id" integer NOT NULL,
  "state" character varying DEFAULT 'pending' NOT NULL,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "zencoder_outputs_idx_asset_format_id" on "zencoder_outputs" ("asset_format_id");
CREATE INDEX "zencoder_outputs_idx_share_id" on "zencoder_outputs" ("share_id");
CREATE INDEX "zencoder_outputs_idx_media_id" on "zencoder_outputs" ("media_id");
CREATE INDEX "zencoder_outputs_idx_upload_id" on "zencoder_outputs" ("upload_id");
CREATE INDEX "zencoder_outputs_idx_user_id" on "zencoder_outputs" ("user_id");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "cms_media" ADD CONSTRAINT "cms_media_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "contacts" ADD CONSTRAINT "contacts_fk_owner_id" FOREIGN KEY ("owner_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "contacts" ADD CONSTRAINT "contacts_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") DEFERRABLE;

;
ALTER TABLE "kliqs" ADD CONSTRAINT "kliqs_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "oauth_tokens" ADD CONSTRAINT "oauth_tokens_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "personas" ADD CONSTRAINT "personas_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "uploads" ADD CONSTRAINT "uploads_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "events" ADD CONSTRAINT "events_fk_kliq_id" FOREIGN KEY ("kliq_id")
  REFERENCES "kliqs" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "events" ADD CONSTRAINT "events_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "pair" ADD CONSTRAINT "pair_fk_child_user_id" FOREIGN KEY ("child_user_id")
  REFERENCES "users" ("id") DEFERRABLE;

;
ALTER TABLE "pair" ADD CONSTRAINT "pair_fk_kliq_id" FOREIGN KEY ("kliq_id")
  REFERENCES "kliqs" ("id") DEFERRABLE;

;
ALTER TABLE "pair" ADD CONSTRAINT "pair_fk_parent_user_id" FOREIGN KEY ("parent_user_id")
  REFERENCES "users" ("id") DEFERRABLE;

;
ALTER TABLE "kliq_contact_map" ADD CONSTRAINT "kliq_contact_map_fk_contact_id" FOREIGN KEY ("contact_id")
  REFERENCES "contacts" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "kliq_contact_map" ADD CONSTRAINT "kliq_contact_map_fk_kliq_id" FOREIGN KEY ("kliq_id")
  REFERENCES "kliqs" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "shares" ADD CONSTRAINT "shares_fk_media_id" FOREIGN KEY ("media_id")
  REFERENCES "cms_media" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "shares" ADD CONSTRAINT "shares_fk_upload_id" FOREIGN KEY ("upload_id")
  REFERENCES "uploads" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "shares" ADD CONSTRAINT "shares_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "comments" ADD CONSTRAINT "comments_fk_share_id" FOREIGN KEY ("share_id")
  REFERENCES "shares" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "comments" ADD CONSTRAINT "comments_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "cms_asset" ADD CONSTRAINT "cms_asset_fk_asset_format_id" FOREIGN KEY ("asset_format_id")
  REFERENCES "cms_asset_format" ("id") DEFERRABLE;

;
ALTER TABLE "cms_asset" ADD CONSTRAINT "cms_asset_fk_share_id" FOREIGN KEY ("share_id")
  REFERENCES "shares" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "cms_asset" ADD CONSTRAINT "cms_asset_fk_media_id" FOREIGN KEY ("media_id")
  REFERENCES "cms_media" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "cms_asset" ADD CONSTRAINT "cms_asset_fk_upload_id" FOREIGN KEY ("upload_id")
  REFERENCES "uploads" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "share_contact_map" ADD CONSTRAINT "share_contact_map_fk_contact_id" FOREIGN KEY ("contact_id")
  REFERENCES "contacts" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "share_contact_map" ADD CONSTRAINT "share_contact_map_fk_share_id" FOREIGN KEY ("share_id")
  REFERENCES "shares" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "share_kliq_map" ADD CONSTRAINT "share_kliq_map_fk_kliq_id" FOREIGN KEY ("kliq_id")
  REFERENCES "kliqs" ("id") DEFERRABLE;

;
ALTER TABLE "share_kliq_map" ADD CONSTRAINT "share_kliq_map_fk_share_id" FOREIGN KEY ("share_id")
  REFERENCES "shares" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "zencoder_outputs" ADD CONSTRAINT "zencoder_outputs_fk_asset_format_id" FOREIGN KEY ("asset_format_id")
  REFERENCES "cms_asset_format" ("id") DEFERRABLE;

;
ALTER TABLE "zencoder_outputs" ADD CONSTRAINT "zencoder_outputs_fk_share_id" FOREIGN KEY ("share_id")
  REFERENCES "shares" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "zencoder_outputs" ADD CONSTRAINT "zencoder_outputs_fk_media_id" FOREIGN KEY ("media_id")
  REFERENCES "cms_media" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "zencoder_outputs" ADD CONSTRAINT "zencoder_outputs_fk_upload_id" FOREIGN KEY ("upload_id")
  REFERENCES "uploads" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "zencoder_outputs" ADD CONSTRAINT "zencoder_outputs_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "users" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
