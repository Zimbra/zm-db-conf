#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2007, 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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
my $concurrent = 10;

Migrate::verifySchemaVersion(39);

my @sql = ();
my $sqlStmt = <<_SQL_;
ALTER TABLE mailbox
ADD COLUMN last_backup_at INTEGER UNSIGNED AFTER tracking_imap,
ADD INDEX i_last_backup_at (last_backup_at, id);
_SQL_
push(@sql, $sqlStmt);
Migrate::runSqlParallel($concurrent, @sql);

Migrate::updateSchemaVersion(39, 40);

exit(0);
