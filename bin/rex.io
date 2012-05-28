#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use YAML;
use Rex::IO::Client::Args;
use Rex::IO::Client;

use Data::Dumper;

getopts(
   help => \&help,
   dump => sub {
      my $client = Rex::IO::Client->new();
      $client->dump;
   },
   get => sub {
      my ($key) = @_;
      if(!$key || $key eq "1") {
         print "You have to define a key.\n";
         print "Example: rex.io --get=service://ntp/etc/ntp.conf\n";
         exit 1;
      }
      print Dump({ cmdb_get($key) });
   },
   "server-add" => sub {
      my ($server) = @_;
      my $client = Rex::IO::Client->new();

      my $ret = {};
      eval {
         $ret = $client->add_server($server);
      };

      if($@) {
         print "Error adding new server.\n";
         exit 1;
      }

      print "Server $server added.\n";
      print Dump($ret);
   },
   "server-rm" => sub {
      my ($server) = @_;
      my $client = Rex::IO::Client->new();
      eval {
         $client->rm_server($server);
      };

      if($@) {
         print "Error deleting server ($server)\n";
         exit 1;
      }

      print "Server $server removed.\n";
   },
);

sub help {
   print "--------------------------------------------------------------------------------\n";
   print " rex.io - Command Line Client Version $Rex::IO::Client::VERSION\n";
   print "    --help                to display this help message\n";
   print "    --dump                to display every cmdb option known to this client\n";
   print "    --get <key>           get values of key from cmdb\n";
   print "    --server-add <server> add a new server to the cmdb\n";
   print "    --server-rm <server>  delete a server from the cmdb\n";
   print "--------------------------------------------------------------------------------\n";

   exit;
}




