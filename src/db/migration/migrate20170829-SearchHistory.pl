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

Migrate::verifySchemaVersion(109);
createSearchHistoryTables();
addSearchIdCheckpointColumn();
Migrate::updateSchemaVersion(109, 110);
exit(0);

#####################

sub createSearchHistoryTables($) {
  my ($group) = @_;
  my @groups = Migrate::getMailboxGroups();
  my @sql = ();
  foreach my $group (@groups) {
    my $sql = <<_SQL_;
CREATE TABLE IF NOT EXISTS $group.searches (
mailbox_id       INTEGER UNSIGNED NOT NULL,
id               INTEGER UNSIGNED NOT NULL,
search           VARCHAR(255),
status           TINYINT NOT NULL DEFAULT 0,
last_search_date DATETIME,

PRIMARY KEY (mailbox_id, id),
INDEX i_search (mailbox_id, search),
CONSTRAINT fk_searches_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id) ON DELETE CASCADE
) ENGINE = InnoDB;
_SQL_
    push(@sql,$sql);
  }
  Migrate::runSqlParallel($concurrent,@sql);
  my @sql = ();
  foreach my $group (@groups) {
    my $sql = <<_SQL_; 
CREATE TABLE IF NOT EXISTS $group.search_history (
mailbox_id    INTEGER UNSIGNED NOT NULL,
search_id     INTEGER UNSIGNED NOT NULL,
date          DATETIME NOT NULL,

CONSTRAINT fk_search_history_mailbox_id FOREIGN KEY (mailbox_id) REFERENCES zimbra.mailbox(id) ON DELETE CASCADE,
CONSTRAINT fk_search_id FOREIGN KEY (mailbox_id, search_id) REFERENCES $group.searches(mailbox_id, id) ON DELETE CASCADE
) ENGINE = InnoDB;
_SQL_
    push(@sql,$sql);
  }
  Migrate::runSqlParallel($concurrent,@sql);
}

sub addSearchIdCheckpointColumn($) {
  my @colCountRes = Migrate::runSql("SELECT count(*) from information_schema.columns where table_schema='zimbra' and table_name='mailbox' and column_name='search_id_checkpoint'");
  my $colCount = @colCountRes[0];
  if ($colCount == 0) {
    my @sql = ();
    my $sql = <<_SQL_;
ALTER TABLE zimbra.mailbox
ADD COLUMN search_id_checkpoint INTEGER DEFAULT 0 NOT NULL AFTER itemcache_checkpoint;
_SQL_
    Migrate::runSql($sql);
  }
}
