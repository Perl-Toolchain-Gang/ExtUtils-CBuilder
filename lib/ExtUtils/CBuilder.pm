package ExtUtils::CBuilder;

use strict;
use File::Spec;
use File::Basename;
use IO::File;
use Config;

use vars qw($VERSION);
$VERSION = '0.00_01';

sub new {
  my $class = shift;
  my $self = bless {@_}, $class;

  while (my ($k,$v) = each %Config) {
    $self->{config}{$k} = $v unless exists $self->{config}{$k};
  }
  return $self;
}

sub object_file {
  my ($self, $filename) = @_;

  # File name, minus the suffix
  (my $file_base = $filename) =~ s/\.[^.]+$//;
  return "$file_base$self->{config}{obj_ext}";
}

sub compile_library {
  my ($self, %args) = @_;
  die "Missing 'source' argument to compile_library()" unless defined $args{source};
  
  my $cf = $self->{config}; # For convenience

  $args{object_file} ||= $self->object_file($args{source});
  
  my @include_dirs = map {"-I$_"} (@{$args{include_dirs} || []},
				   File::Spec->catdir($cf->{installarchlib}, 'CORE'));
  
  my @extra_compiler_flags = $self->split_like_shell($args{extra_compiler_flags});
  my @cccdlflags = $self->split_like_shell($cf->{cccdlflags});
  my @ccflags = $self->split_like_shell($cf->{ccflags});
  my @optimize = $self->split_like_shell($cf->{optimize});
  my @flags = (@include_dirs, @cccdlflags, @extra_compiler_flags, '-c', @ccflags, @optimize);
  
  my @cc = $self->split_like_shell($cf->{cc});
  
  $self->do_system(@cc, @flags, '-o', $args{object_file}, $args{source})
    or die "error building $args{object_file} from '$args{source}'";

  return $args{object_file};
}

sub compile_executable {
  die "Not implemented yet";
}

sub have_c_compiler {
  my ($self) = @_;
  return $self->{have_compiler} if defined $self->{have_compiler};
  
  my $tmpfile = File::Spec->catfile(File::Spec->tmpdir, 'compilet.c');
  {
    my $fh = IO::File->new("> $tmpfile") or die "Can't create $tmpfile: $!";
    print $fh "int boot_compilet() { return 1; }\n";
  }

  my ($obj_file, @lib_files);
  eval {
    $obj_file = $self->compile_library(source => $tmpfile);
    @lib_files = $self->link_objects(objects => $obj_file, module_name => 'compilet');
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

sub need_prelink_objects { 0 }

sub prelink_objects {
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

sub link_objects {
  my ($self, %args) = @_;
  my $cf = $self->{config}; # For convenience
  
  my $objects = delete $args{objects};
  $objects = [$objects] unless ref $objects;
  $args{lib_file} ||= $self->lib_file($objects->[0]);
  
  my @temp_files = 
    $self->prelink_objects(%args,
			   dl_name => $args{module_name}) if $self->need_prelink_objects;
  
  my @linker_flags = $self->split_like_shell($args{extra_linker_flags});
  my @lddlflags = $self->split_like_shell($cf->{lddlflags});
  my @shrp = $self->split_like_shell($cf->{shrpenv});
  my @ld = $self->split_like_shell($cf->{ld});
  $self->do_system(@shrp, @ld, @lddlflags, '-o', $args{lib_file}, @$objects, @linker_flags)
    or die "error building $args{lib_file} from @$objects";
  
  return wantarray ? ($args{lib_file}, @temp_files) : $args{lib_file};
}

sub do_system {
  my ($self, @cmd) = @_;
  print "@cmd\n";
  return !system(@cmd);
}

sub split_like_shell {
  my ($self, $string) = @_;
  
  return () unless defined($string) && length($string);
  return @$string if UNIVERSAL::isa($string, 'ARRAY');
  
  return $self->shell_split($string);
}

sub shell_split {
  return split ' ', $_[1];  # XXX This is naive - needs a fix
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

ExtUtils::CBuilder - Compile and link C code for Perl modules

=head1 SYNOPSIS

  use ExtUtils::CBuilder;
  
  my $b = ExtUtils::CBuilder->new(%options);
  $obj_file = $b->compile_library(source => 'MyModule.c');
  $lib_file = $b->link_objects(objects => $obj_file);

=head1 DESCRIPTION

This module can build the C portions of Perl modules by invoking the
appropriate compilers and linkers in a cross-platform manner.  It was
motivated by the C<Module::Build> project, but may be useful for other
purposes as well.  However, it is I<not> intended as a general
cross-platform interface to all your C building needs.  That would
have been a much more ambitious goal!

=head1 METHODS

=over 4

=item new

Returns a new C<ExtUtils::CBuilder> object.  A C<config> parameter
lets you override C<Config.pm> settings for all operations performed
by the object, as in the following example:

  # Use a different compiler than Config.pm says
  my $b = ExtUtils::CBuilder->new( config =>
                                   { ld => 'gcc' } );

=item have_c_compiler

Returns true if the current system has a working C compiler and
linker, false otherwise.  To determine this, we actually compile and
link a sample C library.

=item compile_library

Compiles a C source file and produces an object file.  The name of the
object file is returned.  The source file is specified in a C<source>
parameter, which is required; the other parameters listed below are
optional.

=over 4

=item C<object_file>

Specifies the name of the output file to create.  Otherwise the
C<object_file()> method will be consulted, passing it the name of the
C<source> file.

=item C<include_dirs>

Specifies any additional directories in which to search for header
files.  May be given as a string indicating a single directory, or as
a list reference indicating multiple directories.

=item C<extra_compiler_flags>

Specifies any additional arguments to pass to the compiler.  Should be
given as a list reference containing the arguments individually, or if
this is not possible, as a string containing all the arguments
together.

=back

The operation of this method is also affected by the
C<installarchlib>, C<cccdlflags>, C<ccflags>, C<optimize>, and C<cc>
entries in C<Config.pm>.

=item link_objects

Invokes the linker to produce a library file from object files.  In
scalar context, the name of the library file is returned.  In list
context, the library file and any temporary files created are
returned.  A required C<objects> parameter contains the name of the
object files to process, either in a string (for one object file) or
list reference (for one or more files).  The following parameters are
optional:

=over 4

=item lib_file

Specifies the name of the output library file to create.  Otherwise
the C<lib_file()> method will be consulted, passing it the name of
the first entry in C<objects>.

=item module_name

Specifies the name of the Perl module that will be created by linking.
On platforms that need to do prelinking (Win32, OS/2, etc.) this is a
required parameter.

=item extra_linker_flags

Any additional flags you wish to pass to the linker.

=back

On platforms where C<need_prelink_c()> returns true, C<prelink_c()>
will be called automatically.

The operation of this method is also affected by the C<lddlflags>,
C<shrpenv>, and C<ld> entries in C<Config.pm>.

=item object_file

 my $object_file = $b->object_file($source_file);

Converts the name of a C source file to the most natural name of an
output object file to create from it.  For instance, on Unix the
source file F<foo.c> would result in the object file F<foo.o>.

=item lib_file

 my $lib_file = $b->lib_file($object_file);

Converts the name of an object file to the most natural name of a
output library file to create from it.  For instance, on Mac OS X the
object file F<foo.o> would result in the library file F<foo.bundle>.

=item prelink_objects

On certain platforms like Win32, OS/2, VMS, and AIX, it is necessary
to perform some actions before invoking the linker.  The
C<ExtUtils::Mksymlists> module does this, writing files used by the
linker during the creation of shared libraries for dynamic extensions.
The names of any files written will be returned as a list.

Several parameters correspond to C<ExtUtils::Mksymlists::Mksymlists()>
options, as follows:

    Mksymlists()  prelink_objects()       type
   -------------|-------------------|-------------------
    NAME        |  dl_name          | string (required)
    DLBASE      |  dl_base          | string
    FILE        |  dl_file          | string
    DL_VARS     |  dl_vars          | array reference
    DL_FUNCS    |  dl_funcs         | hash reference
    FUNCLIST    |  dl_func_list     | array reference
    IMPORTS     |  dl_imports       | hash reference

Please see the documentation for C<ExtUtils::Mksymlists> for the
details of what these parameters do.

=item need_prelink_objects

Returns true on platforms where C<prelink_objects()> should be called
during linking, and false otherwise.

=back

=head1 TO DO

Currently this has only been tested on Unix and doesn't contain any of
the Windows-specific code from the C<Module::Build> project.  I'll do
that next.

=head1 HISTORY

This module is an outgrowth of the C<Module::Build> project, to which
there have been many contributors.  Notably, Randy W. Sims submitted
lots of code to support 3 compilers on Windows and helped with various
other platform-specific issues.


=head1 AUTHOR

Ken Williams, kwilliams@cpan.org

=head1 SEE ALSO

perl(1), Module::Build(3)

=cut
