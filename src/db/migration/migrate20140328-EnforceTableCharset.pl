#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2005, 2006, 2007, 2008, 2009, 2010, 2013 Zimbra Software, LLC.
# 
# The contents of this file are subject to the Zimbra Public License
# Version 1.4 ("License"); you may not use this file except in
# compliance with the License.  You may obtain a copy of the License at
# http://www.zimbra.com/license.
# 
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied.
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
  my @sqls;
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
 push(@sqls,$sql);  
 }
 }
 my $concurrency = 10;
 Migrate::runSqlParallel($concurrency, @sqls);
}

