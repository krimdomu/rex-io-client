#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Client::Config;
   
use strict;
use warnings;

use vars qw($conf);

sub load {
   my ($class, %data) = @_;

   $conf = {};
   $data{file} ||= "client.conf";

   if(exists $data{file} && -f $data{file}) {
      my $code = eval { local(@ARGV, $/) = ($data{file}); <>; };
      $conf = eval $code;
      if($@) {
         die("Error parsing configuration file! $@");
      }
   }
   else {
      $conf->{server} = "http://rex-server:3000";
   }
}

sub get {
   my ($class) = @_;
   return $conf;
}

1;
