#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2014, 2016 Synacor, Inc.
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

Migrate::verifySchemaVersion(101);
enforceCharset();
Migrate::updateSchemaVersion(101, 102);
exit(0);

sub enforceCharset()
{
  my @tables = ('mail_item_dumpster', 'revision_dumpster', 'appointment_dumpster');
  foreach my $group (Migrate::getMailboxGroups()) {
    foreach my $table (@tables) {
    my $sql;
    $sql = <<_EOF_;
delimiter //
create procedure convertCharset()
    BEGIN
    SET \@curCharset = 
    (SELECT CCSA.character_set_name FROM information_schema.tables T,
       information_schema.collation_character_set_applicability CCSA
    WHERE CCSA.collation_name = T.table_collation
    AND T.table_schema = "$group"
    AND T.table_name = "$table");
    IF \@curCharset!="utf8" 
    THEN 
        ALTER TABLE $group.$table
        CONVERT TO CHARACTER SET "utf8";
    END IF;
    END//
delimiter ;
call convertCharset();
drop procedure convertCharset;
_EOF_
 Migrate::runSql($sql);
}
}
}

