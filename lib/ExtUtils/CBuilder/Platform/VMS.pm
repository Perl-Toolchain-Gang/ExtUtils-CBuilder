package ExtUtils::CBuilder::Platform::VMS;

use strict;
use ExtUtils::CBuilder::Base;

use vars qw(@ISA);
@ISA = qw(ExtUtils::CBuilder::Base);

sub need_prelink { 1 }

1;
