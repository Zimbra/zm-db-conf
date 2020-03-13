-- 
-- ***** BEGIN LICENSE BLOCK *****
-- Zimbra Collaboration Suite Server
-- Copyright (C) 2008, 2009, 2010, 2011, 2013, 2014, 2016 Synacor, Inc.
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

PRAGMA default_cache_size = 500;
PRAGMA encoding = "UTF-8";
PRAGMA legacy_file_format = OFF;

-- -----------------------------------------------------------------------
-- volumes
-- -----------------------------------------------------------------------

-- list of known volumes
CREATE TABLE volume (
   id                     INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   type                   TINYINT NOT NULL,   -- 1 = primary msg, 2 = secondary msg, 10 = index
   name                   VARCHAR(255) NOT NULL UNIQUE,
   path                   TEXT NOT NULL UNIQUE,
   file_bits              SMALLINT NOT NULL,
   file_group_bits        SMALLINT NOT NULL,
   mailbox_bits           SMALLINT NOT NULL,
   mailbox_group_bits     SMALLINT NOT NULL,
   compress_blobs         BOOLEAN NOT NULL,
   compression_threshold  BIGINT NOT NULL
);

-- This table has only one row.  It points to message and index volumes
-- to use for newly provisioned mailboxes.
CREATE TABLE current_volumes (
   message_volume_id            INTEGER NOT NULL,
   secondary_message_volume_id  INTEGER,
   index_volume_id              INTEGER NOT NULL,
   next_mailbox_id              INTEGER NOT NULL,

   CONSTRAINT fk_current_volumes_message_volume_id FOREIGN KEY (message_volume_id) REFERENCES volume(id),
   CONSTRAINT fk_current_volumes_secondary_message_volume_id FOREIGN KEY (secondary_message_volume_id) REFERENCES volume(id),
   CONSTRAINT fk_current_volumes_index_volume_id FOREIGN KEY (index_volume_id) REFERENCES volume(id)
);

-- -----------------------------------------------------------------------
-- mailbox info
-- -----------------------------------------------------------------------

CREATE TABLE mailbox (
   id                  BIGINT UNSIGNED NOT NULL PRIMARY KEY,
   account_id          VARCHAR(127) NOT NULL UNIQUE,  -- e.g. "d94e42c4-1636-11d9-b904-4dd689d02402"
   last_backup_at      INTEGER UNSIGNED,              -- last full backup time, UNIX-style timestamp
   comment             VARCHAR(255)                   -- usually the main email address originally associated with the mailbox
);

CREATE INDEX i_mailbox_last_backup_at ON mailbox(last_backup_at, id);

-- -----------------------------------------------------------------------
-- deleted accounts
-- -----------------------------------------------------------------------

CREATE TABLE deleted_account (
   email       VARCHAR(255) NOT NULL PRIMARY KEY,
   account_id  VARCHAR(127) NOT NULL,
   mailbox_id  INTEGER UNSIGNED NOT NULL,
   deleted_at  INTEGER UNSIGNED NOT NULL      -- UNIX-style timestamp
);

-- -----------------------------------------------------------------------
-- etc.
-- -----------------------------------------------------------------------

-- table for global config params
CREATE TABLE config (
   name         VARCHAR(255) NOT NULL PRIMARY KEY,
   value        TEXT,
   description  TEXT,
   modified     TIMESTAMP DEFAULT (DATETIME('NOW'))
);

INSERT INTO config (name, value, description)
  VALUES ('abq_mode', 'disabled', 'Whether ABQ mode is on/off');
INSERT INTO config (name, description)
  VALUES ('abq_admin_email_list', 'ABQ admin email list');
INSERT INTO config (name, value, description)
  VALUES ('abq_notification_interval', '8h', 'ABQ notification interval');
INSERT INTO config (name, description)
  VALUES ('abq_last_notification_time', 'ABQ last notification time');

-- table for tracking database table maintenance
CREATE TABLE table_maintenance (
   database_name       VARCHAR(64) NOT NULL,
   table_name          VARCHAR(64) NOT NULL,
   maintenance_date    DATETIME NOT NULL,
   last_optimize_date  DATETIME,
   num_rows            INTEGER UNSIGNED NOT NULL,

   PRIMARY KEY (table_name, database_name)
);

CREATE TABLE service_status (
   server   VARCHAR(255) NOT NULL,
   service  VARCHAR(255) NOT NULL,
   time     DATETIME,
   status   BOOL,
  
   UNIQUE (server, service)
);

-- Tracks scheduled tasks
CREATE TABLE scheduled_task (
   class_name       VARCHAR(255) NOT NULL,
   name             VARCHAR(255) NOT NULL,
   mailbox_id       INTEGER UNSIGNED NOT NULL,
   exec_time        DATETIME,
   interval_millis  INTEGER UNSIGNED,
   metadata         MEDIUMTEXT,

   PRIMARY KEY (name, mailbox_id, class_name),
   CONSTRAINT fk_st_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES mailbox(id) ON DELETE CASCADE
);

CREATE INDEX i_scheduled_task_mailbox_id ON scheduled_task(mailbox_id);

-- Mobile Devices
CREATE TABLE mobile_devices (
   mailbox_id          BIGINT UNSIGNED NOT NULL,
   device_id           VARCHAR(64) NOT NULL,
   device_type         VARCHAR(64) NOT NULL,
   user_agent          VARCHAR(64),
   protocol_version    VARCHAR(64),
   provisionable       BOOLEAN NOT NULL DEFAULT 0,
   status              TINYINT UNSIGNED NOT NULL DEFAULT 0,
   policy_key          INTEGER UNSIGNED,
   recovery_password   VARCHAR(64),
   first_req_received  INTEGER UNSIGNED NOT NULL,
   last_policy_update  INTEGER UNSIGNED,
   remote_wipe_req     INTEGER UNSIGNED,
   remote_wipe_ack     INTEGER UNSIGNED,
   policy_values       VARCHAR(512),
   last_used_date      DATE,
   deleted_by_user     BOOLEAN NOT NULL DEFAULT 0,
   model               VARCHAR(64),
   imei                VARCHAR(64),
   friendly_name       VARCHAR(512),
   os                  VARCHAR(64),
   os_language         VARCHAR(64),
   phone_number        VARCHAR(64),
   unapproved_appl_list TEXT NULL,
   approved_appl_list   TEXT NULL,

   PRIMARY KEY (mailbox_id, device_id),
   INDEX i_device_id (device_id),
   CONSTRAINT fk_mobile_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES mailbox(id) ON DELETE CASCADE
);

CREATE TABLE abq_devices (
   id              INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
   device_id       VARCHAR(64) NOT NULL,
   account_id      VARCHAR(127),
   status          ENUM('allowed', 'quarantined', 'blocked'),
   created_time    DATETIME,
   created_by      VARCHAR(255),
   modified_time   DATETIME,
   modified_by     VARCHAR(255),

   CONSTRAINT pk_abq_devices PRIMARY KEY (id),
   CONSTRAINT fk_abq_devices_device_id FOREIGN KEY (device_id) REFERENCES mobile_devices(device_id) ON DELETE CASCADE
);

CREATE INDEX i_device_id ON abq_devices(device_id);
CREATE INDEX i_account_id ON abq_devices(account_id);
CREATE INDEX i_status ON abq_devices(status);
CREATE INDEX i_mobile_devices_last_used_date ON mobile_devices(last_used_date);
