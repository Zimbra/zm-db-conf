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


use strict;
use Migrate;
my $concurrent = 10;

sub usage() {
	print STDERR "Usage: migrateLargeMetadata.pl [-a]\n";
	print STDERR "-a: migrate all groups without prompting\n";
	exit(1);
}

my $allGroups = 0;
my $opt = $ARGV[0];
if (defined($opt)) {
	if ($opt eq '-a') {
		$allGroups = 1;
	} else {
		usage();
	}
}

my @groups = Migrate::getMailboxGroups();
my $sqlGroupsWithSmallMetadata = <<_SQL_;
SELECT table_schema FROM information_schema.columns
WHERE table_name = 'mail_item' AND column_name = 'metadata' AND data_type = 'text'
ORDER BY table_schema;
_SQL_
my @groupsToMigrate = Migrate::runSql($sqlGroupsWithSmallMetadata);

my $total = scalar(@groups);
my $totalToMigrate = scalar(@groupsToMigrate);
if ($totalToMigrate < 1) {
	print "No mailbox group needs to be migrated.\n";
	exit(0);
}
print "$totalToMigrate out of $total mailbox groups need to be migrated.\n";

my $toMigrate;
if ($allGroups) {
	$toMigrate = $totalToMigrate;
} else {
	my $num = 0;
	while ($num < 1 || $num > $totalToMigrate) {
		print "Enter number of groups to migrate (1 - $totalToMigrate): ";
		$num = <STDIN>;
		chomp($num);
		$num += 0;
	}
	$toMigrate = $num;
}
print "Migrating $toMigrate out of $totalToMigrate mailbox groups\n";

my $migrated = 0;
my @sql = ();
foreach my $group (@groupsToMigrate) {
	last if ($migrated >= $toMigrate);
	print "migrating $group\n";
    my $sql = <<_SQL_;
ALTER TABLE $group.mail_item MODIFY COLUMN metadata MEDIUMTEXT;
_SQL_
    push(@sql, $sql);
    $migrated++;
}
my $start = time();
Migrate::runSqlParallel($concurrent, @sql);
my $elapsed = time() - $start;
print "\nMigrated $toMigrate mailbox groups in $elapsed seconds\n";

exit(0);
