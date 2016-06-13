#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2011, 2013, 2014, 2016 Synacor, Inc.
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
########################################################################################################################

Migrate::verifySchemaVersion(81);

addRecipientsColumn();

Migrate::updateSchemaVersion(81, 82);

exit(0);

########################################################################################################################

sub addRecipientsColumn() {
  my @groups = Migrate::getMailboxGroups();
  my @sql = ();
  foreach my $group (@groups) {
    my $sql = <<_EOF_;
ALTER TABLE $group.mail_item ADD COLUMN recipients VARCHAR(128) AFTER sender;
_EOF_
    push(@sql,$sql);
  }
  Migrate::runSqlParallel($concurrent,@sql);

  @sql = ();
  foreach my $group (@groups) {
    my $sql = <<_EOF_;
ALTER TABLE $group.mail_item_dumpster ADD COLUMN recipients VARCHAR(128) AFTER sender;
_EOF_
    push(@sql,$sql);
  }
  Migrate::runSqlParallel($concurrent,@sql);
}
