-- 
-- ***** BEGIN LICENSE BLOCK *****
-- Zimbra Collaboration Suite Server
-- Copyright (C) 2013, 2014, 2016 Synacor, Inc.
--
-- This program is free software: you can redistribute it and/or modify it under
-- the terms of the GNU General Public License as published by the Free Software Foundation,
-- version 2 of the License.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License along with this program.
-- If not, see <https://www.gnu.org/licenses/>.
-- ***** END LICENSE BLOCK *****
-- 
BEGIN TRANSACTION;
DROP TABLE tmp_session_tracking;
ALTER TABLE session_tracking RENAME TO tmp_session_tracking;
CREATE TABLE session_tracking(
    Instance        VARCHAR(255),
    QueueID         VARCHAR(255),

    UnixTimestamp       BIGINT NOT NULL,

    ClientAddress       VARCHAR(64),
    ClientName      VARCHAR(255),
    ClientReverseName   VARCHAR(255),

    Protocol        VARCHAR(255),

    EncryptionProtocol  VARCHAR(255),
    EncryptionCipher    VARCHAR(255),
    EncryptionKeySize   VARCHAR(255),

    SASLMethod      VARCHAR(255),
    SASLSender      VARCHAR(255),
    SASLUsername        VARCHAR(255),

    Helo            VARCHAR(255),

    Sender          VARCHAR(255),

    Size            INT8,

    RecipientData       TEXT,  /* Policy state information */

    UNIQUE (Instance)
);
CREATE INDEX session_tracking_idx1 ON session_tracking (QueueID,ClientAddress,Sender);
CREATE INDEX session_tracking_idx2 ON session_tracking (UnixTimestamp);
INSERT INTO session_tracking(Instance, QueueID, UnixTimestamp, ClientAddress,
ClientName, ClientReverseName, Protocol, EncryptionProtocol, EncryptionCipher,
EncryptionKeySize, SASLMethod, SASLSender, SASLUsername, Helo, Sender, Size,
RecipientData)
SELECT Instance, QueueID, Timestamp, ClientAddress, ClientName,
ClientReverseName, Protocol, EncryptionProtocol, EncryptionCipher,
EncryptionKeySize, SASLMethod, SASLSender, SASLUsername, Helo, Sender, Size,
RecipientData
FROM tmp_session_tracking;
DROP TABLE tmp_session_tracking;
COMMIT;
