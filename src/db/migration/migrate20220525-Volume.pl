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

use DBI;
use strict;
use Migrate;

my $DB_SOCKET;
my $MYSQL = "mysql";
my $DB_USER = "zimbra";
my $DATABASE = "zimbra";
my $DB_PASSWORD = "zimbra";
my $ZMLOCALCONFIG = "/opt/zimbra/bin/zmlocalconfig";
my $PREFIX = "/S3-";

if ($^O !~ /MSWin/i) {
    $DB_PASSWORD = `$ZMLOCALCONFIG -s -m nokey zimbra_mysql_password`;
    chomp $DB_PASSWORD;
    $DB_USER = `$ZMLOCALCONFIG -m nokey zimbra_mysql_user`;
    chomp $DB_USER;
    $MYSQL = "/opt/zimbra/bin/mysql";
    $DB_SOCKET = `$ZMLOCALCONFIG -x -s -m nokey mysql_socket`;
    chomp $DB_SOCKET;
}

# Verify Schema Version Number
Migrate::verifySchemaVersion(111);

addStoreTypeColumn();
updateStoreTypeColumn();

# Update Schema Version Number
Migrate::updateSchemaVersion(111, 112);

exit(0);

# Function to add 'store_type' column
sub addStoreTypeColumn() {
    my $sql = <<VOLUME_ADD_COLUMN_EOF;
ALTER TABLE volume ADD COLUMN IF NOT EXISTS store_type TINYINT NOT NULL DEFAULT '1' COMMENT '1 for onstore and 2 for s3 bucket';
VOLUME_ADD_COLUMN_EOF

    Migrate::log("Adding store_type column to zimbra.volume table.");
    Migrate::runSql($sql);
}

# Function to check the path of added volume contains 'S3-' or not
sub updateStoreTypeColumn() {

    # define datasource and connect to database
    my $data_source = "dbi:mysql:database=$DATABASE;mysql_read_default_file=/opt/zimbra/conf/my.cnf;mysql_socket=$DB_SOCKET";
    my $dbh;
    until ($dbh) {
        $dbh = DBI->connect($data_source, $DB_USER, $DB_PASSWORD, { PrintError => 0 }); 
        sleep 1;
    }

    # prepare and execute query
    my $sql = "SELECT path FROM volume";
    my $sth = $dbh->prepare ($sql);
    $sth->execute();

    # print 'path' column from table volume
    while(my @row = $sth->fetchrow_array()) {
       printf("%s\t\n",$row[0]);
       my $varBool = $PREFIX eq substr($row[0],0,length($PREFIX));
       # printf(" --> do drive starts with prefix ? [%s]\n",$varBool);

        if($varBool eq 1)
        {
            # Migrate::log("varBool equals 1");
            my $sql = "UPDATE volume SET store_type=2 WHERE path='$row[0]'";
            my $sth = $dbh->prepare ($sql);
            $sth->execute();
            $sth->finish();
        }
        else
        {
            # Migrate::log("varBool not equals 1");
        }
    }

    # finish query and disconnect from the MySQL database
    $sth->finish();
    $dbh->disconnect();
}