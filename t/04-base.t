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
use ExtUtils::CBuilder::Base;
use Data::Dumper;$Data::Dumper::Indent=1;

my ( $base, $phony );

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

pass("Passed all tests in $0");

if ($^O eq 'VMS') {
   1 while unlink 'COMPILET.LIS';
   1 while unlink 'COMPILET.OPT';
}

