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

Migrate::verifySchemaVersion(45);
foreach my $group (Migrate::getMailboxGroups()) {
    createImapDataSourceTables($group);
}
Migrate::updateSchemaVersion(45, 46);

exit(0);

#####################

sub createImapDataSourceTables($) {
  my ($group) = @_;

  my $sql = <<CREATE_TABLE_EOF;
CREATE TABLE $group.imap_folder (
   mailbox_id         INTEGER UNSIGNED NOT NULL,
   item_id            INTEGER UNSIGNED NOT NULL,
   data_source_id     CHAR(36) NOT NULL,
   local_path         VARCHAR(1000) NOT NULL,
   remote_path        VARCHAR(1000) NOT NULL,

   PRIMARY KEY (mailbox_id, item_id),
   CONSTRAINT fk_imap_folder_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE TABLE $group.imap_message (
   mailbox_id     INTEGER UNSIGNED NOT NULL,
   imap_folder_id INTEGER UNSIGNED NOT NULL,
   uid            BIGINT NOT NULL,
   item_id        INTEGER UNSIGNED NOT NULL,

   PRIMARY KEY (mailbox_id, item_id),
   CONSTRAINT fk_imap_message_mailbox_id FOREIGN KEY (mailbox_id)
      REFERENCES zimbra.mailbox(id) ON DELETE CASCADE,
   CONSTRAINT fk_imap_message_imap_folder_id FOREIGN KEY (mailbox_id, imap_folder_id)
      REFERENCES $group.imap_folder(mailbox_id, item_id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE UNIQUE INDEX i_uid_imap_id ON $group.imap_message (mailbox_id, imap_folder_id, uid);
CREATE_TABLE_EOF

  Migrate::runSql($sql);
}
