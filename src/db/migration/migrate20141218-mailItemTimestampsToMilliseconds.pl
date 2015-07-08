#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2005, 2007, 2008, 2009, 2010, 2013, 2014 Zimbra, Inc.
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
my $concurrent = 4;
Migrate::verifySchemaVersion(106);
migrateDateColumns();
convertToMilliseconds();
Migrate::updateSchemaVersion(106, 120);
exit(0);

#####################

sub migrateDateColumns($) {
    my @sqls = ();
	my @tables = ('mail_item', 'mail_item_dumpster', 'revision', 'revision_dumpster');
    foreach my $group (Migrate::getMailboxGroups()) {
        foreach my $table (@tables) {
            my $sql = <<EOF;
ALTER TABLE $group.$table CHANGE date date BIGINT UNSIGNED NOT NULL, CHANGE change_date change_date BIGINT UNSIGNED;
EOF
            push(@sqls, $sql);
        }
        my $tombstone = <<EOF;
ALTER TABLE $group.tombstone CHANGE date date BIGINT UNSIGNED NOT NULL;
EOF
        push(@sqls, $tombstone);
	}
    Migrate::log("changing date and change_date columns to BIGINT");
    Migrate::runSqlParallel($concurrent, @sqls);
}

sub convertToMilliseconds($) {
    my @sqls = ();
	my @tables = ('mail_item', 'mail_item_dumpster', 'revision', 'revision_dumpster');
    foreach my $group (Migrate::getMailboxGroups()) {
        foreach my $table (@tables) {
    my $sql = <<EOF;
UPDATE $group.$table SET date=date*1000, change_date=change_date*1000;
EOF
            push(@sqls, $sql);
        }
        my $tombstone = <<EOF;
UPDATE $group.tombstone SET date=date*1000;
EOF
        push(@sqls, $tombstone);
	}
    Migrate::log("converting seconds to milliseconds");
    Migrate::runSqlParallel($concurrent, @sqls);
}