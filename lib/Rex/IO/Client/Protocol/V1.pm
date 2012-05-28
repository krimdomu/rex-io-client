#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Client::Protocol::V1;
   
use strict;
use warnings;

use Mojo::UserAgent;
use Mojo::JSON;

use Rex::Hardware;
use Data::Dumper;
use YAML;

my $io_server = "http://localhost:3000";

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub get_information {
   my ($self) = @_;

   my %hw_info = Rex::Hardware->get(qw/Host/);

   my $tx = $self->_ua->get("$io_server/server/" . $hw_info{Host}->{hostname});
   if($tx->success) {
      my $data = $self->_json->decode($tx->res->body)->{data};

      delete $data->{name};
      delete $data->{type};

      return $data;
   }
   else {
      my ($message, $code) = $tx->error;
      if($code == 404) {
         die("Client not found.");
      }

      die("Unknown error.");
   }

}

sub dump {
   my ($self) = @_;
   print Dump($self->get_information);
}

sub _json {
   my ($self) = @_;
   return Mojo::JSON->new;
}

sub _ua {
   my ($self) = @_;
   return Mojo::UserAgent->new;
}

1;
