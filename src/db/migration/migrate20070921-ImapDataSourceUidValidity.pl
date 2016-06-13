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

Migrate::verifySchemaVersion(46);
foreach my $group (Migrate::getMailboxGroups()) {
    alterImapFolderSchema($group);
}
Migrate::updateSchemaVersion(46, 47);

exit(0);

#####################

sub alterImapFolderSchema($) {
  my ($group) = @_;
  my $table = $group . ".imap_folder";

  # The DELETE statement removes bogus folder trackers
  # (remote_path prefixed by /) that were discovered when fixing bug 19108.

  my $sql = <<ALTER_TABLE_EOF;
DELETE FROM $table
WHERE remote_path like '/%';

ALTER TABLE $table
ADD COLUMN uid_validity INTEGER UNSIGNED;

CREATE UNIQUE INDEX i_local_path
ON $table (local_path(200), data_source_id, mailbox_id);

CREATE UNIQUE INDEX i_remote_path
ON $table (remote_path(200), data_source_id, mailbox_id);
ALTER_TABLE_EOF

  Migrate::runSql($sql);
}
