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
use Rex::IO::Client::Config;

my @files = ("/etc/rex/io/client.conf", "/usr/local/etc/rex/io/client.conf", "client.conf");

my $cfg;
for my $file (@files) {
   if(-f $file) {
      $cfg = $file;
      last;
   }
}

Rex::IO::Client::Config->load(file => $cfg);

getopts(
   help => \&help,
   dump => sub {
      my $client = Rex::IO::Client->new;
      $client->dump;
   },
   service => sub {
      my ($service) = @_;
      my $client = Rex::IO::Client->new();
      my %opts = Rex::IO::Client::Args->get;
  
      if(exists $opts{"get"}) {
         print Dump($client->get_service($service));
      }

      elsif(exists $opts{"add"}) {
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

         exit;
      }

      elsif(exists $opts{"rm"}) {
         eval {
            $client->rm_service($service);
         };

         if($@) {
            print "Error deleting service ($service)\n";
            exit 1;
         }

         print "Service $service removed.\n";
         exit;
      }

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

      my $tmp;
      if(exists $opts{service}) {
         eval {
            $tmp = Mojo::JSON->decode($opts{service});
         };
      }

      if(exists $opts{"service"} && exists $opts{"add"} && ! ref($tmp)) {
         $ret = $client->add_service_to_server($server, $opts{"service"});
      }

      elsif(exists $opts{"service"} && exists $opts{"rm"} && ! ref($tmp)) {
         $ret = $client->remove_service_from_server($server, $opts{"service"});
      }

      elsif(exists $opts{service} && exists $opts{section} && exists $opts{variables} && ! ref($tmp)) {
         $ret = $client->configure_service_of_server($server, $opts{service}, $opts{section}, Mojo::JSON->decode($opts{variables}));
      }

      elsif(exists $opts{"rm"}) {
         eval {
            $client->rm_server($server);
         };

         if($@) {
            print "Error deleting server ($server)\n";
            exit 1;
         }

         print "Server $server removed.\n";
         exit;
      }

      elsif(exists $opts{"add"}) {
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
         exit;
      }

      elsif(exists $opts{"get"}) {
         print Dump($client->get_server($server));
         exit;
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
   print "    --server=<server>\n";
   print "       --add                        add a new server to the cmdb\n";
   print "       --rm                         delete a server from the cmdb\n";
   print "       --get                        get all cmdb information of server\n";
   print "       --service=<service>\n";
   print "          --add                     add a new service to a server\n";
   print "          --rm                      remove a service from a server\n";
   print "          --section=<section>       configure a section\n";
   print "             --variables=<json>     configure variables of a section\n";
   print "    --service=<service> \n";
   print "       --add                        add a new service to the cmdb\n";
   print "       --rm                         delete a service from the cmdb\n";
   print "       --get                        get all cmdb information of service\n";
   print "       --desc=<desc>                add a description to the new service\n";
   print "       --variables=<string>         add additional variables in json format\n";
   print "    --list-servers                  lists all known servers and their\n";
   print "                                    configuration\n";
   print "    --list-services                 lists all known services\n";
   print "--------------------------------------------------------------------------------\n";

   exit;
}




