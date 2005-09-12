package ExtUtils::CBuilder::Platform::VMS;

use strict;
use ExtUtils::CBuilder::Base;

use vars qw($VERSION @ISA);
$VERSION = '0.12';
@ISA = qw(ExtUtils::CBuilder::Base);

sub need_prelink { 1 }

sub arg_include_dirs {
  my ($self, @dirs) = @_;

  # VMS can only have one include list, remove the one from config.
  if ($self->{config}{ccflags} =~ s{/include=\(([^\)]*)\)} {}i) {
    unshift @dirs, $1;
  }
  return unless @dirs;

  return ('/include=(' . join(',', @dirs) . ')');
}

sub _do_link {
  my ($self, $type, %args) = @_;
  
  my $objects = delete $args{objects};
  $objects = [$objects] unless ref $objects;
  
  # VMS has two option files, the external symbol, and to pull in PerlShr
  $objects->[-1] .= ',';
  push @$objects, 'sys$disk:[]' . @temp_files[0] . '/opt,';
  push @$objects, $self->perl_inc() . 'PerlShr.Opt/opt';

  # Need to create with the same name as DynaLoader will load with.
  if (defined &DynaLoader::mod2fname) {
    my $out = $args{$type} || $self->$type($objects->[0]);
    my ($dev,$dir,$file) = File::Spec->splitpath($out);
    $file = DynaLoader::mod2fname([$file]);
    $args{$type} = File::Spec->catpath($dev,$dir,$file);
  }

  return $self->SUPER::_do_link($type, %args, objects => $objects);
}

sub arg_nolink { return; }

sub arg_object_file {
  my ($self, $file) = @_;
  return "/obj=$file";
}

sub arg_exec_file {
  my ($self, $file) = @_;
  return ("/exe=$file");
}

sub arg_share_object_file {
  my ($self, $file) = @_;
  return ("$self->{config}{lddlflags}=$file");
}

1;
