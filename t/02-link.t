#! perl -w

use strict;
use Test;
BEGIN { 
  if ($^O eq 'MSWin32') {
    print "1..0 # Skipped: link_executable() is not implemented yet on Win32\n";
    exit;
  }
  plan tests => 5;
}

use ExtUtils::CBuilder;
use File::Spec;

my $b = ExtUtils::CBuilder->new;
ok $b;

my $source_file = File::Spec->catfile('t', 'compilet.c');
{
  local *FH;
  open FH, "> $source_file" or die "Can't create $source_file: $!";
  print FH "int main(char **argv) { return 11; }\n";
  close FH;
}
ok -e $source_file;

# Compile
my $object_file;
ok $object_file = $b->compile(source => $source_file);

# Link
my ($exe_file, @temps);
($exe_file, @temps) = $b->link_executable(objects => $object_file);
ok $exe_file;

# Try the executable
my $retval = system($exe_file);
ok $retval >> 8, 11;

# Clean up
for ($source_file, $exe_file, $object_file, @temps) {
  tr/"'//d;
  1 while unlink;
}
