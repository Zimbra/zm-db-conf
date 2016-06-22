#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2011, 2013, 2014, 2016 Synacor, Inc.
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

Migrate::verifySchemaVersion(80);

addDeviceInformationColumns();

Migrate::updateSchemaVersion(80, 81);

exit(0);

#####################

sub addDeviceInformationColumns() {
    my $sql = <<MOBILE_DEVICES_ADD_COLUMN_EOF;
ALTER TABLE mobile_devices ADD COLUMN model VARCHAR(64);
ALTER TABLE mobile_devices ADD COLUMN imei VARCHAR(64);
ALTER TABLE mobile_devices ADD COLUMN friendly_name VARCHAR(512);
ALTER TABLE mobile_devices ADD COLUMN os VARCHAR(64);
ALTER TABLE mobile_devices ADD COLUMN os_language VARCHAR(64);
ALTER TABLE mobile_devices ADD COLUMN phone_number VARCHAR(64);
MOBILE_DEVICES_ADD_COLUMN_EOF
    
    Migrate::log("Adding device information columns to ZIMBRA.MOBILE_DEVICES table.");
    Migrate::runSql($sql);
}
