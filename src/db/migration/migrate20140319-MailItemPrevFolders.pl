#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2014 Zimbra Software, LLC.
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

########################################################################################################################

Migrate::verifySchemaVersion(100);

foreach my $group (Migrate::getMailboxGroups()) {
    addPrevFoldersColumnToMailItem($group);
    addPrevFoldersColumnToMailItemDumpster($group);
}

Migrate::updateSchemaVersion(100, 101);

exit(0);

########################################################################################################################

sub addPrevFoldersColumnToMailItem($) {
    my ($group) = @_;
    Migrate::logSql("Adding prev_folder_ids column to mail_item table...");
    my $sql = <<_EOF_;
ALTER TABLE $group.mail_item ADD COLUMN prev_folders TEXT AFTER folder_id;
_EOF_
  Migrate::runSql($sql);
}

sub addPrevFoldersColumnToMailItemDumpster($) {
    my ($group) = @_;
    Migrate::logSql("Adding prev_folder_ids column to mail_item_dumpster table...");
    my $sql = <<_EOF_;
ALTER TABLE $group.mail_item_dumpster ADD COLUMN prev_folders TEXT AFTER folder_id;
_EOF_
  Migrate::runSql($sql);
}
