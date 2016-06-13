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

Migrate::verifySchemaVersion(90);
doIt();
Migrate::updateSchemaVersion(90, 91);

exit(0);

#####################

sub doIt() {
  foreach my $group (Migrate::getMailboxGroups()) {
    my $volumeIdInt = (Migrate::runSql("show columns from $group.mail_item where Field = 'volume_id';"))[0];
    if (length $volumeIdInt == 0) {
      Migrate::logSql("$group.mail_item.volume_id doesn't exist, assuming $group is already done, skipping...");
    } else {
      $volumeIdInt = (Migrate::runSql("show columns from $group.mail_item where Field = 'volume_id' and Type like '%int%';"))[0];
      if (length $volumeIdInt == 0) {
        #existing install using external store; volume_id was manually altered
        Migrate::logSql("$group.mail_item.volume_id is not currently an int; this installation probably altered it for older StoreManager implementation");
        fixVolumeId($group);	
      } else {
        #standard migration
        Migrate::logSql("Adding blob locator columns in $group");
        alterVolumeId($group);
      }
    }
  }
}

sub alterVolumeId($) {
#standard migration
  my ($group) = @_;
  my $sql;
  $sql = <<_EOF_;
ALTER TABLE $group.mail_item DROP INDEX i_volume_id,
                             DROP FOREIGN KEY fk_mail_item_volume_id,
                             DROP KEY fk_mail_item_volume_id,
                             CHANGE volume_id locator VARCHAR(1024);
ALTER TABLE $group.mail_item_dumpster DROP INDEX i_volume_id,
                                      DROP FOREIGN KEY fk_mail_item_dumpster_volume_id,
                                      DROP KEY fk_mail_item_dumpster_volume_id,
                                      CHANGE volume_id locator VARCHAR(1024);
ALTER TABLE $group.revision CHANGE volume_id locator VARCHAR(1024);
ALTER TABLE $group.revision_dumpster CHANGE volume_id locator VARCHAR(1024);
_EOF_
  Migrate::runSql($sql);
}

sub fixVolumeId($) {
#migration for installs which hacked our db schema for legacy HttpStore support
  my ($group) = @_;
  my $sql;
  
#drop any existing keys/indexes from mail_item
  my $mailItemVolIdx = (Migrate::runSql("show indexes from $group.mail_item where key_name='i_volume_id';"))[0];  
  if (length $mailItemVolIdx > 0) {
    $sql = <<_EOF_;
ALTER TABLE $group.mail_item DROP INDEX i_volume_id;
_EOF_
    Migrate::runSql($sql);
  }
  my $mailItemVolFk = (Migrate::runSql("select * from INFORMATION_SCHEMA.KEY_COLUMN_USAGE where REFERENCED_TABLE_NAME= 'volume' and CONSTRAINT_SCHEMA='$group' and CONSTRAINT_NAME='fk_mail_item_volume_id';"))[0];  
  if (length $mailItemVolFk > 0) {
    $sql = <<_EOF_;
ALTER TABLE $group.mail_item DROP FOREIGN KEY fk_mail_item_volume_id;
_EOF_
    Migrate::runSql($sql);
  }
  my $mailItemVolFkIdx = (Migrate::runSql("show indexes from $group.mail_item where key_name='fk_mail_item_volume_id';"))[0];  
  if (length $mailItemVolFkIdx > 0) {
    $sql = <<_EOF_;
ALTER TABLE $group.mail_item DROP KEY fk_mail_item_volume_id;
_EOF_
    Migrate::runSql($sql);
  }

#drop any existing keys/indexes from mail_item_dumpster
  my $dumpsterVolIdx = (Migrate::runSql("show indexes from $group.mail_item_dumpster where key_name='i_volume_id';"))[0];  
  if (length $dumpsterVolIdx > 0) {
    $sql = <<_EOF_;
ALTER TABLE $group.mail_item_dumpster DROP INDEX i_volume_id;
_EOF_
    Migrate::runSql($sql);
  }
  my $dumpsterVolFk = (Migrate::runSql("select * from INFORMATION_SCHEMA.KEY_COLUMN_USAGE where REFERENCED_TABLE_NAME= 'volume' and CONSTRAINT_SCHEMA='$group' and CONSTRAINT_NAME='fk_mail_item_dumpster_volume_id';"))[0];  
  if (length $dumpsterVolFk > 0) {
    $sql = <<_EOF_;
ALTER TABLE $group.mail_item_dumpster DROP FOREIGN KEY fk_mail_item_dumpster_volume_id;
_EOF_
    Migrate::runSql($sql);
  }
  my $dumpsterVolFkIdx = (Migrate::runSql("show indexes from $group.mail_item_dumpster where key_name='fk_mail_item_dumpster_volume_id';"))[0];  
  if (length $dumpsterVolFkIdx > 0) {
    $sql = <<_EOF_;
ALTER TABLE $group.mail_item_dumpster DROP KEY fk_mail_item_dumpster_volume_id;
_EOF_
    Migrate::runSql($sql);
  }
  
#alter columns  
  $sql = <<_EOF_;
ALTER TABLE $group.mail_item CHANGE volume_id locator VARCHAR(1024);
ALTER TABLE $group.mail_item_dumpster CHANGE volume_id locator VARCHAR(1024);
ALTER TABLE $group.revision CHANGE volume_id locator VARCHAR(1024);
ALTER TABLE $group.revision_dumpster CHANGE volume_id locator VARCHAR(1024);
_EOF_
  Migrate::runSql($sql);
}

