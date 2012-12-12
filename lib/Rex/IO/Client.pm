#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
=head1 NAME

Rex::IO::Client - Client Library for Rex::IO::Server

=head1 GETTING HELP

=over 4

=item * IRC: irc.freenode.net #rex

=item * Bug Tracker: L<https://github.com/krimdomu/rex-io-client/issues>

=back

=head1 METHODS

=over 4

=cut

package Rex::IO::Client;
   
use strict;
use warnings;
use Data::Dumper;

our $VERSION = "0.0.8";

sub create {

   my ($class, %option) = @_;

   my $version = $option{protocol} || 1;

   my $klass = "Rex::IO::Client::Protocol::V$version";
   eval "use $klass";

   if($@) {
      die("Protocol Version $version not found.");
   }

   return $klass->new(%option);
}


1;
