#!/usr/bin/perl

# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

#
# Remove "4:rsvp5:false" from metadata of every appointment and task.
# (bug 26472)
#

use strict;
use Migrate;

sub bumpUpMailboxChangeCheckpoints();
sub setRsvpTrue($);

my $CONCURRENCY = 10;
my $NOW = time();
my $RSVP_FALSE_METADATA_PATTERN = '4:rsvp5:false';

bumpUpMailboxChangeCheckpoints();

my @groups = Migrate::getMailboxGroups();
my @sqlMetadataUpdate;
foreach my $groupdb (@groups) {
    my $sql = setRsvpTrue($groupdb);
    push(@sqlMetadataUpdate, $sql);
    print "$sql\n";
}
Migrate::runSqlParallel($CONCURRENCY, @sqlMetadataUpdate);

exit(0);


#####################


# Increment change_checkpoint column for all rows in mailbox table.
# This SQL must be executed immediately rather than queued.
sub bumpUpMailboxChangeCheckpoints() {
    my $sql =<<_SQL_;
UPDATE mailbox
SET change_checkpoint = change_checkpoint + 100;
_SQL_
    Migrate::runSql($sql);
}

# Remove the part of metadata that corresponds to rsvp=false.
sub setRsvpTrue($) {
    my $groupdb = shift;
    my $sql = <<_SQL_;
UPDATE $groupdb.mail_item mi, mailbox mb
SET
    mi.metadata = REPLACE(metadata, '$RSVP_FALSE_METADATA_PATTERN', ''),
    mi.mod_metadata = mb.change_checkpoint,
    mi.change_date = $NOW
WHERE
    mi.type IN (11, 15) AND
    mi.metadata LIKE '\%$RSVP_FALSE_METADATA_PATTERN\%' AND
    mb.id = mi.mailbox_id
_SQL_
    return $sql;
}
