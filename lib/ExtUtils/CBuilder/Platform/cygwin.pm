package ExtUtils::CBuilder::Platform::cygwin;

use strict;
use File::Spec;
use ExtUtils::CBuilder::Platform::Unix;

use vars qw(@ISA);
@ISA = qw(ExtUtils::CBuilder::Platform::Unix);

sub link_objects {
  my ($self, %args) = @_;
  
  $args{extra_linker_flags} = ['-L'.File::Spec->catdir($self->{config}{archlibexp}, 'CORE'),
			       '-lperl',
			       $self->split_like_shell($args{extra_linker_flags})];
  return $self->SUPER::link_c(%args);
}

1;
