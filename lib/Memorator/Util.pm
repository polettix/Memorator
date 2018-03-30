package Memorator::Util;
use strict;
use warnings;
{ our $VERSION = '0.001'; }

sub local_name {
   my ($name, $suffix) = @_;
   (my $retval = $name . '_' . $suffix) =~ s{\W}{_}gmxs;
   return $retval;
}

1;
