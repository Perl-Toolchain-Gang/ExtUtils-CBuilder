#!/usr/bin/perl

# A script to check a local copy against bleadperl, generating a
# patch if they're out of sync.  The path to bleadperl is required.
# An optional directory argument will be chdir()-ed into before comparing.

# NOTE -- now that EU::CB has blead as upstream, the generated diff
# is to be used to bring the local copy into sync with blead

use strict;
use warnings;
use File::Spec::Functions;

my $blead = shift @ARGV
  or die "Usage: $0 <bleadperl-src> [ExtUtils-CBuilder-src]\n";

chdir shift() if @ARGV;

die "Doesn't look like $blead contains the perl source"
  unless -f catfile($blead, 'perl.c');

my $HEAD = catfile($blead, qw/.git HEAD/);
my $head = do { local (@ARGV, $/) = $HEAD; <> };
my ($ref) = $head =~ m{ref: (.*)};

my $commit = do { local (@ARGV, $/) = catfile($blead, '.git', $ref); <> };

$commit = substr($commit, 0, 8);

print STDERR "Comparing with $commit\n";

my $upstream = catdir($blead, qw/dist ExtUtils-CBuilder/);

diff( "lib", "$upstream/lib" );
diff( "t", "$upstream/t" );

######################
sub diff {
  my ($first, $second, @skip) = @_;
  local $_ = `diff -ur $first $second`;

  for my $x (@skip) {
    s/^Only in .* $x\n//mg;
  }
  print;
}
