package ExtUtils::CBuilder::Base;

use strict;
use File::Spec;
use File::Basename;
use Config;
use Text::ParseWords;

use vars qw($VERSION);
$VERSION = '0.00_01';

sub new {
  my $class = shift;
  my $self = bless {@_}, $class;

  $self->{properties}{perl} = $class->find_perl_interpreter
    or warn "Warning: Can't locate your perl binary";

  while (my ($k,$v) = each %Config) {
    $self->{config}{$k} = $v unless exists $self->{config}{$k};
  }
  return $self;
}

sub find_perl_interpreter {
  my $perl;
  File::Spec->file_name_is_absolute($perl = $^X)
    or -f ($perl = $Config::Config{perlpath})
    or ($perl = $^X);
  return $perl;
}

sub add_to_cleanup {
  my $self = shift;
  my %files = map {$_, 1} @_;
}

sub object_file {
  my ($self, $filename) = @_;

  # File name, minus the suffix
  (my $file_base = $filename) =~ s/\.[^.]+$//;
  return "$file_base$self->{config}{obj_ext}";
}

sub arg_include_dirs {
  my $self = shift;
  return map {"-I$_"} @_;
}

sub arg_nolink { '-c' }

sub arg_object_file {
  my ($self, $file) = @_;
  return ('-o', $file);
}

sub compile {
  my ($self, %args) = @_;
  die "Missing 'source' argument to compile()" unless defined $args{source};
  
  my $cf = $self->{config}; # For convenience

  $args{object_file} ||= $self->object_file($args{source});
  
  my @include_dirs = $self->arg_include_dirs
    (@{$args{include_dirs} || []},
     File::Spec->catdir($cf->{installarchlib}, 'CORE'));
  
  my @extra_compiler_flags = $self->split_like_shell($args{extra_compiler_flags});
  my @cccdlflags = $self->split_like_shell($cf->{cccdlflags});
  my @ccflags = $self->split_like_shell($cf->{ccflags});
  my @optimize = $self->split_like_shell($cf->{optimize});
  my @flags = (@include_dirs, @cccdlflags, @extra_compiler_flags,
	       $self->arg_nolink,
	       @ccflags, @optimize,
	       $self->arg_object_file($args{object_file}),
	      );
  
  my @cc = $self->split_like_shell($cf->{cc});
  
  $self->do_system(@cc, @flags, $args{source})
    or die "error building $args{object_file} from '$args{source}'";

  return $args{object_file};
}

sub have_compiler {
  my ($self) = @_;
  return $self->{have_compiler} if defined $self->{have_compiler};
  
  my $tmpfile = File::Spec->catfile(File::Spec->tmpdir, 'compilet.c');
  {
    local *FH;
    open FH, "> $tmpfile" or die "Can't create $tmpfile: $!";
    print FH "int boot_compilet() { return 1; }\n";
    close FH;
  }

  my ($obj_file, @lib_files);
  eval {
    $obj_file = $self->compile(source => $tmpfile);
    @lib_files = $self->link(objects => $obj_file, module_name => 'compilet');
  };
  warn $@ if $@;
  my $result = $self->{have_compiler} = $@ ? 0 : 1;
  
  foreach (grep defined, $tmpfile, $obj_file, @lib_files) {
    1 while unlink;
  }
  return $result;
}

sub lib_file {
  my ($self, $dl_file) = @_;
  $dl_file =~ s/\.[^.]+$//;
  $dl_file =~ tr/"//d;
  return "$dl_file.$self->{config}{dlext}";
}


sub exe_file {
  my ($self, $dl_file) = @_;
  $dl_file =~ s/\.[^.]+$//;
  $dl_file =~ tr/"//d;
  return "$dl_file$self->{config}{_exe}";
}

sub need_prelink { 0 }

sub prelink {
  my ($self, %args) = @_;
  
  ($args{dl_file} = $args{dl_name}) =~ s/.*::// unless $args{dl_file};
  
  require ExtUtils::Mksymlists;
  ExtUtils::Mksymlists::Mksymlists( # dl. abbrev for dynamic library
    DL_VARS  => $args{dl_vars}      || [],
    DL_FUNCS => $args{dl_funcs}     || {},
    FUNCLIST => $args{dl_func_list} || [],
    IMPORTS  => $args{dl_imports}   || {},
    NAME     => $args{dl_name},
    DLBASE   => $args{dl_base},
    FILE     => $args{dl_file},
  );
  
  # Mksymlists will create one of these files
  return grep -e, map "$args{dl_file}.$_", qw(ext def opt);
}

sub link {
  my ($self, %args) = @_;
  return $self->_do_link('lib_file', lddl => 1, %args);
}

sub link_executable {
  my ($self, %args) = @_;
  return $self->_do_link('exe_file', lddl => 0, %args);
}
				   
sub _do_link {
  my ($self, $type, %args) = @_;

  my $cf = $self->{config}; # For convenience
  
  my $objects = delete $args{objects};
  $objects = [$objects] unless ref $objects;
  my $out = $args{$type} || $self->$type($objects->[0]);
  
  my @temp_files;
  @temp_files =
    $self->prelink(%args,
		   dl_name => $args{module_name}) if $self->need_prelink;
  
  my @linker_flags = $self->split_like_shell($args{extra_linker_flags});
  my @lddlflags = $args{lddl} ? $self->split_like_shell($cf->{lddlflags}) : ();
  my @shrp = $self->split_like_shell($cf->{shrpenv});
  my @ld = $self->split_like_shell($cf->{ld});
  $self->do_system(@shrp, @ld, @lddlflags, '-o', $out, @$objects, @linker_flags)
    or die "error building $out from @$objects";
  
  return wantarray ? ($out, @temp_files) : $out;
}


sub do_system {
  my ($self, @cmd) = @_;
  print "@cmd\n";
  return !system(@cmd);
}

sub split_like_shell {
  my ($self, $string) = @_;
  
  return () unless defined($string);
  return @$string if UNIVERSAL::isa($string, 'ARRAY');
  $string =~ s/^\s+|\s+$//g;
  return () unless length($string);
  
  return Text::ParseWords::shellwords($string);
}

1;
