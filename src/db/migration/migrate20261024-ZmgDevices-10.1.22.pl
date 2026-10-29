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
# ZCS-20929: re-key zmg_devices on (mailbox_id, device_id) and add the device
# token lifecycle columns. Every step checks the current table shape first, so
# re-running after a partial failure picks up where it stopped.
#
use strict;
use Migrate;

my $TABLE = "zmg_devices";

# Secondary indexes of the 106 -> 107 table, dropped here. MariaDB may name the
# reg_id unique key after its constraint symbol or after the column.
my %LEGACY_INDEXES = map { $_ => 1 } qw(uk_zmg_reg_id reg_id i_mailbox_id i_reg_id);
my %TARGET_INDEXES = map { $_ => 1 } qw(PRIMARY uk_zmg_id uk_zmg_mbox_reg_id i_zmg_device_id i_zmg_reg_id_hash i_zmg_last_seen_at);

# Verify Schema Version Number
Migrate::verifySchemaVersion(119);

if (tableExists()) {
    verifyKnownIndexes();
    addColumns();
    dropLegacyKeys();
    backfillLegacyRows();
    alignColumns();
    addKeys();
} else {
    createTable();
}
verifyTable();

# Update Schema Version Number
Migrate::updateSchemaVersion(119, 120);

exit(0);

sub queryValue($) {
    my ($sql) = @_;
    my @rows = Migrate::runSql($sql);
    return $rows[0];
}

sub tableExists() {
    return queryValue("SELECT COUNT(*) FROM information_schema.TABLES " .
        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '$TABLE';") > 0;
}

sub columnExists($) {
    my ($column) = @_;
    return queryValue("SELECT COUNT(*) FROM information_schema.COLUMNS " .
        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '$TABLE' AND COLUMN_NAME = '$column';") > 0;
}

sub indexNames() {
    return Migrate::runSql("SELECT DISTINCT INDEX_NAME FROM information_schema.STATISTICS " .
        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '$TABLE';");
}

sub indexExists($) {
    my ($index) = @_;
    return grep { $_ eq $index } indexNames();
}

sub foreignKeyNames() {
    return Migrate::runSql("SELECT CONSTRAINT_NAME FROM information_schema.TABLE_CONSTRAINTS " .
        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '$TABLE' AND CONSTRAINT_TYPE = 'FOREIGN KEY';");
}

sub primaryKeyColumns() {
    my $columns = queryValue("SELECT GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) FROM information_schema.STATISTICS " .
        "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '$TABLE' AND INDEX_NAME = 'PRIMARY';");
    return (!defined($columns) || $columns eq 'NULL') ? '' : $columns;
}

# Refuse to touch a table carrying keys this migration does not know about.
sub verifyKnownIndexes() {
    my @unknown = grep { !$LEGACY_INDEXES{$_} && !$TARGET_INDEXES{$_} } indexNames();
    Migrate::myquit(1, "Unexpected index(es) on $TABLE: @unknown. Aborting migration.\n") if (@unknown);

    @unknown = grep { $_ ne 'fk_zmg_mailbox_id' } foreignKeyNames();
    Migrate::myquit(1, "Unexpected foreign key(s) on $TABLE: @unknown. Aborting migration.\n") if (@unknown);

    my $pk = primaryKeyColumns();
    Migrate::myquit(1, "Unexpected primary key ($pk) on $TABLE. Aborting migration.\n")
        unless ($pk eq '' || $pk eq 'mailbox_id,app_id' || $pk eq 'mailbox_id,reg_id' || $pk eq 'mailbox_id,device_id');
}

# New columns go in nullable so existing rows can be backfilled first.
sub addColumns() {
    my $sql = <<ZMG_ADD_COLUMNS_EOF;
ALTER TABLE $TABLE
  ADD COLUMN IF NOT EXISTS id BIGINT NOT NULL AUTO_INCREMENT FIRST,
  ADD UNIQUE KEY IF NOT EXISTS uk_zmg_id (id),
  ADD COLUMN IF NOT EXISTS device_id VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
  ADD COLUMN IF NOT EXISTS device_type VARCHAR(16) NULL,
  ADD COLUMN IF NOT EXISTS app_version VARCHAR(32) NULL,
  ADD COLUMN IF NOT EXISTS reg_id_hash BINARY(32) NULL,
  ADD COLUMN IF NOT EXISTS reg_id_updated_at INTEGER UNSIGNED NULL,
  ADD COLUMN IF NOT EXISTS created_at INTEGER UNSIGNED NULL,
  ADD COLUMN IF NOT EXISTS updated_at INTEGER UNSIGNED NULL,
  ADD COLUMN IF NOT EXISTS last_seen_at INTEGER UNSIGNED NULL;
ZMG_ADD_COLUMNS_EOF

    Migrate::log("Adding device token lifecycle columns to $TABLE.");
    Migrate::runSql($sql);
}

# Runs after the old (mailbox_id, app_id) primary key is gone, since resetting
# app_id would collide on it. The old app_id column held the app version. Only rows not yet backfilled
# (device_id IS NULL) are touched, and assignments run left to right, so
# app_version receives the old app_id before app_id is reset.
sub backfillLegacyRows() {
    my $sql = <<ZMG_BACKFILL_EOF;
UPDATE $TABLE SET
  app_version       = LEFT(app_id, 32),
  app_id            = 'unknown',
  reg_id_hash       = UNHEX(SHA2(reg_id, 256)),
  device_id         = CONCAT('legacy-', LEFT(SHA2(reg_id, 256), 56)),
  device_type       = 'MOBILE',
  os_name           = COALESCE(NULLIF(TRIM(os_name), ''), 'UNKNOWN'),
  push_provider     = COALESCE(NULLIF(TRIM(push_provider), ''), 'FCM'),
  reg_id_updated_at = UNIX_TIMESTAMP(),
  created_at        = UNIX_TIMESTAMP(),
  updated_at        = UNIX_TIMESTAMP(),
  last_seen_at      = UNIX_TIMESTAMP()
WHERE device_id IS NULL;
ZMG_BACKFILL_EOF

    Migrate::log("Backfilling legacy rows in $TABLE.");
    Migrate::runSql($sql);
}

# The foreign key goes first, since it relies on the indexes dropped after it.
sub dropLegacyKeys() {
    if (grep { $_ eq 'fk_zmg_mailbox_id' } foreignKeyNames()) {
        if (primaryKeyColumns() ne 'mailbox_id,device_id') {
            Migrate::log("Dropping foreign key fk_zmg_mailbox_id from $TABLE.");
            Migrate::runSql("ALTER TABLE $TABLE DROP FOREIGN KEY fk_zmg_mailbox_id;");
        }
    }

    my $legacyPk = primaryKeyColumns();
    if ($legacyPk eq 'mailbox_id,app_id' || $legacyPk eq 'mailbox_id,reg_id') {
        Migrate::log("Dropping primary key ($legacyPk) from $TABLE.");
        Migrate::runSql("ALTER TABLE $TABLE DROP PRIMARY KEY;");
    }

    foreach my $index (grep { $LEGACY_INDEXES{$_} } indexNames()) {
        Migrate::log("Dropping index $index from $TABLE.");
        Migrate::runSql("ALTER TABLE $TABLE DROP INDEX $index;");
    }

    if (columnExists('max_payload_size')) {
        Migrate::log("Dropping column max_payload_size from $TABLE.");
        Migrate::runSql("ALTER TABLE $TABLE DROP COLUMN max_payload_size;");
    }
}

# Final types, nullability and column order, matching db.sql.
sub alignColumns() {
    my $sql = <<ZMG_ALIGN_COLUMNS_EOF;
ALTER TABLE $TABLE
  MODIFY COLUMN id BIGINT NOT NULL AUTO_INCREMENT FIRST,
  MODIFY COLUMN mailbox_id INTEGER UNSIGNED NOT NULL AFTER id,
  MODIFY COLUMN device_id VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL AFTER mailbox_id,
  MODIFY COLUMN device_type VARCHAR(16) NOT NULL DEFAULT 'MOBILE' AFTER device_id,
  MODIFY COLUMN app_id VARCHAR(64) NOT NULL AFTER device_type,
  MODIFY COLUMN app_version VARCHAR(32) AFTER app_id,
  MODIFY COLUMN os_name VARCHAR(16) NOT NULL DEFAULT 'UNKNOWN' AFTER app_version,
  MODIFY COLUMN os_version VARCHAR(32) AFTER os_name,
  MODIFY COLUMN push_provider VARCHAR(16) NOT NULL DEFAULT 'FCM' AFTER os_version,
  MODIFY COLUMN reg_id VARCHAR(1024) CHARACTER SET ascii COLLATE ascii_bin NOT NULL AFTER push_provider,
  MODIFY COLUMN reg_id_hash BINARY(32) NOT NULL AFTER reg_id,
  MODIFY COLUMN reg_id_updated_at INTEGER UNSIGNED NOT NULL AFTER reg_id_hash,
  MODIFY COLUMN created_at INTEGER UNSIGNED NOT NULL AFTER reg_id_updated_at,
  MODIFY COLUMN updated_at INTEGER UNSIGNED NOT NULL AFTER created_at,
  MODIFY COLUMN last_seen_at INTEGER UNSIGNED AFTER updated_at;
ZMG_ALIGN_COLUMNS_EOF

    Migrate::log("Aligning column definitions of $TABLE.");
    Migrate::runSql($sql);
}

sub addKeys() {
    if (primaryKeyColumns() eq '') {
        Migrate::log("Adding primary key (mailbox_id, device_id) to $TABLE.");
        Migrate::runSql("ALTER TABLE $TABLE ADD PRIMARY KEY (mailbox_id, device_id);");
    }
    my $sql = <<ZMG_ADD_KEYS_EOF;
ALTER TABLE $TABLE
  ADD UNIQUE KEY IF NOT EXISTS uk_zmg_mbox_reg_id (mailbox_id, reg_id_hash),
  ADD INDEX IF NOT EXISTS i_zmg_device_id (device_id),
  ADD INDEX IF NOT EXISTS i_zmg_reg_id_hash (reg_id_hash),
  ADD INDEX IF NOT EXISTS i_zmg_last_seen_at (last_seen_at);
ZMG_ADD_KEYS_EOF

    Migrate::log("Adding indexes to $TABLE.");
    Migrate::runSql($sql);

    unless (grep { $_ eq 'fk_zmg_mailbox_id' } foreignKeyNames()) {
        Migrate::log("Adding foreign key fk_zmg_mailbox_id to $TABLE.");
        Migrate::runSql("ALTER TABLE $TABLE ADD CONSTRAINT fk_zmg_mailbox_id " .
            "FOREIGN KEY (mailbox_id) REFERENCES mailbox(id) ON DELETE CASCADE;");
    }
}

sub createTable() {
    my $sql = <<ZMG_CREATE_TABLE_EOF;
CREATE TABLE IF NOT EXISTS $TABLE (
   id                 BIGINT NOT NULL AUTO_INCREMENT,
   mailbox_id         INTEGER UNSIGNED NOT NULL,
   device_id          VARCHAR(64)   CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
   device_type        VARCHAR(16)   NOT NULL DEFAULT 'MOBILE',
   app_id             VARCHAR(64)   NOT NULL,
   app_version        VARCHAR(32),
   os_name            VARCHAR(16)   NOT NULL DEFAULT 'UNKNOWN',
   os_version         VARCHAR(32),
   push_provider      VARCHAR(16)   NOT NULL DEFAULT 'FCM',
   reg_id             VARCHAR(1024) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
   reg_id_hash        BINARY(32)    NOT NULL,
   reg_id_updated_at  INTEGER UNSIGNED NOT NULL,
   created_at         INTEGER UNSIGNED NOT NULL,
   updated_at         INTEGER UNSIGNED NOT NULL,
   last_seen_at       INTEGER UNSIGNED,

   PRIMARY KEY (mailbox_id, device_id),
   UNIQUE KEY uk_zmg_id (id),
   UNIQUE KEY uk_zmg_mbox_reg_id (mailbox_id, reg_id_hash),
   CONSTRAINT fk_zmg_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES mailbox(id) ON DELETE CASCADE,
   INDEX i_zmg_device_id (device_id),
   INDEX i_zmg_reg_id_hash (reg_id_hash),
   INDEX i_zmg_last_seen_at (last_seen_at)
) ENGINE = InnoDB;
ZMG_CREATE_TABLE_EOF

    Migrate::log("Creating table $TABLE.");
    Migrate::runSql($sql);
}

sub verifyTable() {
    my $pk = primaryKeyColumns();
    Migrate::myquit(1, "$TABLE primary key is ($pk), expected (mailbox_id, device_id).\n")
      unless ($pk eq 'mailbox_id,device_id');
    foreach my $index (keys %TARGET_INDEXES) {
        Migrate::myquit(1, "$TABLE is missing index $index.\n") unless (indexExists($index));
    }
    Migrate::myquit(1, "$TABLE is missing foreign key fk_zmg_mailbox_id.\n")
      unless (grep { $_ eq 'fk_zmg_mailbox_id' } foreignKeyNames());
    Migrate::myquit(1, "$TABLE still has column max_payload_size.\n") if (columnExists('max_payload_size'));
}