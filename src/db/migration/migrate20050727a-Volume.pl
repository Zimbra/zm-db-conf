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

#############

my $MYSQL = "mysql";
my $DB_USER = "liquid";
my $DB_PASSWORD = "liquid";
my $DATABASE = "liquid";

if (-f "/opt/liquid/bin/lqlocalconfig") {
    $DB_PASSWORD = `lqlocalconfig -s -m nokey liquid_mysql_password`;
    chomp $DB_PASSWORD;
    $DB_USER = `lqlocalconfig -m nokey liquid_mysql_user`;
    chomp $DB_USER;
}

#############

updateSchemaVersion(11);
updateVolume();

exit(0);

#############

sub updateSchemaVersion($)
{
    my ($dbVersion) = @_;
    if (!defined($dbVersion)) {
	print("dbVersion not specified.\n");
	exit(1);
    }

    my $sql = <<SET_SCHEMA_VERSION_EOF;

UPDATE $DATABASE.config SET value = '$dbVersion' WHERE name = 'db.version';

SET_SCHEMA_VERSION_EOF

    printLog("Updating DB schema version to $dbVersion.");
    runSql($sql);
}

sub updateVolume()
{
    my $sql = <<EOF;

ALTER TABLE volume
ADD COLUMN file_bits SMALLINT NOT NULL,
ADD COLUMN file_group_bits SMALLINT NOT NULL,
ADD COLUMN mailbox_bits SMALLINT NOT NULL,
ADD COLUMN mailbox_group_bits SMALLINT NOT NULL;

UPDATE volume
SET file_bits = (
  SELECT value
  FROM config
  WHERE name = 'store.filePath.fileBits'
);

UPDATE volume
SET file_group_bits = (
  SELECT value
  FROM config
  WHERE name = 'store.filePath.groupBits'
);

UPDATE volume
SET mailbox_bits = (
  SELECT value
  FROM config
  WHERE name = 'store.mailboxPath.mailboxBits'
);

UPDATE volume
SET mailbox_group_bits = (
  SELECT value
  FROM config
  WHERE name = 'store.mailboxPath.groupBits'
);

DELETE FROM config
WHERE name LIKE 'store%Bits';

EOF

    printLog("Updating volume and config tables.");
    runSql($sql);
}

#############

sub runSql($$$)
{
    my ($script) = @_;

    # Write the last script to a text file for debugging
    # open(LASTSCRIPT, ">lastScript.sql") || die "Could not open lastScript.sql";
    # print(LASTSCRIPT $script);
    # close(LASTSCRIPT);

    # Run the mysql command and redirect output to a temp file
    my $tempFile = "mysql.out";
    my $command = "$MYSQL --user=$DB_USER --password=$DB_PASSWORD " .
        "--database=$DATABASE --batch --skip-column-names";
    open(MYSQL, "| $command > $tempFile") || die "Unable to run $command";
    print(MYSQL $script);
    close(MYSQL);

    if ($? != 0) {
        die "Error while running '$command'.";
    }

    # Process output
    open(OUTPUT, $tempFile) || die "Could not open $tempFile";
    my @output;
    while (<OUTPUT>) {
        s/\s+$//;
        push(@output, $_);
    }

    unlink($tempFile);
    return @output;
}

sub printLog
{
    print scalar(localtime()), ": ", @_, "\n";
}
