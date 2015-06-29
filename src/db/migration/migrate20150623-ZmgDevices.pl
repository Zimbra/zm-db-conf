#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2011, 2013, 2014 Zimbra, Inc.
# 
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.
# ***** END LICENSE BLOCK *****
# 


use strict;
use Migrate;

Migrate::verifySchemaVersion(105);

addDeviceInformationColumns();

Migrate::updateSchemaVersion(105, 106);

exit(0);

#####################

sub addDeviceInformationColumns() {
    my $sql = <<ZMG_DEVICES_ADD_COLUMN_EOF;
ALTER TABLE zmg_devices ADD COLUMN os_name VARCHAR(16);
ALTER TABLE zmg_devices ADD COLUMN os_version VARCHAR(8);
ALTER TABLE zmg_devices ADD COLUMN max_payload_size INTEGER UNSIGNED;
ZMG_DEVICES_ADD_COLUMN_EOF
    
    Migrate::log("Adding OS information columns to ZIMBRA.ZMG_DEVICES table.");
    Migrate::runSql($sql);
}
