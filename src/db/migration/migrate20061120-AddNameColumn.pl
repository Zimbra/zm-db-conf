#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2006, 2007, 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
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

addNameColumn();

exit(0);

#####################

sub addNameColumn($) {
  my ($group) = @_;
  Migrate::verifySchemaVersion(31);
  my $date = time();
  my @groups = Migrate::getMailboxGroups();
  my @sql = ();
  foreach my $group (@groups) {
    my $sql = <<ADD_NAME_COLUMN_EOF;
ALTER TABLE $group.mail_item
ADD COLUMN name VARCHAR(128) AFTER subject;
ADD_NAME_COLUMN_EOF
    push(@sql,$sql);
  }
  Migrate::runSqlParallel($concurrent,@sql);

  my @sql = ();
  foreach my $group (@groups) {
    my $sql = <<ADD_NAME_COLUMN_EOF;
CREATE UNIQUE INDEX i_name_folder_id ON $group.mail_item(mailbox_id, folder_id, name);
ADD_NAME_COLUMN_EOF
    push(@sql,$sql);
  }
  Migrate::runSqlParallel($concurrent,@sql);

  my @sql = ();
  foreach my $group (@groups) {
    my $sql = <<ADD_NAME_COLUMN_EOF;
UPDATE IGNORE $group.mail_item
SET name = subject
WHERE id < 256 AND type IN (1, 3);
ADD_NAME_COLUMN_EOF
    push(@sql,$sql);
  }
  Migrate::runSqlParallel($concurrent,@sql);

  my @sql = ();
  foreach my $group (@groups) {
    my $sql = <<ADD_NAME_COLUMN_EOF;
UPDATE IGNORE $group.mail_item
SET name = subject
WHERE type IN (1, 2, 3, 8, 13, 14) AND subject IS NOT NULL AND name IS NULL;
ADD_NAME_COLUMN_EOF
    push(@sql,$sql);
  }
  Migrate::runSqlParallel($concurrent,@sql);

  my @sql = ();
  foreach my $group (@groups) {
    my $sql = <<ADD_NAME_COLUMN_EOF;
UPDATE IGNORE $group.mail_item
SET name = CONCAT(SUBSTRING(subject, 1, 99), '{RENAMED-MIGRATE-$date}'), subject = name
WHERE type IN (1, 2, 3, 8, 13, 14) AND subject IS NOT NULL AND name IS NULL;
ADD_NAME_COLUMN_EOF
    push(@sql,$sql);
  }
  Migrate::runSqlParallel($concurrent,@sql);

  Migrate::updateSchemaVersion(31, 32);
}
