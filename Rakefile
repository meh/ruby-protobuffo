#! /usr/bin/env ruby
require 'rake'

task :default => :test

task :test do
	sh 'gem build *.gemspec'
	sh 'gem install *.gem'

  Dir.chdir 'test'

  sh 'rspec parser_spec.rb --color --format doc'
end
