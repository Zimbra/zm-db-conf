#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2022 Synacor, Inc.
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
use DBI;
use strict;
use Migrate;

# Verify Schema Version Number
Migrate::verifySchemaVersion(114);

addTimestampColumn();

# Update Schema Version Number
Migrate::updateSchemaVersion(114, 115);

exit(0);

# Function to add 'timestamp' column to mobile_devices table that is auto updating
sub addTimestampColumn() {
    my $sql = <<MDM_ADD_COLUMN_EOF;
ALTER TABLE mobile_devices ADD COLUMN IF NOT EXISTS update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;
MDM_ADD_COLUMN_EOF

    Migrate::log("Adding timestamp column to zimbra.mobile_devices table.");
    Migrate::runSql($sql);
}