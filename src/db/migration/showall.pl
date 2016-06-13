#!/usr/bin/perl -w
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

# Prints the output of SHOW CREATE TABLE for all zimbra databases

use strict;
use Migrate;

my @databases = Migrate::runSql("SHOW DATABASES;", 0);
foreach my $database (@databases) {
    $database = lc($database);
    if ($database eq "zimbra" || $database =~ /^mailbox[0-9]+$/) {
	print("Database $database:\n");
	my @tables = Migrate::runSql("SHOW TABLES FROM $database;", 0);
	foreach my $table (@tables) {
	    my $row = (Migrate::runSql("SHOW CREATE TABLE $database.$table;", 0))[0];
	    my $create = (split("\t", $row))[1];
	    $create =~ s/\\n/\n/g;
	    print("\n" . $create . "\n");
	}
    }
}
