package ExtUtils::CBuilder::Platform::Windows;

use strict;
use ExtUtils::CBuilder::Base;

use vars qw(@ISA);
@ISA = qw(ExtUtils::CBuilder::Base);

sub need_prelink_objects { 1 }

1;
