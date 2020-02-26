#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2020 Synacor, Inc.
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

Migrate::verifySchemaVersion(111);

my $sqlStmt = <<_SQL_;

INSERT INTO zimbra.`CONFIG` (name, value, description, modified)
  VALUES ('abq_mode', 'disabled', 'Whether ABQ mode is on/off', CURRENT_TIMESTAMP);
INSERT INTO zimbra.`CONFIG` (name, description, modified)
  VALUES ('abq_admin_email_list', 'ABQ admin email list', CURRENT_TIMESTAMP);
INSERT INTO zimbra.`CONFIG` (name, value, description, modified)
  VALUES ('abq_notification_interval', '8h', 'ABQ notification interval', CURRENT_TIMESTAMP);
INSERT INTO zimbra.`CONFIG` (name, description, modified)
  VALUES ('abq_last_notification_time', 'ABQ last notification time', CURRENT_TIMESTAMP);
  
CREATE INDEX i_device_id ON mobile_devices (device_id);
  
CREATE TABLE zimbra.abq_devices (
   device_id       VARCHAR(64) NOT NULL,
   account_id      VARCHAR(127) NOT NULL,
   status          VARCHAR(64),
   created_time    DATETIME,
   created_by      VARCHAR(255),
   modified_time   DATETIME,
   modified_by     VARCHAR(255),

   CONSTRAINT pk_abq_devices PRIMARY KEY (device_id, account_id),
   CONSTRAINT fk_abq_devices_device_id FOREIGN KEY (device_id) REFERENCES mobile_devices(device_id) ON DELETE CASCADE,
   CONSTRAINT fk_abq_devices_account_id FOREIGN KEY (account_id) REFERENCES mailbox(account_id) ON DELETE CASCADE
) ENGINE = InnoDB;

_SQL_

Migrate::runSql($sqlStmt);

Migrate::updateSchemaVersion(111, 112);

exit(0);
