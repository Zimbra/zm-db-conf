#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2006, 2007, 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

Migrate::verifySchemaVersion(24);

my @mailboxIds = Migrate::getMailboxIds();
foreach my $id (@mailboxIds) {
    setCheckedCalendarFlag($id);
}

Migrate::updateSchemaVersion(24, 25);

exit(0);

#####################

sub setCheckedCalendarFlag($) {
    my ($mailboxId) = @_;
    my $sql = <<EOF_SET_CHECKED_CALENDAR_FLAG;
    
UPDATE mailbox$mailboxId.mail_item mi, zimbra.mailbox mbx
SET flags = flags | 2097152,
    mod_metadata = change_checkpoint + 100,
    change_checkpoint = change_checkpoint + 200
WHERE mi.id = 10 AND mbx.id = $mailboxId;

EOF_SET_CHECKED_CALENDAR_FLAG
    Migrate::runSql($sql);
}
