#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2026 Synacor, Inc.
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
# ZCS-21706: drop the foreign keys from every mboxgroupN table to zimbra.mailbox(id).
#
# On MariaDB > 10.1 every write to zimbra.mailbox walks all foreign keys that reference it
# (MDEV-30182). With 16 tables x N mailbox groups that is ~1,600 FKs, which makes the
# mailbox-row UPDATE done on nearly every mailbox change ~150x slower.
# Mailbox deletion already removes these rows explicitly (DbMailbox.sTables), so the FKs
# are not needed. Intra-group FKs (e.g. revision -> mail_item) and the zimbra.* FKs are kept.
#
# Metadata-only change (no table rebuild). Safe to re-run: uses DROP FOREIGN KEY IF EXISTS.

use strict;
use Migrate;

Migrate::verifySchemaVersion(118);

# table => constraint, as defined in create_database.sql up to schema version 118
my %FKS = (
    'mail_item'            => 'fk_mail_item_mailbox_id',
    'mail_item_dumpster'   => 'fk_mail_item_dumpster_mailbox_id',
    'revision'             => 'fk_revision_mailbox_id',
    'revision_dumpster'    => 'fk_revision_dumpster_mailbox_id',
    'tag'                  => 'fk_tag_mailbox_id',
    'open_conversation'    => 'fk_open_conversation_mailbox_id',
    'appointment'          => 'fk_appointment_mailbox_id',
    'appointment_dumpster' => 'fk_appointment_dumpster_mailbox_id',
    'tombstone'            => 'fk_tombstone_mailbox_id',
    'pop3_message'         => 'fk_pop3_message_mailbox_id',
    'imap_folder'          => 'fk_imap_folder_mailbox_id',
    'imap_message'         => 'fk_imap_message_mailbox_id',
    'data_source_item'     => 'fk_data_source_item_mailbox_id',
    'purged_conversations' => 'fk_purged_conversation_mailbox_id',
    'purged_messages'      => 'fk_purged_message_mailbox_id',
    'event'                => 'fk_event_mailbox_id',
);

my @groups = Migrate::getMailboxGroups();
Migrate::log("Dropping mboxgroup -> zimbra.mailbox foreign keys in " . scalar(@groups) . " mailbox groups.");

foreach my $group (@groups) {
    my $sql = "";
    foreach my $table (sort keys %FKS) {
        $sql .= "ALTER TABLE `$group`.`$table` DROP FOREIGN KEY IF EXISTS `$FKS{$table}`;\n";
    }
    Migrate::runSql($sql, 0);
}

# Safety net: drop any remaining FK from a mailbox group to zimbra.mailbox, whatever its name.
my @left = Migrate::runSql(
    "SELECT CONSTRAINT_SCHEMA, TABLE_NAME, CONSTRAINT_NAME FROM information_schema.REFERENTIAL_CONSTRAINTS " .
    "WHERE CONSTRAINT_SCHEMA LIKE 'mboxgroup%' AND UNIQUE_CONSTRAINT_SCHEMA = 'zimbra' " .
    "AND REFERENCED_TABLE_NAME = 'mailbox';", 0);
foreach my $row (@left) {
    my ($schema, $table, $name) = split(/\t/, $row);
    next unless ($schema && $table && $name);
    Migrate::log("Dropping unexpected foreign key $schema.$table.$name");
    Migrate::runSql("ALTER TABLE `$schema`.`$table` DROP FOREIGN KEY `$name`;", 0);
}

Migrate::updateSchemaVersion(118, 119);

exit(0);
