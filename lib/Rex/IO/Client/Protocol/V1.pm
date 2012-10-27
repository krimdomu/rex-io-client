#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Client::Protocol::V1;

use strict;
use warnings;

use attributes;

use Mojo::UserAgent;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   $self->{endpoint} ||= "http://127.0.0.1:3000";

   return $self;
}

sub endpoint :lvalue {
   my ($self) = @_;
   $self->{endpoint};
}

sub search_server {
   my ($self, $expr) = @_;
   $self->_get("/hardware/search/$expr")->res->json;
}

sub get_server {
   my ($self, $id) = @_;
   $self->_get("/hardware/$id")->res->json;
}

sub list_os {
   my ($self) = @_;
   $self->_list("/os")->res->json;
}

sub list_os_templates {
   my ($self) = @_;
   $self->_list("/os-template")->res->json;
}

sub _ua {
   my ($self) = @_;
   return Mojo::UserAgent->new;
}

sub _get {
   my ($self, $url) = @_;
   $self->_ua->get($self->endpoint . $url);
}

sub _list {
   my ($self, $url) = @_;
   my $tx = $self->_ua->build_tx(LIST => $self->endpoint . $url);
   $self->_ua->start($tx);
}


1;
