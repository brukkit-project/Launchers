SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

CREATE TABLE IF NOT EXISTS `jobs` (
  `username` varchar(20) DEFAULT NULL,
  `experience` int(11) DEFAULT NULL,
  `level` int(11) DEFAULT NULL,
  `job` varchar(20) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `sip` (
  `time` varchar(255) NOT NULL,
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sip` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC AUTO_INCREMENT=0 ;

CREATE TABLE IF NOT EXISTS `banlist` (
  `name` varchar(32) NOT NULL,
  `reason` text NOT NULL,
  `admin` varchar(32) NOT NULL,
  `time` bigint(20) NOT NULL,
  `temptime` bigint(20) NOT NULL DEFAULT '0',
  `type` int(11) NOT NULL DEFAULT '0',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ip` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC AUTO_INCREMENT=0 ;

CREATE TABLE IF NOT EXISTS `iConomy` (
  `id` int(255) NOT NULL AUTO_INCREMENT,
  `username` varchar(32) NOT NULL,
  `balance` double(64,2) NOT NULL,
  `status` int(2) NOT NULL DEFAULT '0',
  UNIQUE KEY `username` (`username`),
  KEY `id` (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=0 ;

CREATE TABLE IF NOT EXISTS `permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `type` tinyint(1) NOT NULL,
  `permission` varchar(200) NOT NULL,
  `world` varchar(50) DEFAULT NULL,
  `value` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique` (`name`,`permission`,`world`,`type`),
  KEY `user` (`name`,`type`),
  KEY `world` (`world`,`name`,`type`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=5 ;

INSERT IGNORE `permissions` (`id`, `name`, `type`, `permission`, `world`, `value`) VALUES
(0, 'Admin', 0, '*', ' ', ' '),
(1, 'user', 0, 'modifyworld.*', '', ''),
(2, 'vip', 0, 'modifyworld.*', '', ''),
(3, 'premium', 0, 'modifyworld.*', '', ''),
(4, 'demo', 1, 'group-premium-until', ' ', '1391024852');

CREATE TABLE IF NOT EXISTS `permissions_entity` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `type` tinyint(1) NOT NULL,
  `prefix` varchar(255) NOT NULL,
  `suffix` varchar(255) NOT NULL,
  `default` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `default` (`default`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=6 ;

INSERT IGNORE `permissions_entity` (`id`, `name`, `type`, `prefix`, `suffix`, `default`) VALUES
(1, 'user', 0, '&f[&7User&f]', '', 1),
(3, 'vip', 0, '&f[&6V.I.P&f]', '', 0),
(4, 'premium', 0, '&f[&2Premium&f]', '', 0),
(5, 'Admin', 0, '&f[&4Admin&f]', '', 0);

CREATE TABLE IF NOT EXISTS `permissions_inheritance` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `child` varchar(50) NOT NULL,
  `parent` varchar(50) NOT NULL,
  `type` tinyint(1) NOT NULL,
  `world` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `child` (`child`,`parent`,`type`,`world`),
  KEY `child_2` (`child`,`type`),
  KEY `parent` (`parent`,`type`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=0 ;

CREATE TABLE IF NOT EXISTS `usersession` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user` varchar(255) DEFAULT 'user',
  `session` varchar(255) DEFAULT NULL,
  `server` varchar(255) DEFAULT NULL,
  `token` varchar(255) DEFAULT NULL,
  `realmoney` int(255) DEFAULT '0',
  `md5` varchar(255) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=0 ;

CREATE TABLE IF NOT EXISTS `sashok724_launcher_keys` (
  `key` varchar(255) DEFAULT NULL,
  `amount` int(255) DEFAULT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;