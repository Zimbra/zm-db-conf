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

ALTER TABLE zimbra.`MOBILE_DEVICES`
ADD `ADDED_TO_QUARANTINE` BOOLEAN DEFAULT 0,
ADD `QUARANTINE_STATUS` VARCHAR(64) NULL;

_SQL_

Migrate::runSql($sqlStmt);

Migrate::updateSchemaVersion(111, 112);

exit(0);
