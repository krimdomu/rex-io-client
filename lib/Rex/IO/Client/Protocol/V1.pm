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
use Rex::IO::Client::Config;


sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   return $self;
}

sub get_information {
   my ($self, $host) = @_;

   if(! $host) {
      my %hw_info = Rex::Hardware->get(qw/Host/);
      $host = $hw_info{Host}->{hostname};
   }

   my $io_server = $self->_server;
   my $tx = $self->_ua->get("$io_server/server/$host");
   if($tx->success) {
      my $data = $self->_json->decode($tx->res->body)->{data};

      delete $data->{name};
      delete $data->{type};

      return $data;
   }
   else {
      my ($message, $code) = $tx->error;
      if($code == 404) {
         die("Client (" . $host . ") not found.");
      }

      die("Unknown error.");
   }

}

sub get {
   my ($self, %option) = @_;

   my $info = $self->get_information();
   my $data = $info->{$option{type}}->{$option{module}}->{$option{key}};

   # perhaps someone use a filename as a key 
   # like /etc/ntp.conf and forgot one "/"
   # service://ntp/etc/ntp.conf (wrong)
   # service://ntp//etc/ntp.conf (right)
   if(! $data) {
      $data = $info->{$option{type}}->{$option{module}}->{"/".$option{key}};
   }

   return $data;
}

sub get_server {
   my ($self, $server) = @_;
   return $self->get_information($server);
}

sub add_server {
   my ($self, $server, $option) = @_;

   $option ||= {};
   my $ref = $option;
   $ref->{name} = $server;

   my $io_server = $self->_server;
   my $tx = $self->_ua->post("$io_server/server",
      { "Content-Type" => "application/json" },
      Mojo::JSON->encode($ref),
   );

   if($tx->success) {
      return $self->_json->decode($tx->res->body);
   }

   die("Can't add server");
}

sub rm_server {
   my ($self, $server) = @_;

   my $io_server = $self->_server;
   my $tx = $self->_ua->delete("$io_server/server/$server");

   if($tx->success) {
      return $self->_json->decode($tx->res->body);
   }

   die("Can't delete server");
}

sub get_service {
   my ($self, $service) = @_;

   my $io_server = $self->_server;
   my $tx = $self->_ua->get("$io_server/service/$service");
   if($tx->success) {
      my $data = $self->_json->decode($tx->res->body)->{data};

      delete $data->{name};
      delete $data->{type};

      return $data;
   }
   else {
      my ($message, $code) = $tx->error;
      if($code == 404) {
         die("Service (" . $service . ") not found.");
      }

      die("Unknown error.");
   }

}

sub add_service {
   my ($self, $service, $option) = @_;

   $option ||= {};
   my $ref = $option;
   $ref->{name} = $service;

   my $io_server = $self->_server;
   my $tx = $self->_ua->post("$io_server/service",
      { "Content-Type" => "application/json" },
      Mojo::JSON->encode($ref),
   );

   if($tx->success) {
      return $self->_json->decode($tx->res->body);
   }

   die("Can't add service");
}

sub rm_service {
   my ($self, $server) = @_;

   my $io_server = $self->_server;
   my $tx = $self->_ua->delete("$io_server/service/$server");

   if($tx->success) {
      return $self->_json->decode($tx->res->body);
   }

   die("Can't delete service");
}

sub list_server {
   my ($self) = @_;

   my $io_server = $self->_server;
   my $tx = $self->_ua->build_tx(LIST => "$io_server/server");
   $self->_ua->start($tx);

   if($tx->success) {
      return $self->_json->decode($tx->res->body);
   }

   die("Can't list servers");
}

sub list_service {
   my ($self) = @_;

   my $io_server = $self->_server;
   my $tx = $self->_ua->build_tx(LIST => "$io_server/service");
   $self->_ua->start($tx);

   if($tx->success) {
      return $self->_json->decode($tx->res->body);
   }

   die("Can't list services");
}


sub add_service_to_server {
   my ($self, $server, $service) = @_;

   my $io_server = $self->_server;
   my $tx = $self->_ua->build_tx(LINK => "$io_server/server/$server" => { "Content-Type" => "application/json" } => Mojo::JSON->encode({service => $service}));
   $self->_ua->start($tx);

   if($tx->success) {
      return $self->_json->decode($tx->res->body);
   }

   die("Can't add service to server");
}

sub remove_service_from_server {
   my ($self, $server, $service) = @_;

   my $io_server = $self->_server;
   my $tx = $self->_ua->build_tx(UNLINK => "$io_server/server/$server" => { "Content-Type" => "application/json" } => Mojo::JSON->encode({service => $service}));
   $self->_ua->start($tx);

   if($tx->success) {
      return $self->_json->decode($tx->res->body);
   }

   die("Can't remove service from server");
}

sub configure_service_of_server {
   my ($self, $server, $service, $data) = @_;

   my $io_server = $self->_server;
   my $tx = $self->_ua->put("$io_server/server/$server/service/$service" => { "Content-Type" => "application/json" } => Mojo::JSON->encode($data));

   if($tx->success) {
      return $self->_json->decode($tx->res->body);
   }

   die("Can't configure service $service of server $server.");
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

sub _server {
   my ($self) = @_;
   return Rex::IO::Client::Config->get()->{"server"};
}

1;
