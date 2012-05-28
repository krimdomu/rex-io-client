#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Client;
   
use strict;
use warnings;

use Rex::IO::Client::Protocol;

our $VERSION = "0.30.99.0";

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub dump {
   my ($self) = @_;
   $self->_client->dump;
}

sub _client {
   my ($self) = @_;
   return Rex::IO::Client::Protocol->factory("V1");
}

1;
