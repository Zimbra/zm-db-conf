#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2005, 2007, 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

sub secondaryMessageVolume() {
	my $sql = <<END_OF_SQL;
ALTER TABLE volume DISABLE KEYS;
ALTER TABLE volume ADD COLUMN type TINYINT NOT NULL AFTER id;
UPDATE volume SET type=1 WHERE name NOT LIKE '%index%';
UPDATE volume SET type=10 WHERE name LIKE '%index%';
ALTER TABLE volume ENABLE KEYS;

ALTER TABLE current_volumes ADD COLUMN secondary_message_volume_id INTEGER UNSIGNED AFTER message_volume_id;
ALTER TABLE current_volumes ADD INDEX i_secondary_message_volume_id (secondary_message_volume_id);
ALTER TABLE current_volumes ADD CONSTRAINT
    fk_current_volumes_secondary_message_volume_id
    FOREIGN KEY (secondary_message_volume_id)
    REFERENCES volume(id);
END_OF_SQL
    Migrate::log("Removing MESSAGE_VOLUME_ID colume from zimbra.mailbox table");
    Migrate::runSql($sql);
}


#
# Main
#

my @mailboxIds = Migrate::getMailboxIds();

Migrate::verifySchemaVersion(17);
secondaryMessageVolume();
Migrate::updateSchemaVersion(17, 18);

exit(0);
