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

Migrate::verifySchemaVersion(22);

my @mailboxIds = Migrate::getMailboxIds();
addImapSyncColumn();
foreach my $id (@mailboxIds) {
    addImapIdColumn($id);
}

Migrate::updateSchemaVersion(22, 23);

exit(0);

#############

sub addImapSyncColumn()
{
    my $sql = <<ADD_TRACKING_IMAP_COLUMN_EOF;
ALTER TABLE zimbra.mailbox
MODIFY tracking_sync INTEGER UNSIGNED NOT NULL DEFAULT 0;

ALTER TABLE zimbra.mailbox
ADD COLUMN tracking_imap BOOLEAN NOT NULL DEFAULT 0 AFTER tracking_sync;

ADD_TRACKING_IMAP_COLUMN_EOF

    Migrate::log("Adding zimbra.mailbox.tracking_imap.");
    Migrate::runSql($sql);
}

sub addImapIdColumn($)
{
    my ($mailboxId) = @_;
    my $dbName = "mailbox" . $mailboxId;
	
    my $sql = <<ADD_IMAP_ID_COLUMN_EOF;
ALTER TABLE $dbName.mail_item
ADD COLUMN imap_id INTEGER UNSIGNED AFTER folder_id;

UPDATE $dbName.mail_item
SET imap_id = id WHERE type IN (5, 6, 8, 11, 14);

ADD_IMAP_ID_COLUMN_EOF

    Migrate::log("Adding and setting $dbName.mail_item.imap_id.");
    Migrate::runSql($sql);
}

