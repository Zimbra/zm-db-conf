#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2012, 2013, 2014, 2016 Synacor, Inc.
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

Migrate::verifySchemaVersion(87);

addLastPurgeAtColumn();

Migrate::updateSchemaVersion(87, 88);

exit(0);

#####################

sub addLastPurgeAtColumn() {
    my $sql = <<MAILBOX_ADD_COLUMN_EOF;
ALTER TABLE mailbox ADD COLUMN last_purge_at INTEGER UNSIGNED NOT NULL DEFAULT 0;
MAILBOX_ADD_COLUMN_EOF
    
    Migrate::log("Adding last_purge_at column to ZIMBRA.MAILBOX table.");
    Migrate::runSql($sql);
}