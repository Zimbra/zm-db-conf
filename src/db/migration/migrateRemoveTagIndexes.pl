#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2011, 2013, 2014 Zimbra, Inc.
# 
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.
# ***** END LICENSE BLOCK *****
#

use strict;
use lib "/opt/zimbra/zimbramon/lib";
use Migrate;

Migrate::loadOutdatedMailboxes("2.2");
removeTagIndexes();

exit(0);

#####################

sub removeTagIndexes() {
  Migrate::log("dropping tag indexes");

  my @groups = Migrate::getMailboxGroups();
  foreach my $group (@groups) {
    # mboxgroup DBs created since the upgrade won't have the indexes, so test before dropping
    my $sql = <<CHECK_INDEXES_EOF;
SHOW INDEXES IN $group.mail_item WHERE Key_name = 'i_unread';
CHECK_INDEXES_EOF
    my @indexes = Migrate::runSql($sql);

    if (scalar(@indexes) > 0) {
      $sql = <<DROP_INDEXES_EOF;
ALTER TABLE $group.mail_item DROP INDEX i_unread, DROP INDEX i_tags_date, DROP INDEX i_flags_date;
DROP_INDEXES_EOF
      Migrate::runSql($sql);
    } else {
      Migrate::log("$group.MAIL_ITEM tag indexes already dropped");
    }

    $sql = <<CHECK_DUMPSTER_INDEXES_EOF;
SHOW INDEXES IN $group.mail_item_dumpster WHERE Key_name = 'i_unread';
CHECK_DUMPSTER_INDEXES_EOF
    @indexes = Migrate::runSql($sql);

    if (scalar(@indexes) > 0) {
      $sql = <<DROP_DUMPSTER_INDEXES_EOF;
ALTER TABLE $group.mail_item_dumpster DROP INDEX i_unread, DROP INDEX i_tags_date, DROP INDEX i_flags_date;
DROP_DUMPSTER_INDEXES_EOF
      Migrate::runSql($sql);
    } else {
      Migrate::log("$group.MAIL_ITEM_DUMPSTER tag indexes already dropped");
    }
  }
}
