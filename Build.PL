use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'ExtUtils::CBuilder',
   license => 'perl',
   requires => {
		'File::Basename' => 0,
		'File::Spec' => 0,
	       },
   build_requires => {
		      'Test' => 0,
		     },
   create_makefile_pl => 'traditional',
  );

$build->create_build_script;
