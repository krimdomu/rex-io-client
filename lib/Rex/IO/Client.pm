#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Client;
   
use strict;
use warnings;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(cmdb_get);

use Rex::IO::Client::Protocol;

our $VERSION = "0.30.99.0";

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

sub get_server {
   my ($self, $name) = @_;
   $self->_client->get_server($name);
}

sub add_server {
   my ($self, $name) = @_;
   $self->_client->add_server($name);
}

sub rm_server {
   my ($self, $name) = @_;
   $self->_client->rm_server($name);
}

sub dump {
   my ($self) = @_;
   $self->_client->dump;
}

sub _client {
   my ($self) = @_;
   return Rex::IO::Client::Protocol->factory("V1");
}

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

1;
