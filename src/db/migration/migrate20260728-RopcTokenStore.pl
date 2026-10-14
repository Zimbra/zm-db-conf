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

Migrate::verifySchemaVersion(118);

my @groups = Migrate::getMailboxGroups();
my $start = time();
my @create_ropc = ();

foreach my $group (@groups) {
    print "Preparing to add ropc_token_store to $group...\n";
    my $query = <<"__EOF__";
CREATE TABLE IF NOT EXISTS $group.ropc_token_store (
    id            BIGINT AUTO_INCREMENT NOT NULL,
    username      VARCHAR(255) NOT NULL,
    domain_name   VARCHAR(255) DEFAULT NULL,
    device_id     VARCHAR(128) NOT NULL DEFAULT '',
    user_agent    VARCHAR(255) NOT NULL DEFAULT '',
    ip            VARCHAR(45)  DEFAULT NULL,
    provider      VARCHAR(32)  NOT NULL,
    factor        VARCHAR(32)  NOT NULL,
    protocol      VARCHAR(32)  NOT NULL,
    created_at    BIGINT NOT NULL,
    updated_at    BIGINT NOT NULL,

    PRIMARY KEY (id),
    UNIQUE KEY `uk_user_device_session` (`username`, `provider`, `protocol`, `device_id`, `user_agent`, `factor`),
    INDEX `idx_domain_lookup` (`domain_name`),
    INDEX `idx_domain_created_lookup` (`domain_name`, `created_at`),
    INDEX `idx_options_ip_lookup` (`username`, `provider`, `protocol`, `ip`, `user_agent`, `factor`),
    INDEX `idx_expiry_cleanup` (`created_at`),
    INDEX `idx_back_channel_logout` (`username`),
    INDEX `idx_device_lookup` (`device_id`, `username`),
    INDEX `idx_latest_session_lookup` (`username`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
__EOF__

    push(@create_ropc, $query);
}

Migrate::runSqlParallel($concurrent, @create_ropc);

my @create_cred = ();
foreach my $group (@groups) {
    my $query = <<"__EOF__";
CREATE TABLE IF NOT EXISTS $group.cred_store (
    id                          BIGINT AUTO_INCREMENT NOT NULL,
    owner_type                  VARCHAR(16) NOT NULL,
    ropc_token_id               BIGINT DEFAULT NULL,
    client_label                VARCHAR(128) DEFAULT NULL,
    reg_id                      VARCHAR(255) CHARACTER SET utf8 DEFAULT NULL,
    app_id                      VARCHAR(64)  CHARACTER SET utf8 DEFAULT NULL,
    mailbox_id                  INTEGER UNSIGNED DEFAULT NULL,
    password_hash               VARCHAR(255) DEFAULT NULL,
    totp_hash                   VARCHAR(255) DEFAULT NULL,
    auth_provider               VARCHAR(16) NOT NULL DEFAULT 'ZIMBRA',
    idp_id                      VARCHAR(255) DEFAULT NULL,
    refresh_token_hash          BINARY(32) DEFAULT NULL,
    refresh_token_enc           VARBINARY(2048) DEFAULT NULL,
    refresh_token_key_version   SMALLINT UNSIGNED DEFAULT NULL,
    refresh_token_issued_at     BIGINT DEFAULT NULL,
    refresh_token_expires_at    BIGINT DEFAULT NULL,
    refresh_token_last_used_at  BIGINT DEFAULT NULL,
    refresh_token_version       INTEGER UNSIGNED NOT NULL DEFAULT 0,
    id_token                    TEXT DEFAULT NULL,
    revoked_at                  BIGINT DEFAULT NULL,
    created_at                  BIGINT NOT NULL,
    updated_at                  BIGINT NOT NULL,

    PRIMARY KEY (id),
    UNIQUE KEY `uk_cred_zmg` (`reg_id`),
    UNIQUE KEY `uk_cred_rt_hash` (`refresh_token_hash`),

    CONSTRAINT fk_cred_ropc FOREIGN KEY (ropc_token_id)
        REFERENCES $group.ropc_token_store (id) ON DELETE CASCADE,

    CONSTRAINT fk_cred_zmg FOREIGN KEY (reg_id)
        REFERENCES zimbra.zmg_devices (reg_id) ON DELETE SET NULL,

    CONSTRAINT fk_cred_mailbox FOREIGN KEY (mailbox_id)
        REFERENCES zimbra.mailbox (id) ON DELETE CASCADE,

    INDEX `i_cred_ropc_lookup`     (`ropc_token_id`),
    INDEX `i_cred_zmg_mailbox`     (`mailbox_id`, `revoked_at`),
    INDEX `i_cred_expiry_cleanup`  (`refresh_token_expires_at`),
    INDEX `i_cred_revocation`      (`owner_type`, `revoked_at`),
    INDEX `i_cred_idp`             (`auth_provider`, `idp_id`),
    INDEX `i_cred_id_token_lookup` (`id_token`(255)),
    INDEX `i_cred_owner_created`   (`owner_type`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
__EOF__

    push(@create_cred, $query);
}
Migrate::runSqlParallel($concurrent, @create_cred);

my $elapsed = time() - $start;
my $numGroups = scalar @groups;
print "\nSuccessfully created ropc_token_store and cred_store in $numGroups mailbox groups in $elapsed seconds\n";

Migrate::updateSchemaVersion(118, 119);

exit(0);
