#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Rex::IO::Client::Args;
use Rex::IO::Client;

use Data::Dumper;

getopts(
   help => \&help,
   dump => sub {
      my $client = Rex::IO::Client->new();
      $client->dump;
   },
);

sub help {
   print "--------------------------------------------------------------------------------\n";
   print " rex.io - Command Line Client Version $Rex::IO::Client::VERSION\n";
   print "    --help                to display this help message\n";
   print "    --dump                to display every cmdb option known to this client\n";
   print "--------------------------------------------------------------------------------\n";

   exit;
}




