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


#Migrate::verifyLoggerSchemaVersion(0);

addConfig();

#Migrate::updateLoggerSchemaVersion(1,2);

exit(0);

#####################

sub addConfig() {
    Migrate::log("Adding Config");

    my $sql = <<EOF;
DROP TABLE IF EXISTS config;
CREATE TABLE config (
	name        VARCHAR(255) NOT NULL PRIMARY KEY,
	value       TEXT,
	description TEXT,
	modified    TIMESTAMP
) ENGINE = MyISAM;
EOF

    Migrate::runLoggerSql($sql);

	$sql = <<EOF;
DELETE from zimbra_logger.config WHERE name = 'db.version';
INSERT into zimbra_logger.config (name,value) values ('db.version',2);
EOF
    Migrate::runLoggerSql($sql);
}
