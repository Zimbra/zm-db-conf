#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

Migrate::verifySchemaVersion(61);
foreach my $group (Migrate::getMailboxGroups()) {
    updateDataSourceItemTable($group);
}
Migrate::updateSchemaVersion(61, 62);

exit(0);

#####################

sub updateDataSourceItemTable() {
  my ($group) = @_;
  Migrate::logSql("Updating data_source_item table for ".$group.".");
  
  my $sql = <<CREATE_TABLE_EOF;
DROP TABLE IF EXISTS $group.data_source_item;
CREATE TABLE IF NOT EXISTS $group.data_source_item (
   mailbox_id     INTEGER UNSIGNED NOT NULL,
   data_source_id CHAR(36) NOT NULL,
   item_id        INTEGER UNSIGNED NOT NULL,
   folder_id      INTEGER UNSIGNED NOT NULL DEFAULT 0,
   remote_id      VARCHAR(255) BINARY NOT NULL,
   metadata       MEDIUMTEXT,
   
   PRIMARY KEY (mailbox_id, item_id),
   UNIQUE INDEX i_remote_id (mailbox_id, data_source_id, remote_id),   -- for reverse lookup
   CONSTRAINT fk_data_source_item_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id) ON DELETE CASCADE
) ENGINE = InnoDB;
CREATE_TABLE_EOF

  Migrate::runSql($sql);
}
