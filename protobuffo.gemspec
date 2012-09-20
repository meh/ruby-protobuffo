Kernel.load 'lib/protobuffo/version.rb'

Gem::Specification.new {|s|
	s.name         = 'protobuffo'
	s.version      = ProtoBuffo.version
	s.author       = 'meh.'
	s.email        = 'meh@schizofreni.co'
	s.homepage     = 'https://github.com/meh/ruby-protobuffo'
	s.platform     = Gem::Platform::RUBY
	s.summary      = 'Ruby protobuf implementation.'

	s.files         = `git ls-files`.split("\n")
	s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
	s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
	s.require_paths = ['lib']

	s.add_runtime_dependency 'backports'

	s.add_runtime_dependency 'parslet'
	s.add_runtime_dependency 'sexp_processor'

	s.add_development_dependency 'rspec'
	s.add_development_dependency 'rake'
}
