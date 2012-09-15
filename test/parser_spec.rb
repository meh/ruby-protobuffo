#! /usr/bin/env ruby
require 'rubygems'
require 'protobuffo'

describe ProtoBuffo do
	let :a do
		ProtoBuffo.to_sexp('message A { }')
	end

	describe '.to_sexp' do
		it 'handles message statement properly' do
			a.first.sexp_type.should == :message
			a.first.sexp_body.first.should == 'A'
		end
	end
end
