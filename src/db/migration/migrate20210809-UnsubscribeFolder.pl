#!/usr/bin/perl

# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2021 Synacor, Inc.
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

#
# Add Unsubscribe system folder (id = 19) to each mailbox.
#

use strict;
use Migrate;

sub bumpUpMailboxChangeCheckpoints();

my $CONCURRENCY = 10;
my $ID = 19;
my $METADATA = 'd1:ai1e3:das5:false4:mseqi1e4:unxti20e1:vi10e2:vti5ee';
my $NOW = time();
my $FOLDERNAME = 'Unsubscribe';

Migrate::verifySchemaVersion(114);

bumpUpMailboxChangeCheckpoints();

my @sqlRename;
my %mailboxes = Migrate::getMailboxes();

my %uniqueGroups;
foreach my $gid (values %mailboxes) {
    if (!exists($uniqueGroups{$gid})) {
        $uniqueGroups{$gid} = $gid;
    }
}
my @sqlInsert;
my @groups = sort(keys %uniqueGroups);
foreach my $gid (sort @groups) {
    my $sql = createFolder($gid);
    push(@sqlInsert, $sql);
}
Migrate::runSqlParallel($CONCURRENCY, @sqlInsert);

exit(0);


#####################


# Increment change_checkpoint column for all rows in mailbox table.
# This SQL must be executed immediately rather than queued.
sub bumpUpMailboxChangeCheckpoints() {
    my $sql =<<_SQL_;
UPDATE mailbox
SET change_checkpoint = change_checkpoint + 100;
_SQL_
    Migrate::runSql($sql);
}

# Create the system Unsubscribe folder for each mailbox in the specified
# mailbox group.
sub createFolder($) {
    my $gid = shift;

    my $sql = <<_SQL_;
INSERT INTO mboxgroup$gid.mail_item (
    mailbox_id, id, type, parent_id, folder_id, index_id, imap_id,
    date, size, blob_digest,
    unread, flags, tags, sender,
    subject, name, metadata,
    mod_metadata, change_date, mod_content
)
SELECT
    id, $ID, 1, 1, 1, null, null,
    $NOW, 0, null,
    0, 0, 0, null,
    '$FOLDERNAME', '$FOLDERNAME', '$METADATA',
    change_checkpoint, $NOW, change_checkpoint
FROM mailbox
WHERE group_id = $gid
ON DUPLICATE KEY UPDATE name = '$FOLDERNAME';
_SQL_
    return $sql;
}


__END__


Metadata:  "d1:ai1e3:das5:false4:mseqi1e4:unxti20e1:vi10e2:vti5ee"

d #map

  ###
  #
  # FN_ATTRS = 1  (FOLDER_IS_IMMUTABLE)
  #
  1: #len("a")
    a # FN_ATTRS (See Folder.java, FOLDER_IS_IMMUTABLE)
  i #int
    1
  e #int end

  ###
  #
  # FN_MODSEQ = 1 (maybe not required, but for consistency)
  #
  4: #len("mseq")
    unxt
  i #int
    1
  e #int end

  ###
  #
  # UID_NEXT = 20  (for imap, this should just start as the type-id of the folder)
  #
  4: #len("unxt")
    unxt
  i #int
    17
  e #int end

  ###
  #
  # MD_VERSION = 10  (current MD version from source code)
  #
  1: #len("v")
    v
  i #int
    10
  e #int end

  #
  # FN_VIEW = 5  (MailItem TYPE_* entry, this one means TYPE_MESSAGE)
  #
  2: #len("vt")
    vt
  i #int
    8
  e #int end

e #map end
