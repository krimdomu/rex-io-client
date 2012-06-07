#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
=head1 NAME

Rex::IO::Client - Client Library for Rex::IO::Server

=head1 GETTING HELP

=over 4

=item * IRC: irc.freenode.net #rex

=item * Bug Tracker: L<https://github.com/krimdomu/rex-io-client/issues>

=back

=head1 METHODS

=over 4

=cut

package Rex::IO::Client;
   
use strict;
use warnings;
use Data::Dumper;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(cmdb_get);

use Rex::IO::Client::Config;
use Rex::IO::Client::Protocol;

our $VERSION = "0.0.6";

=item new()

Constructor

=cut

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub get {
   my ($self, %option) = @_;
   return $self->_client->get(%option);   
}

sub get_variables {
   my ($self, %option) = @_;
   my $ret = $self->get(%option);

   return $ret->{variables};
}

=item get_service($service)

Request information of $service.

=cut
sub get_service {
   my ($self, $name) = @_;
   $self->_client->get_service($name);
}


=item add_service($service, $option)

Create a new service $service with the options provided by $option. $option is a hashRef.

=cut
sub add_service {
   my ($self, $name, $option) = @_;
   $self->_client->add_service($name, $option);
}

=item rm_service($name)

Remove $service.

=cut
sub rm_service {
   my ($self, $name) = @_;
   $self->_client->rm_service($name);
}

=item get_server($server)

Request information of $server.

=cut
sub get_server {
   my ($self, $name) = @_;
   $self->_client->get_server($name);
}

=item add_server($name, $option)

Create a new server $name. With the options provided by $option. $option is a hashRef.

=cut
sub add_server {
   my ($self, $name, $option) = @_;
   $self->_client->add_server($name, $option);
}

sub rm_server {
   my ($self, $name) = @_;
   $self->_client->rm_server($name);
}

sub dump {
   my ($self) = @_;
   $self->_client->dump;
}

=item list_server()

Returns a list of all servers known to the CMDB.

=cut
sub list_server {
   my ($self) = @_;
   $self->_client->list_server();
}

=item list_service()

Returns a list of all services kown to the CMDB.

=cut
sub list_service {
   my ($self) = @_;
   $self->_client->list_service();
}

sub add_service_to_server {
   my ($self, $server, $service) = @_;
   $self->_client->add_service_to_server($server, $service);
}

sub remove_service_from_server {
   my ($self, $server, $service) = @_;
   $self->_client->remove_service_from_server($server, $service);
}

sub configure_service_of_server {
   my ($self, $server, $service, $section, $variables) = @_;
   $self->_client->configure_service_of_server($server, $service, {
      $section => {
         variables => $variables,
      }
   });
}

sub download_service {
   my ($self, $service) = @_;
   $self->_client->download_service($service);
}

sub download_and_apply_service {
   my ($self, $service) = @_;

   eval {
      $self->download_service($service);
   };

   if($@) { print "Error downloading $service.\n"; next; }

   chdir "$service";
   system("rex __io__");
   chdir "..";

   if($? != 0) {
      print "Error applying $service.\n";
      next;
   }

}

sub download_and_apply_services {
   my ($self) = @_;
   
   my $server = $self->get_server;
   if(! ref($server)) {
      die("Can't get service list. Exiting.");
   }

   my $service = $server->{service};

   for my $service_key (keys %{ $service }) {
      $self->download_and_apply_service($service_key);
   }
}

sub _client {
   my ($self) = @_;
   return Rex::IO::Client::Protocol->factory("V1");
}


=back

=head1 FUNCTIONS

=over 4

=item cmdb_get($key)

You can use this function inside your I<Rexfile> to get configuration parameters from L<Rex::IO::CMDB>.

 my @configuration = cmdb_get("service://$service_name/$service_section");

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

=cut

# static function
sub cmdb_get {
   my ($type, $module, $key) = ($_[0] =~ m/^([a-zA-Z]+):\/\/([a-zA-Z_\-\.]+)\/(.*)$/);
   my $client = __PACKAGE__->new;

   my $ret = $client->get_variables(
                type   => $type,
                module => $module,
                key    => $key,
   );

   return %{ $ret };
}

=back

=cut

1;
