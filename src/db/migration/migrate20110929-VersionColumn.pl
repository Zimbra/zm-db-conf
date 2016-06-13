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

Migrate::verifySchemaVersion(85);

addVersionColumn();

Migrate::updateSchemaVersion(85, 86);

exit(0);

#####################

sub addVersionColumn() {
    my $sql = <<MAILBOX_ADD_COLUMN_EOF;
ALTER TABLE mailbox ADD COLUMN version VARCHAR(16);
MAILBOX_ADD_COLUMN_EOF
    
    Migrate::log("Adding version column to ZIMBRA.MAILBOX table.");
    Migrate::runSql($sql);
}
