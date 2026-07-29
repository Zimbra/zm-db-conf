#!/opt/zimbra/common/bin/perl
#
# migrate20260727-TestPatchSchema.pl
#
# Adds a test table to every mailbox group (mboxgroupN) database
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use Migrate;

my $FROM_VERSION = 118;   # set to whatever db.version your test node is on
my $TO_VERSION   = 119;

Migrate::verifySchemaVersion($FROM_VERSION);

# Discover mailbox group databases on this node
my @mboxGroups = Migrate::runSql(
    "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA " .
    "WHERE SCHEMA_NAME LIKE 'mboxgroup%';"
);

foreach my $db (@mboxGroups) {
    chomp($db);
    next unless $db;
    addTestTable($db);
}

Migrate::updateSchemaVersion($FROM_VERSION, $TO_VERSION);

exit(0);

sub addTestTable {
    my ($db) = @_;

    print "Adding test table to $db\n";

    my $sql = qq{
        CREATE TABLE IF NOT EXISTS $db.patch_test_table (
            id           INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
            mailbox_id   INTEGER UNSIGNED NOT NULL,
            test_column  VARCHAR(255),
            created_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
	    INDEX i_mailbox_id (mailbox_id)
        ) ENGINE=InnoDB;
    };

    Migrate::runSql($sql);
}
