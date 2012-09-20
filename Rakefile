#! /usr/bin/env ruby
require 'rake'

task :default => [:install, :test]

task :install do
	sh 'gem install rspec'

	sh 'gem build *.gemspec'
	sh 'gem install *.gem'
end

task :test do
	FileUtils.cd 'test' do
		sh 'rspec parser_spec.rb --color --format doc'
		sh 'rspec message_spec.rb --color --format doc'
	end
end
