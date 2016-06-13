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

Migrate::verifySchemaVersion(19);

alterVolume();

Migrate::updateSchemaVersion(19, 20);

exit(0);

#####################

sub alterVolume() {
    my $sql = "ALTER TABLE volume" .
	" ADD compression_threshold BIGINT NOT NULL;";
    Migrate::runSql($sql);

    Migrate::runSql("UPDATE volume SET compression_threshold = 4096;");
    Migrate::runSql("DELETE FROM config WHERE name = 'store.compressBlobs'");
}
