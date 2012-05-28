#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Client::Args;
   
use strict;
use warnings;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT %OPTS);
    
@EXPORT = qw(getopts);

sub getopts {
   my (%opts) = @_;

   my @params = @ARGV[0..$#ARGV];

   for my $p (@params) {
      my($key, $val) = split(/=/, $p, 2);
      $val ||= 1;

      $key =~ s/^--//;

      $OPTS{$key} = $val;

      if(exists $opts{$key}) {
         my $code = $opts{$key};
         &$code($val);
      }
   }

}

sub get {
   my ($class) = @_;
   return %OPTS;
}

1;
