#!/usr/bin/perl
#
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2026 Synacor, Inc.
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
use lib "/opt/zimbra/libexec/scripts";
use lib "/opt/zimbra/common/lib/perl5";
use Migrate;
use Getopt::Long;
my $concurrent = 10;

sub usage() {
	print STDERR "Usage: $0\n";
	exit(1);
}
my $opt_h;
GetOptions("help" => \$opt_h);
usage() if $opt_h;

# Verify Schema Version Number
Migrate::verifySchemaVersion(118);

my @groups = Migrate::getMailboxGroups();
my @sql = ();

foreach my $group (@groups) {
    print "Preparing to add ropc_token_store to $group...\n";
    my $query = <<"__EOF__";
CREATE TABLE IF NOT EXISTS  $group.ropc_token_store (
    id BIGINT AUTO_INCREMENT NOT NULL,
    username VARCHAR(255) NOT NULL,
    device_id VARCHAR(128) DEFAULT NULL,
    user_agent VARCHAR(255) DEFAULT NULL,
    ip VARCHAR(45) DEFAULT NULL,
    provider VARCHAR(32) NOT NULL,
    protocol VARCHAR(32) NOT NULL,
    refresh_token TEXT DEFAULT NULL,
    id_token TEXT DEFAULT NULL,
    password VARCHAR(256) DEFAULT NULL,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY `uk_user_device_session` (`username`, `provider`, `protocol`, `device_id`, `user_agent`),
    INDEX `idx_options_ip_lookup` (`username`, `provider`, `protocol`, `ip`, `user_agent`),
    INDEX `idx_expiry_cleanup` (`created_at`),
    INDEX `idx_back_channel_logout` (`username`),
    INDEX `idx_device_lookup` (`device_id`, `username`),
    INDEX `idx_latest_session_lookup` (`username`, `created_at`)
) ENGINE=InnoDB;
__EOF__

    push(@sql, $query);
}

my $start = time();
Migrate::runSqlParallel($concurrent, @sql);
my $elapsed = time() - $start;
my $numGroups = scalar @groups;
print "\nSuccessfully created ropc_token_store in $numGroups mailbox groups in $elapsed seconds\n";

Migrate::updateSchemaVersion(118, 119);

exit(0);
