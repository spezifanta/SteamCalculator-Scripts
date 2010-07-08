CREATE TABLE IF NOT EXISTS `sc_steamgameprices` (
  `appid` int(10) unsigned NOT NULL,
  `at` mediumint(6) unsigned NOT NULL,
  `au` mediumint(6) unsigned NOT NULL,
  `de` mediumint(6) unsigned NOT NULL,
  `no` mediumint(6) unsigned NOT NULL,
  `pl` mediumint(6) unsigned NOT NULL,
  `uk` mediumint(6) unsigned NOT NULL,
  `us` mediumint(6) unsigned NOT NULL,
  PRIMARY KEY (`appid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `sc_steamgames` (
  `appid` int(10) unsigned NOT NULL,
  `title` varchar(250) NOT NULL,
  `releasedate` int(10) unsigned NOT NULL,
  `lastupdate` int(10) unsigned NOT NULL,
  `flags` tinyint(4) unsigned NOT NULL,
  PRIMARY KEY (`appid`),
  KEY `title` (`title`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
