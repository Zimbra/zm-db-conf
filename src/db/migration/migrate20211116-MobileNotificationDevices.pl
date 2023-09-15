#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2021 Synacor, Inc.
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

Migrate::verifySchemaVersion(114);

my $sqlStmt = <<_SQL_;
ALTER TABLE zmg_devices DROP PRIMARY KEY;
ALTER TABLE zmg_devices ADD CONSTRAINT PK_zmg_devices PRIMARY KEY (mailbox_id, reg_id);
ALTER TABLE zmg_devices ADD COLUMN send_mail_notification TINYINT(1) DEFAULT 1;
ALTER TABLE zmg_devices ADD COLUMN send_reminder_notification TINYINT(1) DEFAULT 1;
_SQL_

Migrate::runSql($sqlStmt);

Migrate::updateSchemaVersion(114, 115);

exit(0);
