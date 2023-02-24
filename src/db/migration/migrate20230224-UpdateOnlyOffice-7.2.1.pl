# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2023 Synacor, Inc.
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
use DBI;
use strict;
use Migrate;

# Verify Schema Version Number
Migrate::verifySchemaVersion(117);

addTenantColumnToDocChanges();
addMultiColumnToTaskResult();

# Update Schema Version Number
Migrate::updateSchemaVersion(117, 118);

exit(0);

# Function to add 'tenant' column to doc_changes table that is auto updating
sub addTenantColumnToDocChanges() {
    my $sql = <<OO_ADD_COLUMN_EOF;
    ALTER TABLE onlyoffice.`doc_changes` ADD COLUMN `tenant` VARCHAR(255) NULL FIRST;
    ALTER TABLE onlyoffice.`doc_changes` DROP PRIMARY KEY;
    ALTER TABLE onlyoffice.`doc_changes` ADD PRIMARY KEY (`tenant`, `id`,`change_id`);
OO_ADD_COLUMN_EOF

    Migrate::log("Adding tenant column to doc_changes table.");
    Migrate::runSql($sql);
}

# Function to add tenant, created_at, password, additional, columns to task_result table that is auto updating
sub addMultiColumnToTaskResult() {
    my $sql = <<OO_ADD_COLUMN_EOF;
    ALTER TABLE onlyoffice.`task_result` ADD COLUMN `tenant` VARCHAR(255) NULL FIRST;
    ALTER TABLE onlyoffice.`task_result` ADD COLUMN `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
    ALTER TABLE onlyoffice.`task_result` ADD COLUMN `password` LONGTEXT NULL;
    ALTER TABLE onlyoffice.`task_result` ADD COLUMN `additional` LONGTEXT NULL DEFAULT NULL;
    ALTER TABLE onlyoffice.`task_result` DROP PRIMARY KEY;
    ALTER TABLE onlyoffice.`task_result` ADD PRIMARY KEY (`tenant`, `id`);
OO_ADD_COLUMN_EOF

    Migrate::log("Adding tenant, created_at, password, additional columns to task_result table.");
    Migrate::runSql($sql);
}
