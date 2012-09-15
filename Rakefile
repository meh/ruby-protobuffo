#! /usr/bin/env ruby
require 'rake'

task :default => [:install, :test]

task :install do
	sh 'gem build *.gemspec'
	sh 'gem install --development *.gem'
end

task :test do
	FileUtils.cd 'test' do
		sh 'rspec parser_spec.rb --color --format doc'
	end
end
