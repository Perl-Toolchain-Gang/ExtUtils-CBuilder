use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'ExtUtils::CBuilder',
   license => 'perl',
  );

$build->create_build_script;
