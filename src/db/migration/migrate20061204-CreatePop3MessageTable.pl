#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2006, 2007, 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

Migrate::verifySchemaVersion(32);
foreach my $group (Migrate::getMailboxGroups()) {
    createPop3MessageTable($group);
}
Migrate::updateSchemaVersion(32, 33);

exit(0);

#####################

sub createPop3MessageTable($) {
  my ($group) = @_;

  my $sql = <<CREATE_TABLE_EOF;
CREATE TABLE IF NOT EXISTS $group.pop3_message (
   mailbox_id     INTEGER UNSIGNED NOT NULL,
   data_source_id CHAR(36) NOT NULL,
   uid            VARCHAR(255) NOT NULL,
   item_id        INTEGER UNSIGNED NOT NULL,
   
   PRIMARY KEY (mailbox_id, item_id),
   CONSTRAINT fk_pop3_message_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id)
) ENGINE = InnoDB;

CREATE UNIQUE INDEX i_uid_pop3_id ON $group.pop3_message (uid, data_source_id);
CREATE_TABLE_EOF

  Migrate::runSql($sql);
}
