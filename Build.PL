use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');
  sub do_create_makefile_pl {
    my $self = shift;
    $self->SUPER::do_create_makefile_pl(fh => $fh);
    $self->do_system(qw(perl -pi -e), q{s/'INSTALLDIRS' => '\w+'/'INSTALLDIRS' => (\$] >= 5.009003 ? 'perl' : 'site')/}, 'Makefile.PL');
  }
EOF

my $build = $class->new
  (
   module_name => 'ExtUtils::CBuilder',
   license => 'perl',
   auto_configure_requires => 0,
   requires => {
		'File::Basename' => 0,
		'File::Spec' => 3.13, # fixes tmpdir issues
		'File::Temp' => 0,
		'Text::ParseWords' => 0,
		'Cwd' => 0,
		'IO::File' => 0,
		'IPC::Cmd' => 0,
	       },
   build_requires => {
		      'Test::More' => 0.47,
		     },
   create_makefile_pl => 'traditional',
   create_readme => 1,
   meta_merge => {
		  resources => {repository => 'git://github.com/dagolden/extutils-cbuilder.git'},
		 },
   installdirs => ($] >= 5.009003 ? 'core' : 'site'),
  );

$build->create_build_script;
