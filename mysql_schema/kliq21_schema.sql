-- MySQL dump 10.13  Distrib 5.5.44, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: kliq21
-- ------------------------------------------------------
-- Server version	5.5.44-0ubuntu0.12.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `kliq21`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `kliq21` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `kliq21`;

--
-- Table structure for table `cms_asset`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cms_asset` (
  `id` char(36) NOT NULL,
  `type` enum('clip','video','cover','banner','other') NOT NULL DEFAULT 'video',
  `asset_format_id` int(10) unsigned NOT NULL,
  `media_id` char(36) DEFAULT NULL,
  `upload_id` char(36) DEFAULT NULL,
  `share_id` char(36) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `url` varchar(255) NOT NULL,
  `signature` varchar(512) DEFAULT NULL,
  `width` smallint(5) unsigned DEFAULT '0',
  `height` smallint(5) unsigned DEFAULT '0',
  `is_preview` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `is_active` tinyint(1) unsigned NOT NULL DEFAULT '1',
  `meta` text,
  `created` datetime NOT NULL,
  `last_modified` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `cms_asset_idx_asset_format_id` (`asset_format_id`),
  KEY `cms_asset_idx_share_id` (`share_id`),
  KEY `cms_asset_idx_media_id` (`media_id`),
  KEY `cms_asset_idx_upload_id` (`upload_id`),
  CONSTRAINT `cms_asset_fk_asset_format_id` FOREIGN KEY (`asset_format_id`) REFERENCES `cms_asset_format` (`id`),
  CONSTRAINT `cms_asset_fk_media_id` FOREIGN KEY (`media_id`) REFERENCES `cms_media` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `cms_asset_fk_share_id` FOREIGN KEY (`share_id`) REFERENCES `shares` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `cms_asset_fk_upload_id` FOREIGN KEY (`upload_id`) REFERENCES `uploads` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cms_asset_format`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cms_asset_format` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `label` varchar(16) NOT NULL,
  `description` varchar(128) NOT NULL,
  `mime_type` varchar(64) NOT NULL,
  `file_extension` varchar(16) DEFAULT NULL,
  `zencoder_params` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `label` (`label`),
  UNIQUE KEY `file_extension` (`file_extension`),
  KEY `idx_label` (`label`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cms_media`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cms_media` (
  `id` char(36) NOT NULL,
  `type` enum('movie','episode') NOT NULL DEFAULT 'movie',
  `user_id` char(36) NOT NULL,
  `name` varchar(256) NOT NULL,
  `title` varchar(256) NOT NULL,
  `description` varchar(512) DEFAULT NULL,
  `status` enum('new','processing','error','ready','published') NOT NULL DEFAULT 'new',
  `source_video` varchar(256) NOT NULL,
  `created` datetime NOT NULL,
  `last_modified` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `cms_media_idx_user_id` (`user_id`),
  CONSTRAINT `cms_media_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comments`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comments` (
  `id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `share_id` char(36) NOT NULL,
  `picture` varchar(500) DEFAULT NULL,
  `text` varchar(512) NOT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `comments_idx_share_id` (`share_id`),
  KEY `comments_idx_user_id` (`user_id`),
  CONSTRAINT `comments_fk_share_id` FOREIGN KEY (`share_id`) REFERENCES `shares` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `comments_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `contacts`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contacts` (
  `id` char(36) NOT NULL,
  `user_id` char(36) DEFAULT NULL,
  `owner_id` char(36) NOT NULL,
  `handle` varchar(300) NOT NULL,
  `hash` varchar(35) DEFAULT NULL,
  `service` enum('google','twitter','facebook','yahoo','linkedin','manual') NOT NULL,
  `screen_name` varchar(75) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `email` varchar(50) DEFAULT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `website` varchar(200) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `gender` enum('male','female') DEFAULT NULL,
  `org_name` varchar(75) DEFAULT NULL,
  `org_title` varchar(75) DEFAULT NULL,
  `location` varchar(200) DEFAULT NULL,
  `timezone` varchar(75) DEFAULT NULL,
  `language` varchar(10) DEFAULT NULL,
  `optedin` tinyint(1) NOT NULL DEFAULT '0',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `owner_service_contact` (`owner_id`,`handle`,`service`),
  KEY `contacts_idx_owner_id` (`owner_id`),
  KEY `contacts_idx_user_id` (`user_id`),
  CONSTRAINT `contacts_fk_owner_id` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `contacts_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `events`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `events` (
  `id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `kliq_id` char(36) NOT NULL,
  `title` varchar(64) DEFAULT NULL,
  `when_occurs` datetime NOT NULL,
  `location` varchar(64) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `events_idx_user_id` (`user_id`),
  KEY `events_idx_kliq_id` (`kliq_id`),
  CONSTRAINT `events_fk_kliq_id` FOREIGN KEY (`kliq_id`) REFERENCES `kliqs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `events_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `kliq_contact_map`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kliq_contact_map` (
  `kliq_id` char(36) NOT NULL,
  `contact_id` char(36) NOT NULL,
  PRIMARY KEY (`kliq_id`,`contact_id`),
  KEY `kliq_contact_map_idx_contact_id` (`contact_id`),
  KEY `kliq_contact_map_idx_kliq_id` (`kliq_id`),
  CONSTRAINT `kliq_contact_map_fk_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `contacts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `kliq_contact_map_fk_kliq_id` FOREIGN KEY (`kliq_id`) REFERENCES `kliqs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `kliqs`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `kliqs` (
  `id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `name` varchar(100) NOT NULL,
  `image` varchar(150) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `kliqs_idx_user_id` (`user_id`),
  CONSTRAINT `kliqs_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `oauth_tokens`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `oauth_tokens` (
  `id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `persona_id` char(36) DEFAULT NULL,
  `token` varchar(4096) NOT NULL,
  `secret` varchar(4096) DEFAULT NULL,
  `service` enum('google','twitter','facebook','yahoo','linkedin') NOT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `oauth_tokens_idx_user_id` (`user_id`),
  CONSTRAINT `oauth_tokens_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `personas`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `personas` (
  `id` char(36) NOT NULL,
  `user_id` char(36) DEFAULT NULL,
  `handle` varchar(300) NOT NULL,
  `service` enum('google','twitter','facebook','yahoo','linkedin','kliq','manual') NOT NULL,
  `screen_name` varchar(75) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `email` varchar(50) DEFAULT NULL,
  `profile_url` varchar(200) DEFAULT NULL,
  `website` varchar(200) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `gender` enum('male','female') DEFAULT NULL,
  `location` varchar(200) DEFAULT NULL,
  `timezone` varchar(75) DEFAULT NULL,
  `language` varchar(10) DEFAULT NULL,
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `personas_idx_user_id` (`user_id`),
  CONSTRAINT `personas_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `share_contact_map`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `share_contact_map` (
  `id` char(36) NOT NULL,
  `share_id` char(36) NOT NULL,
  `contact_id` char(36) NOT NULL,
  `hash` varchar(100) DEFAULT NULL,
  `link` varchar(200) DEFAULT NULL,
  `method` enum('twitter','facebook','im','email') NOT NULL,
  `service` enum('google','twitter','facebook','yahoo') NOT NULL,
  `delivered` tinyint(1) NOT NULL DEFAULT '0',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `share_contact_map_idx_contact_id` (`contact_id`),
  KEY `share_contact_map_idx_share_id` (`share_id`),
  CONSTRAINT `share_contact_map_fk_contact_id` FOREIGN KEY (`contact_id`) REFERENCES `contacts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `share_contact_map_fk_share_id` FOREIGN KEY (`share_id`) REFERENCES `shares` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `share_kliq_map`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `share_kliq_map` (
  `share_id` char(36) NOT NULL,
  `kliq_id` char(36) NOT NULL,
  PRIMARY KEY (`share_id`,`kliq_id`),
  KEY `share_kliq_map_idx_kliq_id` (`kliq_id`),
  KEY `share_kliq_map_idx_share_id` (`share_id`),
  CONSTRAINT `share_kliq_map_fk_kliq_id` FOREIGN KEY (`kliq_id`) REFERENCES `kliqs` (`id`),
  CONSTRAINT `share_kliq_map_fk_share_id` FOREIGN KEY (`share_id`) REFERENCES `shares` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `shares`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `shares` (
  `id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `media_id` char(36) DEFAULT NULL,
  `upload_id` char(36) DEFAULT NULL,
  `title` varchar(64) DEFAULT NULL,
  `message` varchar(1024) DEFAULT NULL,
  `geo_location` varchar(256) DEFAULT NULL,
  `offset` mediumint(8) unsigned NOT NULL DEFAULT '0',
  `allow_reshare` tinyint(1) NOT NULL DEFAULT '0',
  `allow_location_share` tinyint(1) NOT NULL DEFAULT '0',
  `status` enum('new','processing','error','ready','published') NOT NULL DEFAULT 'new',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `shares_idx_media_id` (`media_id`),
  KEY `shares_idx_upload_id` (`upload_id`),
  KEY `shares_idx_user_id` (`user_id`),
  CONSTRAINT `shares_fk_media_id` FOREIGN KEY (`media_id`) REFERENCES `cms_media` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `shares_fk_upload_id` FOREIGN KEY (`upload_id`) REFERENCES `uploads` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `shares_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `uploads`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `uploads` (
  `id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `title` varchar(64) DEFAULT NULL,
  `suffix` varchar(6) NOT NULL,
  `mime_type` varchar(64) NOT NULL,
  `path` varchar(500) NOT NULL,
  `status` enum('new','processing','error','ready','published') NOT NULL DEFAULT 'new',
  `created` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `uploads_idx_user_id` (`user_id`),
  CONSTRAINT `uploads_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` char(36) NOT NULL,
  `username` varchar(32) NOT NULL,
  `password` text NOT NULL,
  `email` varchar(128) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '0',
  `first_name` varchar(32) NOT NULL DEFAULT '',
  `last_name` varchar(32) NOT NULL DEFAULT '',
  `gender` enum('male','female') DEFAULT NULL,
  `profile_photo` blob,
  `picture` varchar(500) DEFAULT NULL,
  `email_verified` tinyint(1) DEFAULT '0',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `zencoder_outputs`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `zencoder_outputs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` char(36) NOT NULL,
  `media_id` char(36) DEFAULT NULL,
  `upload_id` char(36) DEFAULT NULL,
  `share_id` char(36) DEFAULT NULL,
  `asset_format_id` int(10) unsigned NOT NULL,
  `zc_job_id` int(10) unsigned NOT NULL,
  `zc_output_id` int(10) unsigned NOT NULL,
  `state` enum('pending','submitting','transcoding','finished','failed') NOT NULL DEFAULT 'pending',
  `created` datetime NOT NULL,
  `last_modified` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `zencoder_outputs_idx_asset_format_id` (`asset_format_id`),
  KEY `zencoder_outputs_idx_share_id` (`share_id`),
  KEY `zencoder_outputs_idx_media_id` (`media_id`),
  KEY `zencoder_outputs_idx_upload_id` (`upload_id`),
  KEY `zencoder_outputs_idx_user_id` (`user_id`),
  CONSTRAINT `zencoder_outputs_fk_asset_format_id` FOREIGN KEY (`asset_format_id`) REFERENCES `cms_asset_format` (`id`),
  CONSTRAINT `zencoder_outputs_fk_media_id` FOREIGN KEY (`media_id`) REFERENCES `cms_media` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `zencoder_outputs_fk_share_id` FOREIGN KEY (`share_id`) REFERENCES `shares` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `zencoder_outputs_fk_upload_id` FOREIGN KEY (`upload_id`) REFERENCES `uploads` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `zencoder_outputs_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2116 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping routines for database 'kliq21'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed
