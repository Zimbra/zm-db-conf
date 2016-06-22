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

Migrate::verifySchemaVersion(104);
foreach my $group (Migrate::getMailboxGroups()) {
    addPurgeTables($group);
}
Migrate::updateSchemaVersion(104, 105);
exit(0);

sub addPurgeTables($) {
  my ($DATABASE_NAME) = @_;   
  Migrate::logSql("Adding purge tables to $DATABASE_NAME.");

  my $sqlStmt = <<_SQL_;
CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.purged_conversations (
   mailbox_id     INTEGER UNSIGNED NOT NULL,
   data_source_id CHAR(36) NOT NULL,
   item_id        INTEGER UNSIGNED NOT NULL,
   hash           CHAR(28) BINARY NOT NULL,
   
   PRIMARY KEY (mailbox_id, data_source_id, hash),
   CONSTRAINT fk_purged_conversation_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS ${DATABASE_NAME}.purged_messages (
   mailbox_id       INTEGER UNSIGNED NOT NULL,
   data_source_id   CHAR(36) NOT NULL,
   item_id          INTEGER UNSIGNED NOT NULL,
   parent_id        INTEGER UNSIGNED,
   remote_id        VARCHAR(255) BINARY NOT NULL,
   remote_folder_id VARCHAR(255) BINARY NOT NULL,
   purge_date       INTEGER UNSIGNED,

   PRIMARY KEY (mailbox_id, data_source_id, item_id),
   CONSTRAINT fk_purged_message_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id) ON DELETE CASCADE
) ENGINE = InnoDB;
_SQL_

  Migrate::runSql($sqlStmt);
}

