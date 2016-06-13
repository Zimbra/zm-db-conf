#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2013, 2014, 2016 Synacor, Inc.
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

########################################################################################################################

Migrate::verifySchemaVersion(92);

addItemcacheCheckpointColumn();
addCurrentSessionsTable();

Migrate::updateSchemaVersion(92, 100);

exit(0);

########################################################################################################################

sub addItemcacheCheckpointColumn() {
    Migrate::logSql("Adding ITEMCACHE_CHECKPOINT column to mailbox table...");
    my $sql = <<_EOF_;
ALTER TABLE mailbox ADD COLUMN itemcache_checkpoint INTEGER UNSIGNED NOT NULL DEFAULT 0;
_EOF_
  Migrate::runSql($sql);
}

sub addCurrentSessionsTable() {
    Migrate::logSql("Adding CURRENT_SESSIONS table...");
    my $sql = <<_EOF_;
CREATE TABLE IF NOT EXISTS current_sessions (
	id				INTEGER UNSIGNED NOT NULL,
	server_id		VARCHAR(127) NOT NULL,
	PRIMARY KEY (id, server_id)
) ENGINE = InnoDB;
_EOF_
  Migrate::runSql($sql);
}
