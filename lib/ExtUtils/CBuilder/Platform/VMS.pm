package ExtUtils::CBuilder::Platform::VMS;

use strict;
use ExtUtils::CBuilder::Base;

use vars qw(@ISA);
@ISA = qw(ExtUtils::CBuilder::Base);

sub need_prelink { 1 }

sub arg_include_dirs {
  my $self = shift;
  return '/include=(' . join(',', @_) . ')';
}

sub arg_nolink { }

sub arg_object_file {
  my ($self, $file) = @_;
  return "/obj=$file";
}



1;
