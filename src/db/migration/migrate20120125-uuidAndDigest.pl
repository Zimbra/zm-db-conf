#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2012, 2013, 2014, 2016 Synacor, Inc.
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

sub doIt();

Migrate::verifySchemaVersion(86);
doIt();
Migrate::updateSchemaVersion(86, 87);

exit(0);

#####################

sub doIt() {
  Migrate::logSql("Adding uuid column and widening blob_digest column.");
  my @sqls;
  foreach my $group (Migrate::getMailboxGroups()) {
    my $sql;
    $sql = <<_EOF_;
ALTER TABLE $group.mail_item
  MODIFY COLUMN blob_digest VARCHAR(44) BINARY,
  ADD COLUMN uuid VARCHAR(127) AFTER mod_content,
  ADD INDEX i_uuid (mailbox_id, uuid);
_EOF_
    push(@sqls,$sql);

    $sql = <<_EOF_;
ALTER TABLE $group.mail_item_dumpster
  MODIFY COLUMN blob_digest VARCHAR(44) BINARY,
  ADD COLUMN uuid VARCHAR(127) AFTER mod_content,
  ADD INDEX i_uuid (mailbox_id, uuid);
_EOF_
    push(@sqls,$sql);

    $sql = <<_EOF_;
ALTER TABLE $group.revision
  MODIFY COLUMN blob_digest VARCHAR(44) BINARY;
_EOF_
    push(@sqls,$sql);

    $sql = <<_EOF_;
ALTER TABLE $group.revision_dumpster
  MODIFY COLUMN blob_digest VARCHAR(44) BINARY;
_EOF_
    push(@sqls,$sql);
  }

  my $concurrency = 10;
  Migrate::runSqlParallel($concurrency, @sqls);
}
