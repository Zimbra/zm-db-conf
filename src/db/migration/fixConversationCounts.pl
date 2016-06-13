#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2005, 2007, 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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


my @mailboxIds = Migrate::getMailboxIds();
foreach my $id (@mailboxIds) {
    fixConversationCount($id);
}

exit(0);

#####################

sub fixConversationCount($) {
    my ($mailboxId) = @_;
    my $sql = <<EOF;
UPDATE mailbox$mailboxId.mail_item
LEFT JOIN (SELECT parent_id conv, COUNT(*) cnt FROM mailbox$mailboxId.mail_item WHERE type = 5 GROUP BY parent_id) c ON id = conv
SET size = IFNULL(cnt, 0)
WHERE type = 4;

DELETE FROM mailbox$mailboxId.mail_item WHERE type = 4 AND size = 0;

EOF
    
    Migrate::log("Updating SIZE for conversation rows in mailbox$mailboxId.mail_item.");
    Migrate::runSql($sql);
}
