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

   if(! exists $conf->{server}) {
      my @cfg = ("/etc/rex/io/client.conf", "/usr/local/etc/rex/io/client.conf", "client.conf");

      my $cfg;
      for my $file (@cfg) {
         if(-f $file) {
            $cfg = $file;
            last;
         }
      }

      unless($cfg) {
         print "No configuration file found.\n";
         print "Please create a configuration file in one of the following locations:\n";
         print " * " . join("\n * ", @cfg);
         print "\n";

         exit 1;
      }

      __PACKAGE__->load(file => $cfg);

   }

   return $conf;
}

1;
