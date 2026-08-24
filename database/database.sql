-- ============================================================
-- Community Connect - Lost & Found Application
-- MySQL Database Schema
-- ============================================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

-- ============================================================
-- Database: community_connect
-- ============================================================

-- Drop tables if they exist (in correct dependency order)
DROP TABLE IF EXISTS `reports`;
DROP TABLE IF EXISTS `messages`;
DROP TABLE IF EXISTS `auth_tokens`;
DROP TABLE IF EXISTS `items`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `users`;

-- ============================================================
-- Table: users
-- ============================================================
CREATE TABLE `users` (
  `id`            INT(11)      NOT NULL AUTO_INCREMENT,
  `full_name`     VARCHAR(150) NOT NULL,
  `email`         VARCHAR(200) NOT NULL,
  `phone`         VARCHAR(30)  NOT NULL,
  `password`      VARCHAR(255) NOT NULL,
  `profile_image` VARCHAR(500)          DEFAULT NULL,
  `status`        ENUM('active','suspended','deleted') NOT NULL DEFAULT 'active',
  `reset_token`   VARCHAR(255)          DEFAULT NULL,
  `reset_expires` DATETIME              DEFAULT NULL,
  `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- Table: auth_tokens
-- ============================================================
CREATE TABLE `auth_tokens` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `user_id`    INT(11)      NOT NULL,
  `token`      VARCHAR(255) NOT NULL,
  `expires_at` DATETIME     NOT NULL,
  `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_token` (`token`),
  KEY `idx_auth_tokens_user_id` (`user_id`),
  KEY `idx_auth_tokens_expires` (`expires_at`),
  CONSTRAINT `fk_auth_tokens_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- Table: categories
-- ============================================================
CREATE TABLE `categories` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(100) NOT NULL,
  `icon`        VARCHAR(100)          DEFAULT NULL,
  `description` VARCHAR(255)          DEFAULT NULL,
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_categories_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- Table: items
-- ============================================================
CREATE TABLE `items` (
  `id`                     INT(11)      NOT NULL AUTO_INCREMENT,
  `user_id`                INT(11)      NOT NULL,
  `category_id`            INT(11)               DEFAULT NULL,
  `type`                   ENUM('lost','found')  NOT NULL,
  `title`                  VARCHAR(255) NOT NULL,
  `description`            TEXT         NOT NULL,
  `location`               VARCHAR(255) NOT NULL,
  `date_occurred`          DATE         NOT NULL,
  `time_occurred`          TIME                  DEFAULT NULL,
  `image`                  VARCHAR(500)          DEFAULT NULL,
  `additional_information` TEXT                  DEFAULT NULL,
  `status`                 ENUM('active','resolved','deleted') NOT NULL DEFAULT 'active',
  `created_at`             DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`             DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_items_user_id`     (`user_id`),
  KEY `idx_items_category_id` (`category_id`),
  KEY `idx_items_type`        (`type`),
  KEY `idx_items_status`      (`status`),
  KEY `idx_items_date`        (`date_occurred`),
  FULLTEXT KEY `ft_items_search` (`title`, `description`, `location`),
  CONSTRAINT `fk_items_user`     FOREIGN KEY (`user_id`)     REFERENCES `users`      (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_items_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- Table: messages
-- ============================================================
CREATE TABLE `messages` (
  `id`          INT(11)  NOT NULL AUTO_INCREMENT,
  `sender_id`   INT(11)  NOT NULL,
  `receiver_id` INT(11)  NOT NULL,
  `item_id`     INT(11)           DEFAULT NULL,
  `message`     TEXT     NOT NULL,
  `is_read`     TINYINT(1)        NOT NULL DEFAULT 0,
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_messages_sender`   (`sender_id`),
  KEY `idx_messages_receiver` (`receiver_id`),
  KEY `idx_messages_item`     (`item_id`),
  KEY `idx_messages_is_read`  (`is_read`),
  CONSTRAINT `fk_messages_sender`   FOREIGN KEY (`sender_id`)   REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_messages_receiver` FOREIGN KEY (`receiver_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_messages_item`     FOREIGN KEY (`item_id`)     REFERENCES `items` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- Table: reports
-- ============================================================
CREATE TABLE `reports` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `item_id`     INT(11)      NOT NULL,
  `reported_by` INT(11)      NOT NULL,
  `reason`      VARCHAR(500) NOT NULL,
  `status`      ENUM('pending','reviewed','dismissed') NOT NULL DEFAULT 'pending',
  `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_reports_item`     (`item_id`),
  KEY `idx_reports_reporter` (`reported_by`),
  CONSTRAINT `fk_reports_item`     FOREIGN KEY (`item_id`)     REFERENCES `items`  (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_reports_reporter` FOREIGN KEY (`reported_by`) REFERENCES `users`  (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- Seed Data: Categories
-- ============================================================
INSERT INTO `categories` (`name`, `icon`, `description`) VALUES
  ('Phones',      'smartphone',       'Mobile phones and accessories'),
  ('Laptops',     'laptop',           'Laptops and computers'),
  ('Bags',        'backpack',         'Bags, backpacks and luggage'),
  ('Wallets',     'account_balance_wallet', 'Wallets and purses'),
  ('Keys',        'vpn_key',          'Keys of all kinds'),
  ('Documents',   'description',      'IDs, passports and documents'),
  ('Clothing',    'checkroom',        'Clothes and accessories'),
  ('Electronics', 'electrical_services', 'Electronic devices and gadgets'),
  ('Books',       'menu_book',        'Books and notebooks'),
  ('Other',       'category',         'Miscellaneous items');

COMMIT;
