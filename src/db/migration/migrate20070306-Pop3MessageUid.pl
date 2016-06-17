#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2007, 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

Migrate::verifySchemaVersion(36);
foreach my $group (Migrate::getMailboxGroups()) {
    modifyPop3MessageSchema($group);
}
Migrate::updateSchemaVersion(36, 37);

exit(0);

#####################

sub modifyPop3MessageSchema($) {
  my ($group) = @_;

  my $sql = <<MODIFY_POP3_MESSAGE_SCHEMA_EOF;
ALTER TABLE $group.pop3_message
CHANGE uid uid VARCHAR(255) BINARY NOT NULL;
MODIFY_POP3_MESSAGE_SCHEMA_EOF

  Migrate::runSql($sql);
}
