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

Migrate::verifySchemaVersion(88);

#
# drop the IM tables if exist
#
my $sql = <<_SQL_;

USE zimbra;

DROP TABLE IF EXISTS jiveUserProp;

DROP TABLE IF EXISTS jiveGroupProp;

DROP TABLE IF EXISTS jiveGroupUser;

DROP TABLE IF EXISTS jivePrivate;

DROP TABLE IF EXISTS jiveOffline;

DROP TABLE IF EXISTS jiveRoster;

DROP TABLE IF EXISTS jiveRosterGroups;

DROP TABLE IF EXISTS jiveVCard;

DROP TABLE IF EXISTS jiveID;

DROP TABLE IF EXISTS jiveProperty;

DROP TABLE IF EXISTS jiveVersion;

DROP TABLE IF EXISTS jiveExtComponentConf;

DROP TABLE IF EXISTS jiveRemoteServerConf;

DROP TABLE IF EXISTS jivePrivacyList;

DROP TABLE IF EXISTS jiveSASLAuthorized;

DROP TABLE IF EXISTS mucRoom;

DROP TABLE IF EXISTS mucRoomProp;

DROP TABLE IF EXISTS mucAffiliation;

DROP TABLE IF EXISTS mucMember;

DROP TABLE IF EXISTS mucConversationLog;

_SQL_

Migrate::runSql($sql);

Migrate::updateSchemaVersion(88, 89);

exit(0);
