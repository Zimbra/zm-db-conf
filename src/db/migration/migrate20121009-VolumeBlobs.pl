#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2012, 2013, 2014, 2016 Synacor, Inc.
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

########################################################################################################################

Migrate::verifySchemaVersion(91);

addVolumeBlobsTable();
addVolumeMetadataColumn();

Migrate::updateSchemaVersion(91, 92);

exit(0);

########################################################################################################################

sub addVolumeBlobsTable() {
    Migrate::logSql("Adding VOLUME_BLOBS table...");
    my $sql = <<_EOF_;
CREATE TABLE IF NOT EXISTS volume_blobs (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  volume_id TINYINT NOT NULL,
  mailbox_id INTEGER NOT NULL,
  item_id INTEGER NOT NULL,
  revision INTEGER NOT NULL,
  blob_digest VARCHAR(44),
  processed BOOLEAN default false,
  
  INDEX i_blob_digest (blob_digest),

  CONSTRAINT uc_blobinfo UNIQUE (volume_id,mailbox_id,item_id,revision)
) ENGINE = InnoDB;
_EOF_
  Migrate::runSql($sql);
}

sub addVolumeMetadataColumn() {
    Migrate::logSql("Adding METADATA column to VOLUME...");
    my $sql = <<_EOF_;
ALTER TABLE volume ADD COLUMN metadata MEDIUMTEXT AFTER compression_threshold;
_EOF_
  Migrate::runSql($sql);
}

