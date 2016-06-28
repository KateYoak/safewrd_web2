-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Thu Jun  9 19:39:50 2016
-- 
;
SET foreign_key_checks=0;
--
-- Table: `cms_asset_format`
--
CREATE TABLE `cms_asset_format` (
  `id` integer unsigned NOT NULL auto_increment,
  `name` varchar(64) NOT NULL,
  `label` varchar(16) NOT NULL,
  `description` varchar(128) NOT NULL,
  `mime_type` varchar(64) NOT NULL,
  `file_extension` varchar(16) NULL,
  `zencoder_params` text NULL,
  INDEX `idx_label` (`label`),
  PRIMARY KEY (`id`),
  UNIQUE `file_extension` (`file_extension`),
  UNIQUE `label` (`label`)
) ENGINE=InnoDB;
--
-- Table: `users`
--
CREATE TABLE `users` (
  `id` CHAR(36) NOT NULL,
  `username` varchar(32) NOT NULL,
  `password` text NOT NULL,
  `email` varchar(128) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 0,
  `first_name` varchar(32) NOT NULL DEFAULT '',
  `last_name` varchar(32) NOT NULL DEFAULT '',
  `gender` enum('male', 'female') NULL,
  `profile_photo` blob NULL,
  `picture` text NULL,
  `geo_location` varchar(255) NULL,
  `email_verified` tinyint(1) NULL DEFAULT 0,
  `created` timestamp NOT NULL DEFAULT current_timestamp,
  PRIMARY KEY (`id`),
  UNIQUE `username` (`username`)
) ENGINE=InnoDB;
--
-- Table: `cms_media`
--
CREATE TABLE `cms_media` (
  `id` CHAR(36) NOT NULL,
  `type` enum('movie', 'episode') NOT NULL DEFAULT 'movie',
  `user_id` CHAR(36) NOT NULL,
  `name` text NOT NULL,
  `title` text NOT NULL,
  `description` text NULL,
  `status` enum('new', 'processing', 'error', 'ready', 'published') NOT NULL DEFAULT 'new',
  `source_video` text NOT NULL,
  `created` datetime NOT NULL,
  `last_modified` datetime NOT NULL,
  INDEX `cms_media_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `cms_media_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `contacts`
--
CREATE TABLE `contacts` (
  `id` CHAR(36) NOT NULL,
  `user_id` CHAR(36) NULL,
  `owner_id` CHAR(36) NOT NULL,
  `handle` text NOT NULL,
  `hash` varchar(35) NULL,
  `service` enum('google', 'twitter', 'facebook', 'yahoo', 'linkedin', 'manual') NOT NULL,
  `screen_name` varchar(75) NULL,
  `name` varchar(50) NULL,
  `email` varchar(50) NULL,
  `phone` varchar(15) NULL,
  `website` varchar(200) NULL,
  `image` varchar(255) NULL,
  `gender` enum('male', 'female') NULL,
  `org_name` varchar(75) NULL,
  `org_title` varchar(75) NULL,
  `location` varchar(200) NULL,
  `timezone` varchar(75) NULL,
  `language` varchar(10) NULL,
  `optedin` tinyint(1) NOT NULL DEFAULT 0,
  `created` timestamp NOT NULL DEFAULT current_timestamp,
  INDEX `contacts_idx_owner_id` (`owner_id`),
  INDEX `contacts_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  UNIQUE `owner_service_contact` (`owner_id`, `handle`, `service`),
  CONSTRAINT `contacts_fk_owner_id` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `contacts_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB;
--
-- Table: `kliqs`
--
CREATE TABLE `kliqs` (
  `id` CHAR(36) NOT NULL,
  `user_id` CHAR(36) NOT NULL,
  `name` varchar(100) NOT NULL,
  `image` varchar(150) NULL,
  `is_emergency` tinyint(1) NOT NULL DEFAULT 0,
  `created` timestamp NOT NULL DEFAULT current_timestamp,
  INDEX `kliqs_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `kliqs_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `oauth_tokens`
--
CREATE TABLE `oauth_tokens` (
  `id` CHAR(36) NOT NULL,
  `user_id` CHAR(36) NOT NULL,
  `persona_id` CHAR(36) NULL,
  `token` text NOT NULL,
  `secret` text NULL,
  `service` enum('google', 'twitter', 'facebook', 'yahoo', 'linkedin') NOT NULL,
  `created` timestamp NOT NULL DEFAULT current_timestamp,
  `expires` VARCHAR(64) NULL,
  INDEX `oauth_tokens_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `oauth_tokens_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `personas`
--
CREATE TABLE `personas` (
  `id` CHAR(36) NOT NULL,
  `user_id` CHAR(36) NULL,
  `handle` text NOT NULL,
  `service` enum('google', 'twitter', 'facebook', 'yahoo', 'linkedin', 'kliq', 'manual') NOT NULL,
  `screen_name` varchar(75) NULL,
  `name` varchar(50) NULL,
  `email` varchar(50) NULL,
  `profile_url` varchar(200) NULL,
  `website` varchar(200) NULL,
  `image` varchar(255) NULL,
  `gender` enum('male', 'female') NULL,
  `location` varchar(200) NULL,
  `timezone` varchar(75) NULL,
  `language` varchar(10) NULL,
  `created` timestamp NOT NULL DEFAULT current_timestamp,
  INDEX `personas_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `personas_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `uploads`
--
CREATE TABLE `uploads` (
  `id` CHAR(36) NOT NULL,
  `user_id` CHAR(36) NOT NULL,
  `title` varchar(64) NULL,
  `suffix` varchar(6) NOT NULL,
  `mime_type` varchar(64) NOT NULL,
  `path` text NOT NULL,
  `status` enum('new', 'processing', 'error', 'ready', 'published') NOT NULL DEFAULT 'new',
  `created` datetime NOT NULL,
  INDEX `uploads_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `uploads_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `events`
--
CREATE TABLE `events` (
  `id` CHAR(36) NOT NULL,
  `user_id` CHAR(36) NOT NULL,
  `kliq_id` CHAR(36) NOT NULL,
  `title` varchar(64) NOT NULL,
  `image` varchar(150) NULL,
  `when_occurs` datetime NOT NULL,
  `location` varchar(64) NULL,
  `price` decimal(10, 2) NOT NULL,
  `event_status` varchar(20) NOT NULL DEFAULT 'new',
  `created` timestamp NOT NULL DEFAULT current_timestamp,
  INDEX `events_idx_kliq_id` (`kliq_id`),
  INDEX `events_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `events_fk_kliq_id` FOREIGN KEY (`kliq_id`) REFERENCES `kliqs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `events_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `pair`
--
CREATE TABLE `pair` (
  `id` CHAR(36) NOT NULL,
  `title` VARCHAR(255) NULL,
  `parent_device_id` VARCHAR(36) NULL,
  `child_device_id` VARCHAR(36) NULL,
  `parent_user_id` CHAR(36) NULL,
  `child_user_id` CHAR(36) NULL,
  `kliq_id` CHAR(36) NULL,
  `code` CHAR(8) NULL,
  INDEX `pair_idx_child_user_id` (`child_user_id`),
  INDEX `pair_idx_kliq_id` (`kliq_id`),
  INDEX `pair_idx_parent_user_id` (`parent_user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `pair_fk_child_user_id` FOREIGN KEY (`child_user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `pair_fk_kliq_id` FOREIGN KEY (`kliq_id`) REFERENCES `kliqs` (`id`),
  CONSTRAINT `pair_fk_parent_user_id` FOREIGN KEY (`parent_user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB;
--
-- Table: `kliq_contact_map`
--
CREATE TABLE `kliq_contact_map` (
  `kliq_id` CHAR(36) NOT NULL,
  `contact_id` CHAR(36) NOT NULL,
  INDEX `kliq_contact_map_idx_contact_id` (`contact_id`),
  INDEX `kliq_contact_map_idx_kliq_id` (`kliq_id`),
  PRIMARY KEY (`kliq_id`, `contact_id`),
  CONSTRAINT `kliq_contact_map_fk_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `contacts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `kliq_contact_map_fk_kliq_id` FOREIGN KEY (`kliq_id`) REFERENCES `kliqs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `shares`
--
CREATE TABLE `shares` (
  `id` CHAR(36) NOT NULL,
  `user_id` CHAR(36) NOT NULL,
  `media_id` CHAR(36) NULL,
  `upload_id` CHAR(36) NULL,
  `title` varchar(64) NULL,
  `message` text NULL,
  `geo_location` text NULL,
  `offset` mediumint unsigned NOT NULL DEFAULT 0,
  `allow_reshare` tinyint(1) NOT NULL DEFAULT 0,
  `allow_location_share` tinyint(1) NOT NULL DEFAULT 0,
  `status` enum('new', 'processing', 'error', 'ready', 'published') NOT NULL DEFAULT 'new',
  `created` timestamp NOT NULL DEFAULT current_timestamp,
  INDEX `shares_idx_media_id` (`media_id`),
  INDEX `shares_idx_upload_id` (`upload_id`),
  INDEX `shares_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `shares_fk_media_id` FOREIGN KEY (`media_id`) REFERENCES `cms_media` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `shares_fk_upload_id` FOREIGN KEY (`upload_id`) REFERENCES `uploads` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `shares_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `comments`
--
CREATE TABLE `comments` (
  `id` CHAR(36) NOT NULL,
  `user_id` CHAR(36) NOT NULL,
  `share_id` CHAR(36) NOT NULL,
  `picture` text NULL,
  `text` text NOT NULL,
  `created` timestamp NOT NULL DEFAULT current_timestamp,
  INDEX `comments_idx_share_id` (`share_id`),
  INDEX `comments_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `comments_fk_share_id` FOREIGN KEY (`share_id`) REFERENCES `shares` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `comments_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `cms_asset`
--
CREATE TABLE `cms_asset` (
  `id` CHAR(36) NOT NULL,
  `type` enum('clip', 'video', 'cover', 'banner', 'other') NOT NULL DEFAULT 'video',
  `asset_format_id` integer unsigned NOT NULL,
  `media_id` CHAR(36) NULL,
  `upload_id` CHAR(36) NULL,
  `share_id` CHAR(36) NULL,
  `name` varchar(255) NOT NULL,
  `url` varchar(255) NOT NULL,
  `signature` text NULL,
  `width` smallint unsigned NULL DEFAULT 0,
  `height` smallint unsigned NULL DEFAULT 0,
  `is_preview` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `is_active` tinyint(1) unsigned NOT NULL DEFAULT 1,
  `meta` text NULL,
  `created` datetime NOT NULL,
  `last_modified` datetime NOT NULL,
  INDEX `cms_asset_idx_asset_format_id` (`asset_format_id`),
  INDEX `cms_asset_idx_share_id` (`share_id`),
  INDEX `cms_asset_idx_media_id` (`media_id`),
  INDEX `cms_asset_idx_upload_id` (`upload_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `cms_asset_fk_asset_format_id` FOREIGN KEY (`asset_format_id`) REFERENCES `cms_asset_format` (`id`),
  CONSTRAINT `cms_asset_fk_share_id` FOREIGN KEY (`share_id`) REFERENCES `shares` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `cms_asset_fk_media_id` FOREIGN KEY (`media_id`) REFERENCES `cms_media` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `cms_asset_fk_upload_id` FOREIGN KEY (`upload_id`) REFERENCES `uploads` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `share_contact_map`
--
CREATE TABLE `share_contact_map` (
  `id` CHAR(36) NOT NULL,
  `share_id` CHAR(36) NOT NULL,
  `contact_id` CHAR(36) NOT NULL,
  `hash` varchar(100) NULL,
  `link` varchar(200) NULL,
  `method` enum('twitter', 'facebook', 'im', 'email') NOT NULL,
  `service` enum('google', 'twitter', 'facebook', 'yahoo') NOT NULL,
  `delivered` tinyint(1) NOT NULL DEFAULT 0,
  `created` timestamp NOT NULL DEFAULT current_timestamp,
  INDEX `share_contact_map_idx_contact_id` (`contact_id`),
  INDEX `share_contact_map_idx_share_id` (`share_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `share_contact_map_fk_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `contacts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `share_contact_map_fk_share_id` FOREIGN KEY (`share_id`) REFERENCES `shares` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `share_kliq_map`
--
CREATE TABLE `share_kliq_map` (
  `share_id` CHAR(36) NOT NULL,
  `kliq_id` CHAR(36) NOT NULL,
  INDEX `share_kliq_map_idx_kliq_id` (`kliq_id`),
  INDEX `share_kliq_map_idx_share_id` (`share_id`),
  PRIMARY KEY (`share_id`, `kliq_id`),
  CONSTRAINT `share_kliq_map_fk_kliq_id` FOREIGN KEY (`kliq_id`) REFERENCES `kliqs` (`id`),
  CONSTRAINT `share_kliq_map_fk_share_id` FOREIGN KEY (`share_id`) REFERENCES `shares` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `zencoder_outputs`
--
CREATE TABLE `zencoder_outputs` (
  `id` integer unsigned NOT NULL auto_increment,
  `user_id` CHAR(36) NOT NULL,
  `media_id` CHAR(36) NULL,
  `upload_id` CHAR(36) NULL,
  `share_id` CHAR(36) NULL,
  `asset_format_id` integer unsigned NOT NULL,
  `zc_job_id` integer unsigned NOT NULL,
  `zc_output_id` integer unsigned NOT NULL,
  `state` enum('pending', 'submitting', 'transcoding', 'finished', 'failed') NOT NULL DEFAULT 'pending',
  `created` datetime NOT NULL,
  `last_modified` datetime NOT NULL,
  INDEX `zencoder_outputs_idx_asset_format_id` (`asset_format_id`),
  INDEX `zencoder_outputs_idx_share_id` (`share_id`),
  INDEX `zencoder_outputs_idx_media_id` (`media_id`),
  INDEX `zencoder_outputs_idx_upload_id` (`upload_id`),
  INDEX `zencoder_outputs_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `zencoder_outputs_fk_asset_format_id` FOREIGN KEY (`asset_format_id`) REFERENCES `cms_asset_format` (`id`),
  CONSTRAINT `zencoder_outputs_fk_share_id` FOREIGN KEY (`share_id`) REFERENCES `shares` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `zencoder_outputs_fk_media_id` FOREIGN KEY (`media_id`) REFERENCES `cms_media` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `zencoder_outputs_fk_upload_id` FOREIGN KEY (`upload_id`) REFERENCES `uploads` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `zencoder_outputs_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
SET foreign_key_checks=1;
