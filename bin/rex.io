#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use YAML;
use Rex::IO::Client::Args;
use Rex::IO::Client;

use Mojo::JSON;
use Data::Dumper;

getopts(
   help => \&help,
   dump => sub {
      my $client = Rex::IO::Client->new;
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
   "server-get" => sub {
      my ($server) = @_;
      my $client = Rex::IO::Client->new;
      print Dump($client->get_server($server));
   },
   "server-add" => sub {
      my ($server) = @_;
      my $client = Rex::IO::Client->new;
      my %opts = Rex::IO::Client::Args->get;
      $opts{service} ||= "{}";

      my $service = Mojo::JSON->decode($opts{service});

      my $ret = {};
      eval {
         $ret = $client->add_server($server, {
            service => $service,
         });
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
   "service-get" => sub {
      my ($service) = @_;
      my $client = Rex::IO::Client->new;
      print Dump($client->get_service($service));
   },
   "service-add" => sub {
      my ($service) = @_;
      my $client = Rex::IO::Client->new;
      my %opts = Rex::IO::Client::Args->get;
      $opts{desc} ||= "";
      $opts{variables} ||= "{}";

      my $variables = Mojo::JSON->decode($opts{variables});

      my $ret = {};
      eval {
         $ret = $client->add_service($service, {
            descrition => $opts{desc},
            variables  => $variables,
         });
      };

      if($@) {
         print "Error adding new server.\n";
         exit 1;
      }

      print "Service $service added.\n";
      print Dump($ret);
   },
   "service-rm" => sub {
      my ($service) = @_;
      my $client = Rex::IO::Client->new();
      eval {
         $client->rm_service($service);
      };

      if($@) {
         print "Error deleting service ($service)\n";
         exit 1;
      }

      print "Service $service removed.\n";
   },
   "list-servers" => sub {
      my $client = Rex::IO::Client->new();
      my $data;
      eval {
         $data = $client->list_server();
      };

      if($@) {
         print "Error listing servers: $@\n";
         exit 1;
      }

      print Dump($data->{data});
   },
   "list-services" => sub {
      my $client = Rex::IO::Client->new();
      my $data;
      eval {
         $data = $client->list_service();
      };

      if($@) {
         print "Error listing services: $@\n";
         exit 1;
      }

      print Dump($data->{data});
   },
   "server" => sub {
      my ($server) = @_;
      my $client = Rex::IO::Client->new();

      my %opts = Rex::IO::Client::Args->get;
      my $ret;

      if(exists $opts{"service-add"}) {
         $ret = $client->add_service_to_server($server, $opts{"service-add"});
      }

      if(exists $opts{"service-rm"}) {
         $ret = $client->remove_service_from_server($server, $opts{"service-rm"});
      }

      if($ret->{ok} == Mojo::JSON->true) {
         print "ok\n";
      }
      else {
         print "failed\n";
      }

   },


);

sub help {
   print "--------------------------------------------------------------------------------\n";
   print " rex.io - Command Line Client Version $Rex::IO::Client::VERSION\n";
   print "    --help                          to display this help message\n";
   print "    --dump                          to display every cmdb option known to this client\n";
   print "    --get=<key>                     get values of key from cmdb\n";
   print "    --server-add=<server>           add a new server to the cmdb\n";
   print "          --service=<string>        add services to server in json format\n";
   print "    --server-rm=<server>            delete a server from the cmdb\n";
   print "    --server-get=<server>           get all cmdb information of server\n";
   print "    --server=<server>\n";
   print "          --service-add=<service>   add a new service to a server\n";
   print "          --service-rm=<service>    remove a service from a server\n";
   print "    --service-add=<server>          add a new service to the cmdb\n";
   print "          --desc=<desc>             add a description to the new service\n";
   print "          --variables=<string>      add additional variables in json format\n";
   print "    --service-rm=<server>           delete a service from the cmdb\n";
   print "    --service-get=<server>          get all cmdb information of service\n";
   print "    --list-servers                  lists all known servers and their\n";
   print "                                    configuration\n";
   print "    --list-services                 lists all known services\n";
   print "--------------------------------------------------------------------------------\n";

   exit;
}




