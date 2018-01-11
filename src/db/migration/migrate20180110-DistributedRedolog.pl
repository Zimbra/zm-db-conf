#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2006, 2007, 2008, 2009, 2010, 2013, 2014, 2016, 2017, 2018 Synacor, Inc.
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

Migrate::verifySchemaVersion(109);
createDistributedRedologTable();
Migrate::updateSchemaVersion(109, 110);
exit(0);

#####################
sub createDistributedRedologTable($) {
  my @sql = ();
  my $sql = <<_SQL_;
  CREATE TABLE IF NOT EXISTS zimbra.distributed_redolog
( 
  opOrder BIGINT PRIMARY KEY AUTO_INCREMENT,
  opType CHAR(2) DEFAULT 'OP' CHECK (opType IN ('OP', 'HD')) ,
  op LONGBLOB NOT NULL
) ENGINE = InnoDB;
_SQL_
  Migrate::runSql($sql);
}
