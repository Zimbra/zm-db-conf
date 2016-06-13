#!/usr/bin/perl
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2007, 2008, 2009, 2010, 2013, 2014, 2015, 2016 Synacor, Inc.
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
use lib "/opt/zimbra/common/lib/perl5";
use Zimbra::Util::Common;
use Data::UUID;
use Net::LDAPapi;

my ($binddn,$bindpwd,$host,$junk,$result,@localconfig,$ismaster);
@localconfig=`/opt/zimbra/bin/zmlocalconfig -s ldap_master_url zimbra_ldap_userdn zimbra_ldap_password ldap_is_master`;

$host=$localconfig[0];
($junk,$host) = split /= /, $host, 2;
chomp $host;

$binddn=$localconfig[1];
($junk,$binddn) = split /= /, $binddn, 2;
chomp $binddn;

$bindpwd=$localconfig[2];
($junk,$bindpwd) = split /= /, $bindpwd, 2;
chomp $bindpwd;

$ismaster=$localconfig[3];
($junk,$ismaster) = split /= /, $ismaster, 2;
chomp $ismaster;

if ($ismaster ne "true") {
	exit;
}

print "Updating old Identity classes";
my @attrs = ("zimbraPrefBccAddress", "zimbraPrefForwardIncludeOriginalText", "zimbraPrefForwardReplyFormat", "zimbraPrefForwardReplyPrefixChar", "zimbraPrefMailSignature",
			"zimbraPrefMailSignatureEnabled", "zimbraPrefMailSignatureStyle", "zimbraPrefReplyIncludeOriginalText", "zimbraPrefSaveToSent", "zimbraPrefSentMailFolder",
			"zimbraPrefUseDefaultIdentitySettings");
my $ld = Net::LDAPapi->new(-url=>"$host");
my $status;
if ($host !~ /^ldaps/i) {
  $status=$ld->start_tls_s();
}
$status = $ld->bind_s($binddn,$bindpwd);
$status = $ld->search_s("",LDAP_SCOPE_SUBTREE,"objectClass=zimbraIdentity",\@attrs,0,$result);

my ($ent,$dn,$attr);

foreach ($ent = $ld->first_entry; $ent != 0; $ent = $ld->next_entry) {
	if (($dn = $ld->get_dn) eq "")
	{
		$ld->unbind;
		die "get_dn: ", $ld->errstring, ": ", $ld->extramsg;
	}
	$attr=$ld->first_attribute;
	foreach ($attr = $ld->first_attribute; $attr ne ""; $attr = $ld->next_attribute) {
		my %ldap_modifications = (
			"$attr", "",
		);
		$ld->modify_s($dn,\%ldap_modifications);
	}
	print ".";
}
print "done!\n";

$ld->unbind();
