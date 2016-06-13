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

########################################################################################################################

my $concurrent = 10;

Migrate::verifySchemaVersion(102);

my @groups = Migrate::getMailboxGroups();
#
&dropIndexes();

Migrate::updateSchemaVersion(102, 103);

exit(0);

########################################################################################################################

sub addSqlCommandsForDropIndexesForTable() {
  my ($tableName, $indexes, $mygroups, $sqlCommands) = @_;
  my @keyNames = ();
  foreach my $index (@{$indexes}) {
      push(@keyNames, "Key_name='$index'");
  }
  my $whereClause = join(' or ', @keyNames);
  foreach my $group (@{$mygroups}) {
    my @dropCmds = ();
    my @showIndexes = (Migrate::runSql("SHOW INDEX from $group.$tableName WHERE $whereClause;"));
    foreach my $index (@{$indexes}) {
      foreach my $showLine (@showIndexes) {
        my ($Table, $Non_Unique, $Key_name, @rest) = split('\s+', $showLine);
        if ($index eq $Key_name) {
          push(@dropCmds, "DROP INDEX $index");
          last;
        }
      }
    }
    my $allDrops = join(', ', @dropCmds);
    if (length $allDrops > 0) {
        my $sqlCommand = <<_EOF_;
ALTER TABLE $group.$tableName $allDrops;
_EOF_
        push(@{$sqlCommands},$sqlCommand);
    }
  }
}

########################################################################################################################
sub dropIndexes() {
  my @sql = ();

  my @indexes = ('i_unread', 'i_flags_date', 'i_tags_date', 'i_volume_id');
  &addSqlCommandsForDropIndexesForTable('mail_item', \@indexes, \@groups, \@sql);
  # same indexes need to be dropped for mail_item_dumpster as for mail_item
  &addSqlCommandsForDropIndexesForTable('mail_item_dumpster', \@indexes, \@groups, \@sql);

  Migrate::runSqlParallel($concurrent,@sql);
}
