#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Client::Protocol::V1;

use strict;
use warnings;

use attributes;

use JSON::XS;
use Mojo::UserAgent;
use Data::Dumper;
use Redis;
use Mojo::JSON;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   bless($self, $proto);

   $self->{endpoint} ||= "http://127.0.0.1:3000";
   $self->{redis} = Redis->new(server => "127.0.0.1:6379");

   return $self;
}

sub auth {
   my ($self, $user, $pass) = @_;
   $self->{username} = $user;
   $self->{password} = $pass;

   my $data = decode_json($self->_post("/auth", {user => $user, password => $pass})->res->body);

   if($data->{ok}) {
      return $data->{data};
   }

   return;
}

sub get_user {
   my ($self, $id) = @_;
   my $ret = decode_json($self->_get("/user/$id")->res->body);
   if($ret->{ok}) {
      return $ret->{data};
   }
   return;
}

sub get_group {
   my ($self, $id) = @_;
   my $ret = decode_json($self->_get("/group/$id")->res->body);
   if($ret->{ok}) {
      return $ret->{data};
   }
   return;
}

sub list_users {
   my ($self) = @_;
   my $ret = decode_json($self->_list("/user")->res->body);
   if($ret->{ok}) {
      return $ret->{data};
   }
   return;
}

sub list_groups {
   my ($self) = @_;
   my $ret = decode_json($self->_list("/group")->res->body);
   if($ret->{ok}) {
      return $ret->{data};
   }
   return;
}

sub add_user {
   my ($self, %option) = @_;
   $self->_post("/user", \%option)->res->json;
}

sub add_group {
   my ($self, %option) = @_;
   $self->_post("/group", \%option)->res->json;
}

sub del_user {
   my ($self, $user_id) = @_;
   $self->_delete("/user/$user_id")->res->json;
}

sub del_group {
   my ($self, $group_id) = @_;
   $self->_delete("/group/$group_id")->res->json;
}

sub add_user_to_group {
   my ($self, $user_id, $group_id) = @_;
   $self->_post("/group/$group_id/user/$user_id")->res->json;
}

sub add_incident {
   my ($self, %option) = @_;
   $self->_post("/incident", \%option)->res->json;
}

sub update_incident_status {
   my ($self, $incident_id, $status_id) = @_;
   $self->_post("/incident/$incident_id/status", { status_id => $status_id })->res->json;
}

sub add_incident_message {
   my ($self, $incident_id, %option) = @_;
   $self->_post("/incident/$incident_id/message", \%option)->res->json;
}

sub list_incidents {
   my ($self) = @_;
   my $res = decode_json($self->_list("/incident")->res->body);

   if($res->{ok}) {
      return $res->{data};
   }
   return;
}

sub list_incident_messages {
   my ($self, $incident_id) = @_;
   my $res = decode_json($self->_list("/incident/$incident_id/message")->res->body);
   
   if($res->{ok}) {
      return $res->{data};
   }

   return;
}

sub get_incident {
   my ($self, $incident_id) = @_;
   $self->_get("/incident/$incident_id")->res->json;
}

sub list_incident_status {
   my ($self) = @_;

   my $res = decode_json($self->_list("/incident/status")->res->body);
   
   if($res->{ok}) {
      return $res->{data};
   }

   return;
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
   decode_json($self->_get("/hardware/$id")->res->body);
}

sub add_server {
   my ($self, $mac, %option) = @_;
   $self->_post("/host/$mac", { %option })->res->json;
}

sub del_server {
   my ($self, $srv_id) = @_;
   $self->_delete("/hardware/$srv_id")->res->json;
}

sub get_plugins {
   my ($self) = @_;
   $self->_get("/plugins")->res->json;
}

sub list_os {
   my ($self) = @_;
   $self->_list("/os")->res->json;
}

sub list_hosts {
   my ($self) = @_;
   decode_json($self->_list("/host")->res->body);
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

sub list_online_ips {
   my ($self) = @_;
   $self->_list("/messagebroker/clients?only_ip=true")->res->json;
}

sub list_services {
   my ($self) = @_;
   $self->_list("/service")->res->json;
}

sub get_service {
   my ($self, $service) = @_;
   $self->_list("/service/$service")->res->json;
}

sub add_task_to_host {
   my ($self, %option) = @_;
   $self->_post("/service/host/" . $option{host} . "/task/" . $option{task}, {task_order => ($option{task_order} || 0)})->res->json;
}

sub run_tasks {
   my ($self, @tasks) = @_;
   $self->_run("/service", \@tasks)->res->json;
}

sub run_task_on_host {
   my ($self, %option) = @_;
   $self->_run("/service/host/" . $option{host} . "/task/" . $option{task})->res->json;
}

sub remove_all_tasks_from_host {
   my ($self, $host) = @_;
   $self->_delete("/service/host/$host")->res->json;
}

sub list_services_of_host {
   my ($self, $host) = @_;
   $self->_list("/service/host/$host")->res->json;
}

sub is_online {
   my ($self, $ip) = @_;
   $self->_get("/messagebroker/online/$ip")->res->json;
}

sub trigger_inventory {
   my ($self, $ip) = @_;
   $self->_post("/messagebroker/$ip", {type => "inventory"})->res->json;
}

sub trigger_reboot {
   my ($self, $ip) = @_;
   $self->_post("/messagebroker/$ip", {type => "exec", exec => "/sbin/reboot"})->res->json;
}

sub send_command_to {
   my ($self, $ip, $command) = @_;
   $self->_post("/messagebroker/$ip", $command)->res->json;
}

sub list_alerts {
   my ($self) = @_;
   $self->_list("/monitor/alerts")->res->json;
}

sub list_alerts_of_host {
   my ($self, $host_id) = @_;
   $self->_list("/monitor/alerts/$host_id")->res->json;
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

sub add_dns_record {
   my ($self, $domain, $host, %option) = @_;
   $self->_post("/dns/$domain/$host", \%option)->res->json;   
}

sub del_dns_record {
   my ($self, $domain, $host, $type) = @_;
   $self->_delete("/dns/$domain/$type/$host")->res->json;
}

sub save_deploy_os {
   my ($self, $id, %data) = @_;
   $self->_put("/deploy/os/$id", { %data })->res->json;
}

sub get_monitoring_items_of_host {
   my ($self, $host_id) = @_;
   $self->_list("/monitor/host/$host_id/item")->res->json;
}

sub get_log_of_host {
   my ($self, $host_id, %opt) = @_;
   $self->_post("/log/server/$host_id", \%opt)->res->json;
}

sub get_server_count {
   my ($self) = @_;
   $self->_count("/host")->res->json;
}

sub get_operating_systems {
   my ($self) = @_;
   $self->_count("/host/os")->res->json;
}

sub add_server_group {
   my ($self, %option) = @_;
   $self->_post("/server_group", \%option)->res->json;
}

sub del_server_group {
   my ($self, $group_id) = @_;
   $self->_delete("/server_group/$group_id")->res->json;
}

sub list_server_groups {
   my ($self) = @_;
   $self->_list("/server_group")->res->json;
}

sub add_server_to_server_group {
   my ($self, $server_id, $group_id) = @_;
   $self->_post("/server_group/server/$server_id/$group_id")->res->json;
}

sub list_monitoring_templates {
   my ($self) = @_;
   my $data = decode_json($self->_list("/monitor/template")->res->body);

   if($data->{ok}) {
      return $data->{data};
   }
}

sub add_monitoring_template {
   my ($self, %option) = @_;
   $self->_post("/monitor/template", \%option)->res->json;
}

sub del_monitoring_template {
   my ($self, $id) = @_;
   $self->_delete("/monitor/template/$id")->res->json;
}

sub add_monitoring_item {
   my ($self, $template_id, %option) = @_;
   $self->_post("/monitor/template/$template_id/item", \%option)->res->json;
}

sub del_monitoring_item {
   my ($self, $template_id, $item_id) = @_;
   $self->_delete("/monitor/template/$template_id/item/$item_id")->res->json;
}

sub list_monitoring_item_of_template {
   my ($self, $template_id) = @_;
   my $data = decode_json($self->_list("/monitor/template/$template_id")->res->body);

   if($data->{ok}) {
      return $data->{data};
   }
}

sub get_monitoring_template {
   my ($self, $template_id) = @_;
   my $data = decode_json($self->_get("/monitor/template/$template_id")->res->body);

   if($data->{ok}) {
      return $data->{data};
   }
}

sub get_monitoring_item {
   my ($self, $template_id, $item_id) = @_;
   my $data = decode_json($self->_get("/monitor/template/$template_id/item/$item_id")->res->body);

   if($data->{ok}) {
      return $data->{data};
   }
}

sub update_monitoring_item {
   my ($self, $template_id, $item_id, %option) = @_;
   $self->_post("/monitor/template/$template_id/item/$item_id", \%option)->res->json;
}

sub add_monitoring_template_to_host {
   my ($self, $template_id, $host_id) = @_;
   $self->_post("/monitor/template/$template_id/host/$host_id")->res->json;
}


sub _ua {
   my ($self) = @_;
   if($self->{ua}) {
      return $self->{ua};
   }

   my $ua = Mojo::UserAgent->new;

   if($self->{ssl}) {
      $ua->ca($self->{ssl}->{ca});
      $ua->cert($self->{ssl}->{cert});
      $ua->key($self->{ssl}->{key});
   }

   $self->{ua} = $ua;
   return $self->{ua};
}

sub _get {
   my ($self, $url) = @_;
   $self->_ua->get($self->endpoint . $url);
}

sub _post {
   my ($self, $url, $post) = @_;
   $self->_ua->post($self->endpoint . $url, json => $post);
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

sub _info {
   my ($self, $url) = @_;
   my $tx = $self->_ua->build_tx(INFO => $self->endpoint . $url);
   $self->_ua->start($tx);
}

sub _run {
   my ($self, $url, $obj) = @_;
   $obj ||= {};

   my $tx = $self->_ua->build_tx(RUN => $self->endpoint . $url, json => $obj);
   $self->_ua->start($tx);
}

sub _delete {
   my ($self, $url) = @_;
   my $tx = $self->_ua->build_tx(DELETE => $self->endpoint . $url);
   $self->_ua->start($tx);
}

sub _count {
   my ($self, $url) = @_;
   my $tx = $self->_ua->build_tx(COUNT => $self->endpoint . $url);
   $self->_ua->start($tx);
}

sub _json {
   my ($self) = @_;
   return Mojo::JSON->new;
}

## new urls
# $VERB /1.0/plugin/resource/subres/id
# GET /1.0/hardware/server/5   -> get hardware id 5
# GET /1.0/hardware/server    -> get hardware list

sub clear_call_cache {
   my ($self, $key) = @_;

   my @keys = $self->{redis}->keys("rexioclient:$key");
   for my $key (@keys) {
      $self->{redis}->del($key);
   }
}

sub call_no_cache {
   my ($self, $verb, $version, $plugin, @param) = @_;

   my $url = "/$version/$plugin";
   my $ref;

   #for my $key (@param) {
   while(my $key = shift @param) {
      my $value = shift @param;
      if($key eq "ref") {
         $ref = $value;
         next;
      }

      $url .= "/$key";

      if(defined $value) {
         $url .= "/$value";
      }
   }

   my $meth = "_\L$verb";

   my $ret;

   if(ref $ref) {
      $ret = $self->$meth($url, $ref);
   }
   else {
      $ret = $self->$meth($url);
   }

   return decode_json($ret->res->body);
}

sub call {
   my ($self, $verb, $version, $plugin, @param) = @_;

   my @param_clean = grep { defined $_ && ! ref $_ } @param;
   my $key = "rexioclient:$verb:$version:$plugin:" . join(":", @param_clean);

   my $url = "/$version/$plugin";

   my $ref;

   if($verb eq "POST" || $verb eq "PUT" || $verb eq "DELETE") {
      my $__tmp = { @param };
      if(exists $__tmp->{server}) {
         my @keys = $self->{redis}->keys('rexioclient:*:server:' . $__tmp->{server} . ':*');
         map { $self->{redis}->del($_); } @keys;
      }
   }

   if($verb eq "GET" || $verb eq "LIST" || $verb eq "INFO") {
      my $redis_ret = $self->{redis}->get($key);
      if($redis_ret) {
         return decode_json($redis_ret);
      }
   }

   #for my $key (@param) {
   while(my $key = shift @param) {
      my $value = shift @param;
      if($key eq "ref") {
         $ref = $value;
         next;
      }

      $url .= "/$key";

      if(defined $value) {
         $url .= "/$value";
      }
   }

   my $meth = "_\L$verb";

   my $ret;

   if(ref $ref) {
      $ret = $self->$meth($url, $ref);
   }
   else {
      $ret = $self->$meth($url);
   }

   if($verb eq "GET" || $verb eq "LIST" || $verb eq "INFO") {
      $self->{redis}->set($key, $ret->res->body);
      $self->{redis}->expireat($key, time + 180);
   }

   return decode_json($ret->res->body);
}


1;
