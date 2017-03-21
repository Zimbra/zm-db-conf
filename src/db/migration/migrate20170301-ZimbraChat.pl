#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2015, 2016 Synacor, Inc.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <https://www.gnu.org/licenses/>.
# ***** END LICENSE BLOCK *****
#

use strict;
use Migrate;

Migrate::verifySchemaVersion(107);

my $sqlStmt = <<_SQL_;


CREATE DATABASE IF NOT EXISTS `chat`;

CREATE TABLE IF NOT EXISTS chat.`USER` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `ADDRESS` varchar(256) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS chat.`RELATIONSHIP` (
  `USERID` int(11) NOT NULL,
  `TYPE` tinyint(4) NOT NULL,
  `BUDDYADDRESS` varchar(256) NOT NULL,
  `BUDDYNICKNAME` varchar(128) NOT NULL,
  `GROUP` varchar(256) NOT NULL DEFAULT ''
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS chat.`EVENTMESSAGE` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `USERID` int(11) NOT NULL,
  `EVENTID` varchar(36) DEFAULT NULL,
  `SENDER` varchar(256) NOT NULL,
  `TIMESTAMP` bigint(20) DEFAULT NULL,
  `MESSAGE` text,
  PRIMARY KEY (`ID`)
) ENGINE = InnoDB;
_SQL_

Migrate::runSql($sqlStmt);

Migrate::updateSchemaVersion(107, 108);

exit(0);