package ExtUtils::CBuilder::Platform::os2;

use strict;
use ExtUtils::CBuilder::Platform::Unix;

use vars qw(@ISA);
@ISA = qw(ExtUtils::CBuilder::Platform::Unix);

sub need_prelink_objects { 1 }

1;
