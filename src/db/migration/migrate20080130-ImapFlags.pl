#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

Migrate::verifySchemaVersion(50);
foreach my $group (Migrate::getMailboxGroups()) {
    addImapFlagsColumn($group);
}
Migrate::updateSchemaVersion(50, 51);

exit(0);

#####################

sub addImapFlagsColumn($) {
  my ($group) = @_;
  
  Migrate::log("Adding flags column to $group.imap_message.");

  my $sql = <<ALTER_TABLE_EOF;
ALTER TABLE $group.imap_message
ADD COLUMN flags INTEGER NOT NULL DEFAULT 0;

UPDATE $group.imap_message
SET flags = (
  SELECT flags
  FROM $group.mail_item
  WHERE $group.imap_message.item_id = $group.mail_item.id
  AND $group.imap_message.mailbox_id = $group.mail_item.mailbox_id
);

ALTER_TABLE_EOF

  Migrate::runSql($sql);
}
