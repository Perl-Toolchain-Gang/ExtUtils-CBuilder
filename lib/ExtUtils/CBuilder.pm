package ExtUtils::CBuilder;

use strict;
use File::Spec;
use IO::File;

use vars qw($VERSION);
$VERSION = '0.01';

sub new {
  return bless {}, shift;
}

sub compile_c {
}

sub compile_library {
}

sub compile_executable {
}

sub have_c_compiler {
  my ($self) = @_;
  return $self->{have_compiler} if defined $self->{have_compiler};
  
  my $tmpfile = File::Spec->catfile(File::Spec->tmpdir, 'compilet.c');
  {
    my $fh = IO::File->new("> $tmpfile") or die "Can't create $tmpfile: $!";
    print $fh "int boot_compilet() { return 1; }\n";
  }

  $self->{have_compiler} = 0 + eval { $self->compile_library($tmpfile); 1 };
  1 while unlink $tmpfile;
  return $self->{have_compiler};
}

# Copied from Time::HiRes
sub try_compile_and_link {
  my ($c, %args) = @_;
  
  my ($ok) = 0;
  my $tmp = File::Spec->tmpdir;
  
  local(*TMPC);
  
  my $obj_ext = $Config{obj_ext} || ".o";
  unlink("$tmp.c", "$tmp$obj_ext");
  
  if (open(TMPC, ">$tmp.c")) {
    print TMPC $c;
    close(TMPC);
    
    my $cccmd = $args{cccmd};
    
    my $errornull;
    
    my $COREincdir;
    
    if ($ENV{PERL_CORE}) {
      my $updir = File::Spec->updir;
      $COREincdir = File::Spec->catdir(($updir) x 3);
    } else {
      $COREincdir = File::Spec->catdir($Config{'archlibexp'}, 'CORE');
    }
    
    my $ccflags = $Config{'ccflags'} . ' ' . "-I$COREincdir";
    
    if ($^O eq 'VMS') {
      if ($ENV{PERL_CORE}) {
	# Fragile if the extensions change hierachy within
	# the Perl core but this should do for now.
	$cccmd = "$Config{'cc'} /include=([---]) $tmp.c";
      } else {
	my $perl_core = $Config{'installarchlib'};
	$perl_core =~ s/\]$/.CORE]/;
	$cccmd = "$Config{'cc'} /include=(perl_root:[000000],$perl_core) $tmp.c";
      }
    }
    
    if ($args{silent} || !$VERBOSE) {
      $errornull = "2>/dev/null" unless defined $errornull;
    } else {
      $errornull = '';
    }
    
    $cccmd = "$Config{'cc'} -o $tmp $ccflags $tmp.c @$LIBS $errornull"
      unless defined $cccmd;
    
    if ($^O eq 'VMS') {
      open( CMDFILE, ">$tmp.com" );
      print CMDFILE "\$ SET MESSAGE/NOFACILITY/NOSEVERITY/NOIDENT/NOTEXT\n";
      print CMDFILE "\$ $cccmd\n";
      print CMDFILE "\$ IF \$SEVERITY .NE. 1 THEN EXIT 44\n"; # escalate
      close CMDFILE;
      system("\@ $tmp.com");
      $ok = $?==0;
      for ("$tmp.c", "$tmp$obj_ext", "$tmp.com", "$tmp$Config{exe_ext}") {
	1 while unlink $_;
      }
    } else {
      my $tmp_exe = "$tmp$ld_exeext";
      printf "cccmd = $cccmd\n" if $VERBOSE;
      my $res = system($cccmd);
      $ok = defined($res) && $res==0 && -s $tmp_exe && -x _;
      unlink("$tmp.c", $tmp_exe);
    }
  }
  
  $ok;
}



1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

ExtUtils::CBuilder - Perl extension for blah blah blah

=head1 SYNOPSIS

  use ExtUtils::CBuilder;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for ExtUtils::CBuilder, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
