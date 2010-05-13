#! perl -w

use strict;
use Test::More qw(no_plan); # tests => 7;
BEGIN { 
  if ($^O eq 'VMS') {
    # So we can get the return value of system()
    require vmsish;
    import vmsish;
  }
}
use Cwd;
use File::Temp qw( tempdir );
use ExtUtils::CBuilder::Base;
#use Data::Dumper;$Data::Dumper::Indent=1;

my ( $base, $phony, $cwd );

$base = ExtUtils::CBuilder::Base->new();
ok( $base, "ExtUtils::CBuilder::Base->new() returned true value" );
isa_ok( $base, 'ExtUtils::CBuilder::Base' );

$phony = 'foobar';
$base = ExtUtils::CBuilder::Base->new(
    config  => { cc => $phony },
);
ok( $base, "ExtUtils::CBuilder::Base->new() returned true value" );
isa_ok( $base, 'ExtUtils::CBuilder::Base' );
is( $base->{config}->{cc}, $phony,
    "Got expected value when 'config' argument passed to new()" );

{
    $phony = 'barbaz';
    local $ENV{CC} = $phony;
    $base = ExtUtils::CBuilder::Base->new();
    ok( $base, "ExtUtils::CBuilder::Base->new() returned true value" );
    isa_ok( $base, 'ExtUtils::CBuilder::Base' );
    is( $base->{config}->{cc}, $phony,
        "Got expected value \$ENV{CC} set" );
}

{
    my $path_to_perl = File::Spec->catfile( '', qw| usr bin perl | );
    local $^X = $path_to_perl;
    is(
        ExtUtils::CBuilder::Base::find_perl_interpreter(),
        $path_to_perl,
        "find_perl_interpreter() returned expected absolute path"
    );;
}

{
    $cwd = cwd();
    my $tdir = tempdir();
    chdir $tdir;
    $base = ExtUtils::CBuilder::Base->new();
    ok( $base, "ExtUtils::CBuilder::Base->new() returned true value" );
    isa_ok( $base, 'ExtUtils::CBuilder::Base' );
    is( scalar keys %{$base->{files_to_clean}}, 0,
        "No files needing cleaning yet" );

    my $file_for_cleaning = File::Spec->catfile( $tdir, 'foobar' );
    open my $IN, '>', $file_for_cleaning
        or die "Unable to open dummy file: $!";
    print $IN "\n";
    close $IN or die "Unable to close dummy file: $!";

    $base->add_to_cleanup( $file_for_cleaning );
    is( scalar keys %{$base->{files_to_clean}}, 1,
        "One file needs cleaning" );

    $base->cleanup();
    ok( ! -f $file_for_cleaning, "File was cleaned up" );

    chdir $cwd;
}

pass("Passed all tests in $0");

if ($^O eq 'VMS') {
   1 while unlink 'COMPILET.LIS';
   1 while unlink 'COMPILET.OPT';
}

