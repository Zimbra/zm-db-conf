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

Migrate::verifySchemaVersion(109);

my $sqlStmt = <<_SQL_;


ALTER TABLE chat.`USER` CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE chat.`RELATIONSHIP` CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE chat.`EVENTMESSAGE` CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;

_SQL_

Migrate::runSql($sqlStmt);

Migrate::updateSchemaVersion(109, 110);

exit(0);