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

=head1 FUNCTIONS

=over 4

=cut

package Rex::IO::Client;
   
use strict;
use warnings;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(cmdb_get);

use Rex::IO::Client::Protocol;

our $VERSION = "0.0.1";

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

sub get_service {
   my ($self, $name) = @_;
   $self->_client->get_service($name);
}

sub add_service {
   my ($self, $name, $option) = @_;
   $self->_client->add_service($name, $option);
}

sub rm_service {
   my ($self, $name) = @_;
   $self->_client->rm_service($name);
}

sub get_server {
   my ($self, $name) = @_;
   $self->_client->get_server($name);
}

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

sub list_server {
   my ($self) = @_;
   $self->_client->list_server();
}

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

sub _client {
   my ($self) = @_;
   return Rex::IO::Client::Protocol->factory("V1");
}

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
