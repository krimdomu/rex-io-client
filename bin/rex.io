#!perl

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

=pod

=head1 rex.io - client for the rex.io infrastructure

Rex.IO is a server infrastructure around the Rex Framework. It will combine serveral tools under one interface. The first tool integrated is a small configuration database L<Rex::IO::CMDB>.


=head2 Command line options

=over 4

=item    --help                          to display this help message

=item    --dump                          to display every cmdb option known to this client

=item    --get=<key>                     get values of key from cmdb

=item    --server=<server>

=item       --add                        add a new server to the cmdb

=item       --rm                         delete a server from the cmdb

=item       --get                        get all cmdb information of server

=item       --service=<service>

=item          --add                     add a new service to a server

=item          --rm                      remove a service from a server

=item          --section=<section>       configure a section

=item             --variables=<json>     configure variables of a section

=item    --service=<service> 

=item       --add                        add a new service to the cmdb

=item       --rm                         delete a service from the cmdb

=item       --get                        get all cmdb information of service

=item       --desc=<desc>                add a description to the new service

=item       --variables=<string>         add additional variables in json format

=item    --list-servers                  lists all known servers and their configuration

=item    --list-services                 lists all known services

=back

=head2 WORDING

=head3 SERVICE

A service is a abstract description of a configuration item. Like "ntp" or "apache". A typical service exists of serveral sections. Every section exists of serveral variables. These sections can be multidimensional.

Example:

 {
    "configuration": {
       "server": {
          "default": "ntp.local.lan",
          "type": "string"
       },
       "restrict": {
          "default": [
             "127.0.0.1"
          ],
          "type": "array"
       }
    }
 }

Variable types can be string, integer, array, hash, date, time, datetime, float, double.

=head3 SERVER

A server is an object representing an individual server. A typical server looks like this. This server is configured with the ntp service from above. But with an individual "server" variable.

 {
    "name": "fe01",
    "type": "server",
    "service": {
       "ntp": {
          "configuration": {
             "variables": {
                "server": "pool.ntp.org",
                "restrict": [
                   "127.0.0.1"
                ]
             }
          }
       }
    }
 }

=head2 EXAMPLES

=over 4

=item *

Add a new service

This example will add a service named "ntp". With the configuration structure shown in the example above.

 rex.io --service=ntp --add --desc="NTP Service" --variables='{"configuration": {"server": {"type": "string", "default": "ntp.local.lan"}, "restrict": {"type": "array", "default": ["127.0.0.1"]}}}'

=item *

Add a new server

 rex.io --server=fe01 --add

=item *

Add a service to a server

 rex.io --server=fe01 --service=ntp --add

=item *

Configure a special variable

 rex.io --server=fe01 --service=ntp --section=configuration --variables='{"server": "pool.ntp.org"}'

Or, if you want to configure an array variable

 rex.io --server=fe01 --service=ntp --section=configuration --variables='{"restrict": ["127.0.0.1", "172.16.230.11"]}'

=item *

Remove a service from a server

 rex.io --server=fe01 --service=ntp --rm

=item *

Remove a server

 rex.io --server=fe01 --rm

=item *

Remove a service

 rex.io --service=ntp --rm

=back

=head2 USAGE INSIDE A REXFILE

If you want to use these configurations inside a Rexfile you can do this with the I<cmdb_get()> function.

Example of a Rexfile:

 # Rexfile
 use Rex::IO::Client;
    
 set group => "frontends" => "fe01", "fe02";
    
 task "prepare_ntp", group => "frontends", sub {
    file "/etc/ntp.conf",
       content => template("templates/etc/ntp.conf.tpl", cmdb_get("service://ntp/configuration")),
       owner   => "root",
       mode    => 644;
        
    service ntpd => "start";
 };

And your ntp.conf template file can look like this:

 server  <%= $::server %>
    
 <% for my $restrict_srv (@{ $::restrict }) { %>
 restrict  <%= $restrict_srv %>
 <% } %>
    
 driftfile /var/run/ntp/drift 
