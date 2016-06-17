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

Migrate::verifySchemaVersion(84);

addApplListColumns();

Migrate::updateSchemaVersion(84, 85);

exit(0);

#####################

sub addApplListColumns() {
    my $sql = <<MOBILE_DEVICES_ADD_COLUMN_EOF;
ALTER TABLE mobile_devices ADD COLUMN unapproved_appl_list TEXT NULL;
ALTER TABLE mobile_devices ADD COLUMN approved_appl_list TEXT NULL;
MOBILE_DEVICES_ADD_COLUMN_EOF
    
    Migrate::log("Adding unapproved_appl_list and approved_appl_list column to ZIMBRA.MOBILE_DEVICES table.");
    Migrate::runSql($sql);
}
