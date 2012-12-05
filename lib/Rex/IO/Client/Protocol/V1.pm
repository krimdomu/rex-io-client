#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Client::Protocol::V1;

use strict;
use warnings;

use attributes;

use Mojo::JSON;
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

sub add_server {
   my ($self, $mac, %option) = @_;
   $self->_post("/host/$mac", { %option })->res->json;
}

sub list_os {
   my ($self) = @_;
   $self->_list("/os")->res->json;
}

sub list_hosts {
   my ($self) = @_;
   $self->_list("/host")->res->json;
}

sub add_os_template {
   my ($self, %option) = @_;
   $self->_post("/os-template", { %option })->res->json;
}

sub update_network_adapter {
   my ($self, $id, %option) = @_;
   $self->_post("/network-adapter/$id", { %option })->res->json;
}

sub list_os_templates {
   my ($self) = @_;
   $self->_list("/os-template")->res->json;
}

sub set_next_boot {
   my ($self, %option) = @_;

   unless($option{boot} =~ m/^\d+$/) {
      my $templates = $self->list_os_templates;
      for my $t (@{ $templates }) {
         if($t->{name} eq $option{boot}) {
            $option{boot} = $t->{id};
            last;
         }
      }
   }

   unless($option{server} =~ m/^\d+$/) {
      my $server = $self->search_server($option{server});
      $option{server} = $server->[0]->{id};
   }

   $self->_post("/hardware/$option{server}", {os_template_id => $option{boot}})->res->json;
}

sub update_server {
   my ($self, $srv_id, %option) = @_;
   $self->_post("/hardware/$srv_id", \%option)->res->json;
}

sub get_dns_tlds {
   my ($self) = @_;
   $self->_list("/dns")->res->json;
}

sub get_dns_tld {
   my ($self, $tld) = @_;
   $self->_list("/dns/$tld")->res->json;
}

sub get_dhcp_leases {
   my ($self) = @_;
   $self->_list("/dhcp")->res->json;
}

sub get_deploy_oses {
   my ($self) = @_;
   $self->_list("/deploy/os")->res->json;
}

sub save_deploy_os {
   my ($self, $id, %data) = @_;
   $self->_put("/deploy/os/$id", { %data })->res->json;
}

sub _ua {
   my ($self) = @_;
   return Mojo::UserAgent->new;
}

sub _get {
   my ($self, $url) = @_;
   $self->_ua->get($self->endpoint . $url);
}

sub _post {
   my ($self, $url, $post) = @_;
   $self->_ua->post_json($self->endpoint . $url, $post);
}

sub _put {
   my ($self, $url, $put) = @_;
   $self->_ua->put($self->endpoint . $url, $self->_json->encode($put));
}

sub _list {
   my ($self, $url) = @_;
   my $tx = $self->_ua->build_tx(LIST => $self->endpoint . $url);
   $self->_ua->start($tx);
}

sub _json {
   my ($self) = @_;
   return Mojo::JSON->new;
}


1;
