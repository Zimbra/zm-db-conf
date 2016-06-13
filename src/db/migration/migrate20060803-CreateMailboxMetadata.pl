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

Migrate::verifySchemaVersion(25);

addMailboxMetadataTable();
removeConfigColumn();

Migrate::updateSchemaVersion(25, 26);

exit(0);

#####################

sub addMailboxMetadataTable() {
    my $sql = <<CREATE_MAILBOX_METADATA_EOF;
CREATE TABLE zimbra.mailbox_metadata (
   mailbox_id  INTEGER UNSIGNED NOT NULL,
   section     VARCHAR(64) NOT NULL,       # e.g. "imap"
   metadata    MEDIUMTEXT,

   PRIMARY KEY (mailbox_id, section),

   CONSTRAINT fk_metadata_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES mailbox(id) ON DELETE CASCADE
) ENGINE = InnoDB;

CREATE_MAILBOX_METADATA_EOF
    
    Migrate::log("Adding ZIMBRA.MAILBOX_METADATA table.");
    Migrate::runSql($sql);
}

sub removeConfigColumn() {
    my $sql = <<REMOVE_CONFIG_EOF;
ALTER TABLE zimbra.mailbox
DROP COLUMN config;

REMOVE_CONFIG_EOF
    
    Migrate::log("Removing CONFIG column from ZIMBRA.MAILBOX.");
    Migrate::runSql($sql);
}
