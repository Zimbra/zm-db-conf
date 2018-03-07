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

Migrate::verifySchemaVersion(108);

my $sqlStmt = <<_SQL_;

CREATE TABLE IF NOT EXISTS chat.`MESSAGE` (
   `ID`             VARCHAR(256)  NOT NULL,
   `SENT_TIMESTAMP` BIGINT        NOT NULL,
   `EDIT_TIMESTAMP` BIGINT        DEFAULT 0,
   `MESSAGE_TYPE`   TINYINT       DEFAULT 0,
   `INDEX_STATUS`   TINYINT       DEFAULT 0,
   `SENDER`         VARCHAR(256) NOT NULL,
   `DESTINATION`    VARCHAR(256) NOT NULL,
   `TEXT`           VARCHAR(16384),
   `REACTIONS`      VARCHAR(16384),
   `TYPE_EXTRAINFO` VARCHAR(16384)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS chat.`MESSAGE_READ` (
   `SENDER`                VARCHAR(256) NOT NULL,
   `DESTINATION`           VARCHAR(256) NOT NULL,
   `TIMESTAMP`             BIGINT        NOT NULL,
   `MESSAGE_ID`            VARCHAR(256),
   PRIMARY KEY (SENDER, DESTINATION)
) ENGINE = InnoDB;

CREATE INDEX IF NOT EXISTS INDEX_SENT
   ON chat.`MESSAGE` (SENT_TIMESTAMP);
CREATE INDEX IF NOT EXISTS INDEX_EDIT
   ON chat.`MESSAGE` (EDIT_TIMESTAMP);
CREATE INDEX IF NOT EXISTS INDEX_TEXT
   ON chat.`MESSAGE` (TEXT);
CREATE INDEX IF NOT EXISTS INDEX_FROM
   ON chat.`MESSAGE` (SENDER);
CREATE INDEX IF NOT EXISTS INDEX_TO
   ON chat.`MESSAGE` (DESTINATION);
CREATE INDEX IF NOT EXISTS INDEX_READ_TIMESTAMP
   ON chat.`MESSAGE_READ` (TIMESTAMP);

CREATE TABLE IF NOT EXISTS chat.`SPACE` (
  `ADDRESS`  VARCHAR(256) PRIMARY KEY,
  `TOPIC`    VARCHAR(256),
  `RESOURCE` VARCHAR(16384)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS chat.`CHANNEL` (
  `ADDRESS`        VARCHAR(256) NOT NULL,
  `CHANNEL_NAME`   VARCHAR(128) NOT NULL,
  `TOPIC`          VARCHAR(256),
  `IS_INVITE_ONLY` BOOLEAN,
  PRIMARY KEY (ADDRESS, CHANNEL_NAME)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS chat.`GROUP` (
  `ADDRESS` VARCHAR(256) PRIMARY KEY,
  `TOPIC`   VARCHAR(256)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS chat.`SUBSCRIPTION` (
  `ADDRESS`            VARCHAR(256) NOT NULL,
  `GROUP_ADDRESS`      VARCHAR(256) NOT NULL,
  `JOINED_TIMESTAMP`   BIGINT,
  `LEFT_TIMESTAMP`     BIGINT,
  `BANNED`             BOOLEAN,
  `CAN_ACCESS_ARCHIVE` BOOLEAN,
  PRIMARY KEY (ADDRESS, GROUP_ADDRESS)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS chat.`OWNER` (
  `ADDRESS`            VARCHAR(256) NOT NULL,
  `GROUP_ADDRESS`      VARCHAR(256) NOT NULL,
  PRIMARY KEY (ADDRESS, GROUP_ADDRESS)
) ENGINE = InnoDB;

_SQL_

Migrate::runSql($sqlStmt);

Migrate::updateSchemaVersion(108, 109);

exit(0);