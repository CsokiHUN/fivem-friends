-- --------------------------------------------------------
-- Host:                         37.221.214.77
-- Szerver verzió:               10.3.29-MariaDB-0+deb10u1 - Debian 10
-- Szerver OS:                   debian-linux-gnu
-- HeidiSQL Verzió:              11.3.0.6295
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Adatbázis struktúra mentése a es_extended.
CREATE DATABASE IF NOT EXISTS `es_extended` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_hungarian_ci */;
USE `es_extended`;

-- Struktúra mentése tábla es_extended. friends
CREATE TABLE IF NOT EXISTS `friends` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license1` varchar(100) COLLATE utf8mb4_hungarian_ci DEFAULT '',
  `license2` varchar(100) COLLATE utf8mb4_hungarian_ci DEFAULT '',
  `time` varchar(100) COLLATE utf8mb4_hungarian_ci DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_hungarian_ci;

-- Az adatok exportálása nem lett kiválasztva.

-- Struktúra mentése tábla es_extended. pendingFriends
CREATE TABLE IF NOT EXISTS `pendingFriends` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sourceLicense` varchar(100) COLLATE utf8mb4_hungarian_ci DEFAULT '',
  `targetLicense` varchar(100) COLLATE utf8mb4_hungarian_ci DEFAULT '',
  `time` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_hungarian_ci;

-- Az adatok exportálása nem lett kiválasztva.

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
