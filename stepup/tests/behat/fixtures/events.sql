-- MySQL dump 10.13  Distrib 5.7.23, for Linux (x86_64)
--
-- Host: 127.0.0.1    Database: middleware_test
-- ------------------------------------------------------
-- Server version	5.5.5-10.0.35-MariaDB-wsrep

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
-- Table structure for table `event_stream`
--

DROP TABLE IF EXISTS `event_stream`;
/*!40101 SET @saved_cs_client=@@character_set_client */;
/*!40101 SET character_set_client=utf8 */;
CREATE TABLE `event_stream`
(
    `uuid`        varchar(36) COLLATE utf8_unicode_ci NOT NULL,
    `playhead`    int(11)                             NOT NULL,
    `metadata`    text COLLATE utf8_unicode_ci        NOT NULL,
    `payload`     longtext COLLATE utf8_unicode_ci    NOT NULL,
    `recorded_on` varchar(32) COLLATE utf8_unicode_ci NOT NULL,
    `type`        varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
    PRIMARY KEY (`uuid`, `playhead`),
    KEY `type` (`type`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8
  COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client=@saved_cs_client */;

--
-- Dumping data for table `event_stream`
--

LOCK TABLES `event_stream` WRITE;
/*!40000 ALTER TABLE `event_stream`
    DISABLE KEYS */;
INSERT INTO `event_stream`
VALUES ('e9ab38c3-84a8-47e6-b371-4da5c303669a', 0, '{\"class\":\"Broadway\\\\Domain\\\\Metadata\",\"payload\":[]}',
        '{\"class\":\"Surfnet\\\\Stepup\\\\Identity\\\\Event\\\\IdentityCreatedEvent\",\"payload\":{\"id\":\"e9ab38c3-84a8-47e6-b371-4da5c303669a\",\"institution\":\"dev.openconext.local\",\"name_id\":\"urn:collab:person:dev.openconext.local:admin\",\"preferred_locale\":\"en_GB\"}}',
        '2018-07-30T13:10:08.436248+00:00', 'Surfnet.Stepup.Identity.Event.IdentityCreatedEvent'),
       ('e9ab38c3-84a8-47e6-b371-4da5c303669a', 1, '{\"class\":\"Broadway\\\\Domain\\\\Metadata\",\"payload\":[]}',
        '{\"class\":\"Surfnet\\\\Stepup\\\\Identity\\\\Event\\\\YubikeySecondFactorBootstrappedEvent\",\"payload\":{\"identity_id\":\"e9ab38c3-84a8-47e6-b371-4da5c303669a\",\"name_id\":\"urn:collab:person:dev.openconext.local:admin\",\"identity_institution\":\"dev.openconext.local\",\"preferred_locale\":\"en_GB\",\"second_factor_id\":\"af44163d-ff32-4abd-a65e-629171df8cb3\"}}',
        '2018-07-30T13:10:08.445290+00:00', 'Surfnet.Stepup.Identity.Event.YubikeySecondFactorBootstrappedEvent');
/*!40000 ALTER TABLE `event_stream`
    ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_stream_sensitive_data`
--

DROP TABLE IF EXISTS `event_stream_sensitive_data`;
/*!40101 SET @saved_cs_client=@@character_set_client */;
/*!40101 SET character_set_client=utf8 */;
CREATE TABLE `event_stream_sensitive_data`
(
    `identity_id`    varchar(36) COLLATE utf8_unicode_ci NOT NULL,
    `playhead`       int(11)                             NOT NULL,
    `sensitive_data` longtext COLLATE utf8_unicode_ci    NOT NULL,
    PRIMARY KEY (`identity_id`, `playhead`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8
  COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client=@saved_cs_client */;

--
-- Dumping data for table `event_stream_sensitive_data`
--

LOCK TABLES `event_stream_sensitive_data` WRITE;
/*!40000 ALTER TABLE `event_stream_sensitive_data`
    DISABLE KEYS */;
INSERT INTO `event_stream_sensitive_data`
VALUES ('e9ab38c3-84a8-47e6-b371-4da5c303669a', 0,
        '{\"common_name\":\"Admin\",\"email\":\"admin@dev.openconext.local\"}'),
       ('e9ab38c3-84a8-47e6-b371-4da5c303669a', 1,
        '{\"common_name\":\"Admin\",\"email\":\"admin@dev.openconext.local\",\"second_factor_type\":\"yubikey\",\"second_factor_identifier\":\"02513949\"}');

/*!40000 ALTER TABLE `event_stream_sensitive_data` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

-- Dump completed on 2018-09-13 15:27:19
