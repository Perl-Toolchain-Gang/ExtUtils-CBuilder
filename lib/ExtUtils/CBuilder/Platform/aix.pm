package ExtUtils::CBuilder::Platform::aix;

use strict;
use ExtUtils::CBuilder::Platform::Unix;
use File::Spec;

use vars qw(@ISA);
@ISA = qw(ExtUtils::CBuilder::Platform::Unix);

sub need_prelink_objects { 1 }

sub link_objects {
  my ($self, %args) = @_;
  my $cf = $self->{config};

  (my $baseext = $args{module_name}) =~ s/.*:://;
  my $perl_inc = File::Spec->catdir($cf->{archlibexp}, 'CORE'); #location of perl.exp
  
  # Massage some very naughty bits in %Config
  local $cf->{lddlflags} = $cf->{lddlflags};
  for ($cf->{lddlflags}) {
    s/\Q$(BASEEXT)\E/$baseext/;
    s/\Q$(PERL_INC)\E/$perl_inc/;
  }

  return $self->SUPER::link_objects(%args);
}


1;
