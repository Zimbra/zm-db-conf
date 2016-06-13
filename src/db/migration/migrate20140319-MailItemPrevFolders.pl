#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2014, 2016 Synacor, Inc.
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

Migrate::verifySchemaVersion(100);

foreach my $group (Migrate::getMailboxGroups()) {
    Migrate::log("Migrating $group.  This can take a substantial amount of time...");
    addPrevFoldersColumnToMailItem($group);
    addPrevFoldersColumnToMailItemDumpster($group);
    Migrate::log("done.\n");
}

Migrate::updateSchemaVersion(100, 101);

exit(0);

########################################################################################################################

sub addPrevFoldersColumnToMailItem($) {
    my ($group) = @_;
    Migrate::logSql("Adding prev_folder_ids column to mail_item table...");
    my $sql = <<_EOF_;
ALTER TABLE $group.mail_item ADD COLUMN prev_folders TEXT AFTER folder_id;
_EOF_
  Migrate::runSql($sql);
}

sub addPrevFoldersColumnToMailItemDumpster($) {
    my ($group) = @_;
    Migrate::logSql("Adding prev_folder_ids column to mail_item_dumpster table...");
    my $sql = <<_EOF_;
ALTER TABLE $group.mail_item_dumpster ADD COLUMN prev_folders TEXT AFTER folder_id;
_EOF_
  Migrate::runSql($sql);
}
