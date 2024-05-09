#!/usr/bin/perl
use strict;
use lib "/opt/zimbra/libexec";
use lib "/opt/zimbra/libexec/scripts";
use lib "/opt/zimbra/common/lib/perl5";
use Migrate;
use zmupgrade;

my $platform = qx(/opt/zimbra/libexec/get_plat_tag.sh);
chomp $platform;
my $su = "su - zimbra -c";
my $hiVersion = 118;

sub progress {
	my $msg = shift;
	print "$msg";
}

sub isInstalled {
	my $pkg = shift;
	my $pkgQuery;
	my $good = 0;
	if ($platform =~ /^DEBIAN/ || $platform =~ /^UBUNTU/) {
		$pkgQuery = "dpkg -s $pkg";
	} else {
		$pkgQuery = "rpm -q $pkg";
	}

	my $rc = 0xffff & system ("$pkgQuery > /dev/null 2>&1");
	$rc >>= 8;
	if (($platform =~ /^DEBIAN/ || $platform =~ /^UBUNTU/) && $rc == 0 ) {
		$good = 1;
		$pkgQuery = "dpkg -s $pkg | egrep '^Status: ' | grep 'not-installed'";
		$rc = 0xffff & system ("$pkgQuery > /dev/null 2>&1");
		$rc >>= 8;
		return ($rc == $good);
	} else {
		return ($rc == $good);
	}
}

sub runAsZimbra {
	my $cmd = shift;
	progress("*** Running as zimbra user: $cmd\n");
	my $rc;
	$rc = 0xffff & system("$su \"$cmd\"");
	return $rc;
}


sub main {
	my $curSchemaVersion;
	if (isInstalled("zimbra-store")) {
		my $startSqlResult = zmupgrade::startSql();
		if ($startSqlResult != 0) {
			progress("Failed to start MySQL. Exiting.\n");
			exit 1;
		}
		$curSchemaVersion = Migrate::getSchemaVersion();
		if ($curSchemaVersion < $hiVersion) {
			progress("Schema upgrade required from version $curSchemaVersion to $hiVersion.\n");
			while ($curSchemaVersion < $hiVersion) {
				if (zmupgrade::runSchemaUpgrade($curSchemaVersion)) {
					progress("Schema upgrade failed. Exiting.\n");
					exit 1;
				}
				$curSchemaVersion = Migrate::getSchemaVersion();
			}
			progress("Schema upgrade completed successfully.\n");
		} else {
			progress("Schema upgrade not required.\n");
		}
	}
	return 0;
}
exit main();
