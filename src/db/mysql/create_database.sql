--
-- ***** BEGIN LICENSE BLOCK *****
-- Zimbra Collaboration Suite Server
-- Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016 Synacor, Inc.
--
-- This program is free software: you can redistribute it and/or modify it under
-- the terms of the GNU General Public License as published by the Free Software Foundation,
-- version 2 of the License.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License along with this program.
-- If not, see <https://www.gnu.org/licenses/>.
-- ***** END LICENSE BLOCK *****
--
CREATE DATABASE ${DATABASE_NAME}
DEFAULT CHARACTER SET utf8;

CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.mail_item (
   mailbox_id    INTEGER UNSIGNED NOT NULL,
   id            INTEGER UNSIGNED NOT NULL,
   type          TINYINT NOT NULL,           -- 1 = folder, 5 = message, etc.
   parent_id     INTEGER UNSIGNED,
   folder_id     INTEGER UNSIGNED,
   prev_folders  TEXT,                       -- e.g. "101:2;110:5", before mod_metadata 101, this item was in folder 2, before 110, it was in 5
   index_id      INTEGER UNSIGNED,
   imap_id       INTEGER UNSIGNED,
   date          INTEGER UNSIGNED NOT NULL,  -- stored as a UNIX-style timestamp
   size          BIGINT UNSIGNED NOT NULL,
   locator       VARCHAR(1024),
   blob_digest   VARCHAR(44) BINARY,         -- reference to blob
   unread        INTEGER UNSIGNED,           -- stored separately from the other flags so we can index it
   flags         INTEGER NOT NULL DEFAULT 0,
   tags          BIGINT NOT NULL DEFAULT 0,
   tag_names     TEXT,
   sender        VARCHAR(128),
   recipients    VARCHAR(128),
   subject       TEXT,
   name          VARCHAR(255),               -- namespace entry for item (e.g. tag name, folder name, document filename)
   metadata      MEDIUMTEXT,
   mod_metadata  INTEGER UNSIGNED NOT NULL,  -- change number for last row modification
   change_date   INTEGER UNSIGNED,           -- UNIX-style timestamp for last row modification
   mod_content   INTEGER UNSIGNED NOT NULL,  -- change number for last change to "content" (e.g. blob)
   uuid          VARCHAR(127),               -- e.g. "d94e42c4-1636-11d9-b904-4dd689d02402"

   PRIMARY KEY (mailbox_id, id),
   INDEX i_type (mailbox_id, type),          -- for looking up folders and tags
   INDEX i_parent_id (mailbox_id, parent_id),-- for looking up a parent\'s children
   INDEX i_folder_id_date (mailbox_id, folder_id, date), -- for looking up by folder and sorting by date
   INDEX i_index_id (mailbox_id, index_id),  -- for looking up based on search results
   INDEX i_date (mailbox_id, date),          -- fallback index in case other constraints are not specified
   INDEX i_mod_metadata (mailbox_id, mod_metadata),      -- used by the sync code
   INDEX i_uuid (mailbox_id, uuid),          -- for looking up by uuid 

   UNIQUE INDEX i_name_folder_id (mailbox_id, folder_id, name),   -- for namespace uniqueness

   CONSTRAINT fk_mail_item_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id),
   CONSTRAINT fk_mail_item_parent_id FOREIGN KEY (mailbox_id, parent_id) REFERENCES ${DATABASE_NAME}.mail_item(mailbox_id, id),
   CONSTRAINT fk_mail_item_folder_id FOREIGN KEY (mailbox_id, folder_id) REFERENCES ${DATABASE_NAME}.mail_item(mailbox_id, id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.mail_item_dumpster (
   mailbox_id    INTEGER UNSIGNED NOT NULL,
   id            INTEGER UNSIGNED NOT NULL,
   type          TINYINT NOT NULL,           -- 1 = folder, 5 = message, etc.
   parent_id     INTEGER UNSIGNED,
   folder_id     INTEGER UNSIGNED,
   prev_folders  TEXT,                       -- e.g. "101:2;110:5", before mod_metadata 101, this item was in folder 2, before 110, it was in 5
   index_id      INTEGER UNSIGNED,
   imap_id       INTEGER UNSIGNED,
   date          INTEGER UNSIGNED NOT NULL,  -- stored as a UNIX-style timestamp
   size          BIGINT UNSIGNED NOT NULL,
   locator       VARCHAR(1024),
   blob_digest   VARCHAR(44) BINARY,         -- reference to blob
   unread        INTEGER UNSIGNED,           -- stored separately from the other flags so we can index it
   flags         INTEGER NOT NULL DEFAULT 0,
   tags          BIGINT NOT NULL DEFAULT 0,
   tag_names     TEXT,
   sender        VARCHAR(128),
   recipients    VARCHAR(128),
   subject       TEXT,
   name          VARCHAR(255),               -- namespace entry for item (e.g. tag name, folder name, document filename)
   metadata      MEDIUMTEXT,
   mod_metadata  INTEGER UNSIGNED NOT NULL,  -- change number for last row modification
   change_date   INTEGER UNSIGNED,           -- UNIX-style timestamp for last row modification
   mod_content   INTEGER UNSIGNED NOT NULL,  -- change number for last change to "content" (e.g. blob)
   uuid          VARCHAR(127),               -- e.g. "d94e42c4-1636-11d9-b904-4dd689d02402"

   PRIMARY KEY (mailbox_id, id),
   INDEX i_type (mailbox_id, type),          -- for looking up folders and tags
   INDEX i_parent_id (mailbox_id, parent_id),-- for looking up a parent\'s children
   INDEX i_folder_id_date (mailbox_id, folder_id, date), -- for looking up by folder and sorting by date
   INDEX i_index_id (mailbox_id, index_id),  -- for looking up based on search results
   INDEX i_date (mailbox_id, date),          -- fallback index in case other constraints are not specified
   INDEX i_mod_metadata (mailbox_id, mod_metadata),      -- used by the sync code
   INDEX i_uuid (mailbox_id, uuid),          -- for looking up by uuid 

   -- Must not enforce unique index on (mailbox_id, folder_id, name) for the dumpster version!

   CONSTRAINT fk_mail_item_dumpster_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.revision (
   mailbox_id    INTEGER UNSIGNED NOT NULL,
   item_id       INTEGER UNSIGNED NOT NULL,
   version       INTEGER UNSIGNED NOT NULL,
   date          INTEGER UNSIGNED NOT NULL,  -- stored as a UNIX-style timestamp
   size          BIGINT UNSIGNED NOT NULL,
   locator       VARCHAR(1024),
   blob_digest   VARCHAR(44) BINARY,         -- reference to blob
   name          VARCHAR(255),               -- namespace entry for item (e.g. tag name, folder name, document filename)
   metadata      MEDIUMTEXT,
   mod_metadata  INTEGER UNSIGNED NOT NULL,  -- change number for last row modification
   change_date   INTEGER UNSIGNED,           -- UNIX-style timestamp for last row modification
   mod_content   INTEGER UNSIGNED NOT NULL,  -- change number for last change to "content" (e.g. blob)

   PRIMARY KEY (mailbox_id, item_id, version),

   CONSTRAINT fk_revision_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id),
   CONSTRAINT fk_revision_item_id FOREIGN KEY (mailbox_id, item_id) REFERENCES ${DATABASE_NAME}.mail_item(mailbox_id, id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.revision_dumpster (
   mailbox_id    INTEGER UNSIGNED NOT NULL,
   item_id       INTEGER UNSIGNED NOT NULL,
   version       INTEGER UNSIGNED NOT NULL,
   date          INTEGER UNSIGNED NOT NULL,  -- stored as a UNIX-style timestamp
   size          BIGINT UNSIGNED NOT NULL,
   locator       VARCHAR(1024),
   blob_digest   VARCHAR(44) BINARY,         -- reference to blob
   name          VARCHAR(255),               -- namespace entry for item (e.g. tag name, folder name, document filename)
   metadata      MEDIUMTEXT,
   mod_metadata  INTEGER UNSIGNED NOT NULL,  -- change number for last row modification
   change_date   INTEGER UNSIGNED,           -- UNIX-style timestamp for last row modification
   mod_content   INTEGER UNSIGNED NOT NULL,  -- change number for last change to "content" (e.g. blob)

   PRIMARY KEY (mailbox_id, item_id, version),

   CONSTRAINT fk_revision_dumpster_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id),
   CONSTRAINT fk_revision_dumpster_item_id FOREIGN KEY (mailbox_id, item_id) REFERENCES ${DATABASE_NAME}.mail_item_dumpster(mailbox_id, id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.tag (
   mailbox_id    INTEGER UNSIGNED NOT NULL,
   id            INTEGER NOT NULL,
   name          VARCHAR(128) NOT NULL,
   color         BIGINT,
   item_count    INTEGER NOT NULL DEFAULT 0,
   unread        INTEGER NOT NULL DEFAULT 0,
   listed        BOOLEAN NOT NULL DEFAULT FALSE,
   sequence      INTEGER UNSIGNED NOT NULL,  -- change number for rename/recolor/etc.
   policy        VARCHAR(1024),

   PRIMARY KEY (mailbox_id, id),
   UNIQUE INDEX i_tag_name (mailbox_id, name),
   CONSTRAINT fk_tag_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.tagged_item (
   mailbox_id    INTEGER UNSIGNED NOT NULL,
   tag_id        INTEGER NOT NULL,
   item_id       INTEGER UNSIGNED NOT NULL,

   UNIQUE INDEX i_tagged_item_unique (mailbox_id, tag_id, item_id),
   CONSTRAINT fk_tagged_item_tag FOREIGN KEY (mailbox_id, tag_id) REFERENCES ${DATABASE_NAME}.tag(mailbox_id, id) ON DELETE CASCADE,
   CONSTRAINT fk_tagged_item_item FOREIGN KEY (mailbox_id, item_id) REFERENCES ${DATABASE_NAME}.mail_item(mailbox_id, id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.open_conversation (
   mailbox_id  INTEGER UNSIGNED NOT NULL,
   hash        CHAR(28) BINARY NOT NULL,
   conv_id     INTEGER UNSIGNED NOT NULL,

   PRIMARY KEY (mailbox_id, hash),
   INDEX i_conv_id (mailbox_id, conv_id),
   CONSTRAINT fk_open_conversation_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id),
   CONSTRAINT fk_open_conversation_conv_id FOREIGN KEY (mailbox_id, conv_id) REFERENCES ${DATABASE_NAME}.mail_item(mailbox_id, id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.appointment (
   mailbox_id  INTEGER UNSIGNED NOT NULL,
   uid         VARCHAR(255) NOT NULL,
   item_id     INTEGER UNSIGNED NOT NULL,
   start_time  DATETIME NOT NULL,
   end_time    DATETIME,

   PRIMARY KEY (mailbox_id, uid),
   CONSTRAINT fk_appointment_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id),
   CONSTRAINT fk_appointment_item_id FOREIGN KEY (mailbox_id, item_id) REFERENCES ${DATABASE_NAME}.mail_item(mailbox_id, id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE UNIQUE INDEX i_item_id ON ${DATABASE_NAME}.appointment (mailbox_id, item_id);

CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.appointment_dumpster (
   mailbox_id  INTEGER UNSIGNED NOT NULL,
   uid         VARCHAR(255) NOT NULL,
   item_id     INTEGER UNSIGNED NOT NULL,
   start_time  DATETIME NOT NULL,
   end_time    DATETIME,

   PRIMARY KEY (mailbox_id, uid),
   CONSTRAINT fk_appointment_dumpster_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id),
   CONSTRAINT fk_appointment_dumpster_item_id FOREIGN KEY (mailbox_id, item_id) REFERENCES ${DATABASE_NAME}.mail_item_dumpster(mailbox_id, id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE UNIQUE INDEX i_item_id ON ${DATABASE_NAME}.appointment_dumpster (mailbox_id, item_id);

CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.tombstone (
   mailbox_id  INTEGER UNSIGNED NOT NULL,
   sequence    INTEGER UNSIGNED NOT NULL,  -- change number for deletion
   date        INTEGER UNSIGNED NOT NULL,  -- deletion date as a UNIX-style timestamp
   type        TINYINT,                    -- 1 = folder, 3 = tag, etc.
   ids         TEXT,

   INDEX i_sequence (mailbox_id, sequence),
   CONSTRAINT fk_tombstone_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id)
) ENGINE = InnoDB;

-- Tracks UID's of messages on remote POP3 servers
CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.pop3_message (
   mailbox_id     INTEGER UNSIGNED NOT NULL,
   data_source_id CHAR(36) NOT NULL,
   uid            VARCHAR(255) BINARY NOT NULL,
   item_id        INTEGER UNSIGNED NOT NULL,

   PRIMARY KEY (mailbox_id, item_id),
   CONSTRAINT fk_pop3_message_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id)
) ENGINE = InnoDB;

CREATE UNIQUE INDEX i_uid_pop3_id ON ${DATABASE_NAME}.pop3_message (uid, data_source_id);

-- Tracks folders on remote IMAP servers
CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.imap_folder (
   mailbox_id         INTEGER UNSIGNED NOT NULL,
   item_id            INTEGER UNSIGNED NOT NULL,
   data_source_id     CHAR(36) NOT NULL,
   local_path         VARCHAR(1000) NOT NULL,
   remote_path        VARCHAR(1000) NOT NULL,
   uid_validity       INTEGER UNSIGNED,

   PRIMARY KEY (mailbox_id, item_id),
   CONSTRAINT fk_imap_folder_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE UNIQUE INDEX i_local_path
ON ${DATABASE_NAME}.imap_folder (local_path(200), data_source_id, mailbox_id);

CREATE UNIQUE INDEX i_remote_path
ON ${DATABASE_NAME}.imap_folder (remote_path(200), data_source_id, mailbox_id);

-- Tracks messages on remote IMAP servers
CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.imap_message (
   mailbox_id     INTEGER UNSIGNED NOT NULL,
   imap_folder_id INTEGER UNSIGNED NOT NULL,
   uid            BIGINT NOT NULL,
   item_id        INTEGER UNSIGNED NOT NULL,
   flags          INTEGER NOT NULL DEFAULT 0,

   PRIMARY KEY (mailbox_id, item_id),
   CONSTRAINT fk_imap_message_mailbox_id FOREIGN KEY (mailbox_id)
      REFERENCES zimbra.mailbox(id) ON DELETE CASCADE,
   CONSTRAINT fk_imap_message_imap_folder_id FOREIGN KEY (mailbox_id, imap_folder_id)
      REFERENCES ${DATABASE_NAME}.imap_folder(mailbox_id, item_id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE UNIQUE INDEX i_uid_imap_id ON ${DATABASE_NAME}.imap_message (mailbox_id, imap_folder_id, uid);

-- Tracks local MailItem created from remote objects via DataSource
CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.data_source_item (
   mailbox_id     INTEGER UNSIGNED NOT NULL,
   data_source_id CHAR(36) NOT NULL,
   item_id        INTEGER UNSIGNED NOT NULL,
   folder_id      INTEGER UNSIGNED NOT NULL DEFAULT 0,
   remote_id      VARCHAR(255) BINARY NOT NULL,
   metadata       MEDIUMTEXT,

   PRIMARY KEY (mailbox_id, item_id),
   UNIQUE INDEX i_remote_id (mailbox_id, data_source_id, remote_id),   -- for reverse lookup
   CONSTRAINT fk_data_source_item_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.purged_conversations (
   mailbox_id     INTEGER UNSIGNED NOT NULL,
   data_source_id CHAR(36) NOT NULL,
   item_id        INTEGER UNSIGNED NOT NULL,
   hash           CHAR(28) BINARY NOT NULL,
   
   PRIMARY KEY (mailbox_id, data_source_id, hash),
   CONSTRAINT fk_purged_conversation_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.purged_messages (
   mailbox_id       INTEGER UNSIGNED NOT NULL,
   data_source_id   CHAR(36) NOT NULL,
   item_id          INTEGER UNSIGNED NOT NULL,
   parent_id        INTEGER UNSIGNED,
   remote_id        VARCHAR(255) BINARY NOT NULL,
   remote_folder_id VARCHAR(255) BINARY NOT NULL,
   purge_date       INTEGER UNSIGNED,

   PRIMARY KEY (mailbox_id, data_source_id, item_id),
   CONSTRAINT fk_purged_message_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id) ON DELETE CASCADE
) ENGINE = InnoDB;


-- Support for Zimbra Chat
CREATE DATABASE IF NOT EXISTS `chat`
DEFAULT CHARACTER SET utf8;

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

CREATE TABLE IF NOT EXISTS chat.`MESSAGE` (
   `ID`             VARCHAR(48)   NOT NULL,
   `SENT_TIMESTAMP` BIGINT        NOT NULL,
   `EDIT_TIMESTAMP` BIGINT        DEFAULT 0,
   `MESSAGE_TYPE`   TINYINT       DEFAULT 0,
   `TARGET_TYPE`    TINYINT       DEFAULT 0,
   `INDEX_STATUS`   TINYINT       DEFAULT 0,
   `SENDER`         VARCHAR(256) NOT NULL,
   `DESTINATION`    VARCHAR(256) NOT NULL,
   `TEXT`           VARCHAR(4096),
   `REACTIONS`      VARCHAR(4096),
   `TYPE_EXTRAINFO` VARCHAR(4096)
) ENGINE = InnoDB;

CREATE INDEX IF NOT EXISTS INDEX_SENT
   ON chat.`MESSAGE` (SENT_TIMESTAMP);
CREATE INDEX IF NOT EXISTS INDEX_EDIT
   ON chat.`MESSAGE` (EDIT_TIMESTAMP);
CREATE INDEX IF NOT EXISTS INDEX_FROM
   ON chat.`MESSAGE` (SENDER);
CREATE INDEX IF NOT EXISTS INDEX_TO
   ON chat.`MESSAGE` (DESTINATION);
CREATE INDEX IF NOT EXISTS INDEX_TEXT
   ON chat.`MESSAGE` (`TEXT`(191));

CREATE TABLE IF NOT EXISTS chat.`MESSAGE_READ` (
   `SENDER`                VARCHAR(256) NOT NULL,
   `DESTINATION`           VARCHAR(256) NOT NULL,
   `TIMESTAMP`             BIGINT       NOT NULL,
   `MESSAGE_ID`            VARCHAR(48)
) ENGINE = InnoDB;

CREATE INDEX IF NOT EXISTS INDEX_MESSAGE_READ
   ON chat.`MESSAGE_READ` (`SENDER`(191), `DESTINATION`(191));
CREATE INDEX IF NOT EXISTS INDEX_READ_TIMESTAMP
   ON chat.`MESSAGE_READ` (TIMESTAMP);

CREATE TABLE IF NOT EXISTS chat.`SPACE` (
   `ADDRESS`  VARCHAR(256) NOT NULL,
   `TOPIC`    VARCHAR(256),
   `RESOURCE` VARCHAR(4096),
   `NAME` VARCHAR(256) DEFAULT '' NOT NULL
) ENGINE = InnoDB;

CREATE INDEX IF NOT EXISTS INDEX_SPACE
   ON chat.`SPACE` (`ADDRESS`(191));

CREATE TABLE IF NOT EXISTS chat.`CHANNEL` (
   `ADDRESS`        VARCHAR(256) NOT NULL,
   `CHANNEL_NAME`   VARCHAR(128) NOT NULL,
   `TOPIC`          VARCHAR(256),
   `IS_INVITE_ONLY` BOOLEAN
) ENGINE = InnoDB;

CREATE INDEX IF NOT EXISTS INDEX_CHANNEL
   ON chat.`CHANNEL` (`ADDRESS`(191));

CREATE TABLE IF NOT EXISTS chat.`GROUP` (
   `ADDRESS`      VARCHAR(256) NOT NULL,
   `TOPIC`        VARCHAR(256),
   `IMAGE`        MEDIUMBLOB DEFAULT NULL,
   `IMAGE_UPDATE` BIGINT DEFAULT NULL
) ENGINE = InnoDB;
CREATE INDEX IF NOT EXISTS INDEX_GROUP
   ON chat.`GROUP` (`ADDRESS`(191));

CREATE TABLE IF NOT EXISTS chat.`SUBSCRIPTION` (
   `ADDRESS`            VARCHAR(256) NOT NULL,
   `GROUP_ADDRESS`      VARCHAR(256) NOT NULL,
   `JOINED_TIMESTAMP`   BIGINT,
   `LEFT_TIMESTAMP`     BIGINT,
   `BANNED`             BOOLEAN,
   `CAN_ACCESS_ARCHIVE` BOOLEAN
) ENGINE = InnoDB;

CREATE INDEX IF NOT EXISTS INDEX_SUBSCRIPTION
   ON chat.`SUBSCRIPTION` (`ADDRESS`(191), `GROUP_ADDRESS`(191));

CREATE TABLE IF NOT EXISTS chat.`OWNER` (
   `ADDRESS`            VARCHAR(256) NOT NULL,
   `GROUP_ADDRESS`      VARCHAR(256) NOT NULL
) ENGINE = InnoDB;

CREATE INDEX IF NOT EXISTS INDEX_OWNER
   ON chat.`OWNER` (`ADDRESS`(191), `GROUP_ADDRESS`(191));

CREATE TABLE `chat`.`USERV3` (
  `ID`             VARCHAR(256) NOT NULL,
  `LAST_SEEN`      BIGINT       DEFAULT NULL,
  `STATUS_MESSAGE` VARCHAR(256) DEFAULT '' NOT NULL,
  `IMAGE`          MEDIUMBLOB   DEFAULT NULL,
  `IMAGE_UPDATE`   BIGINT       DEFAULT NULL
) ENGINE = InnoDB;

CREATE INDEX `INDEX_USERV3` ON `chat`.`USERV3` (`ID`);

CREATE TABLE `chat`.`FIREBASE` (
  `TOKEN`       VARCHAR(256) NOT NULL,
  `ACCOUNT_ID`  VARCHAR(256) NOT NULL,
  `API_VERSION` INTEGER NOT NULL
) ENGINE = InnoDB;
CREATE INDEX `INDEX_FIREBASE` ON `chat`.`FIREBASE` (`TOKEN`);

CREATE TABLE `chat`.`USER_ROOM_JOIN` (
  `ACCOUNT_ID`    VARCHAR(256) NOT NULL,
  `ROOM_ADDRESS`  VARCHAR(256) NOT NULL,
  `DELETED_ON`    BIGINT DEFAULT NULL
) ENGINE = InnoDB;
CREATE INDEX `INDEX_USER_ROOM_JOIN` ON `chat`.`USER_ROOM_JOIN` (`ACCOUNT_ID`, `ROOM_ADDRESS`);

CREATE TABLE `chat`.`CHANNELV3` (
  `ADDRESS`        VARCHAR(256) NOT NULL,
  `SPACE_ID`       VARCHAR(256) NOT NULL,
  `NAME`           VARCHAR(128) NOT NULL,
  `TOPIC`          VARCHAR(256),
  `IS_INVITE_ONLY` BOOLEAN DEFAULT FALSE,
  `IMAGE`          MEDIUMBLOB DEFAULT NULL,
  `IMAGE_UPDATE`   BIGINT DEFAULT NULL
) ENGINE = InnoDB;
CREATE INDEX `INDEX_CHANNELV3_ADDRESS` ON `chat`.`CHANNELV3` (`ADDRESS`);
CREATE INDEX `INDEX_CHANNELV3_SPACE_ID` ON `chat`.`CHANNELV3` (`SPACE_ID`);

CREATE TABLE `chat`.`VISIBILITY` (
  `ADDRESS`         VARCHAR(256) NOT NULL,
  `ACCOUNT_ID`      VARCHAR(256) NOT NULL,
  `START_TIMESTAMP` BIGINT       NOT NULL
) ENGINE = InnoDB;
CREATE INDEX `INDEX_VISIBILITY` ON `chat`.`VISIBILITY` (`ACCOUNT_ID`,`ADDRESS`);
CREATE INDEX `INDEX_VISIBILITY_ADDRESS` ON `chat`.`VISIBILITY` (`ADDRESS`);

CREATE TABLE `chat`.`INSTANT_MEETING` (
  `ADDRESS`   VARCHAR(256) NOT NULL,
  `NAME`      VARCHAR(256),
  `PASSWORD`  VARCHAR(256)
) ENGINE = InnoDB;
CREATE INDEX `INDEX_INSTANT_MEETING` ON `chat`.`INSTANT_MEETING` (`ADDRESS`);

CREATE TABLE `chat`.`CONVERSATION_OPTIONS` (
  `ACCOUNT_ID`      VARCHAR(256) NOT NULL,
  `ADDRESS`         VARCHAR(256) NOT NULL,
  `NOTIFICATIONS`   BOOLEAN DEFAULT TRUE
) ENGINE = InnoDB;
CREATE INDEX `INDEX_CONVERSATION_OPTIONS` ON `chat`.`CONVERSATION_OPTIONS` (`ACCOUNT_ID`,`ADDRESS`);
CREATE INDEX `INDEX_CONVERSATION_OPTIONS_ACCOUNT_ID` ON `chat`.`CONVERSATION_OPTIONS` (`ACCOUNT_ID`);
CREATE INDEX `INDEX_CONVERSATION_OPTIONS_ADDRESS` ON `chat`.`CONVERSATION_OPTIONS` (`ADDRESS`);
