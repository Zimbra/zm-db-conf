#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2015 Zimbra, Inc.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.
# ***** END LICENSE BLOCK *****
#


use strict;
use Migrate;

Migrate::verifySchemaVersion(121);
foreach my $group (Migrate::getMailboxGroups()) {
    addDavNameTable($group);
}
Migrate::updateSchemaVersion(121, 122);
exit(0);

sub addDavNameTable($) {
  my ($DATABASE_NAME) = @_;
  Migrate::logSql("Adding dav_name table to $DATABASE_NAME.");

  my $sqlStmt = <<_SQL_;
CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.dav_name (
   mailbox_id       INTEGER UNSIGNED NOT NULL,
   item_id          INTEGER UNSIGNED NOT NULL,
   folder_id        INTEGER UNSIGNED NOT NULL,
   dav_base_name    VARCHAR(255) NOT NULL,

   PRIMARY KEY (mailbox_id, item_id),
   UNIQUE INDEX i_folder_id_dav_base_name (mailbox_id, folder_id, dav_base_name),   -- for namespace uniqueness
   CONSTRAINT fk_dav_name_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id) ON DELETE CASCADE,
   CONSTRAINT fk_dav_name_item_id FOREIGN KEY (mailbox_id, item_id)
      REFERENCES ${DATABASE_NAME}.mail_item(mailbox_id, id) ON DELETE CASCADE
) ENGINE = InnoDB;
_SQL_

  Migrate::runSql($sqlStmt);
}

