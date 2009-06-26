#!/usr/bin/perl

# A script to check a local copy against bleadperl, generating a blead
# patch if they're out of sync.  The path to bleadperl is required.
# An optional directory argument will be chdir()-ed into before comparing.

use strict;
my $blead = shift @ARGV
  or die "Usage: $0 <bleadperl-src> [ExtUtils-CBuilder-src]\n";

chdir shift() if @ARGV;


diff( "$blead/lib/ExtUtils/CBuilder.pm", "lib/ExtUtils/CBuilder.pm");

diff( "$blead/lib/ExtUtils/CBuilder", "lib/ExtUtils/CBuilder",
      qw(t Changes .svn) );

diff( "$blead/lib/ExtUtils/CBuilder/t", "t",
      qw(.svn) );

######################
sub diff {
  my ($first, $second, @skip) = @_;
  local $_ = `diff -ur $first $second`;

  for my $x (@skip) {
    s/^Only in .* $x\n//mg;
  }
  print;
}
