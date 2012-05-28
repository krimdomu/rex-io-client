#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Client::Protocol;
   
use strict;
use warnings;

sub factory {
   my ($class, $protocol) = @_;

   $protocol = "Rex::IO::Client::Protocol::$protocol";
   eval "use $protocol;";

   if($@) {
      die($@);
   }

   return $protocol->new;
}

1;
