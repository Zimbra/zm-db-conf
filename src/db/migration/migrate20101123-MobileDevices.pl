#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2010, 2011, 2013, 2014, 2016 Synacor, Inc.
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

Migrate::verifySchemaVersion(65);

addLastUsedDateColumn();

Migrate::updateSchemaVersion(65, 80);

exit(0);

#####################

sub addLastUsedDateColumn() {
    my $sql = <<MOBILE_DEVICES_ADD_COLUMN_EOF;
ALTER TABLE mobile_devices ADD COLUMN last_used_date DATE;
ALTER TABLE mobile_devices ADD COLUMN deleted_by_user BOOLEAN NOT NULL DEFAULT 0 AFTER last_used_date;
ALTER TABLE mobile_devices ADD INDEX i_last_used_date (last_used_date);
MOBILE_DEVICES_ADD_COLUMN_EOF
    
    Migrate::log("Adding last_used_date and deleted_by_user column to ZIMBRA.MOBILE_DEVICES table.");
    Migrate::runSql($sql);
}
