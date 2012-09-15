#! /usr/bin/env ruby
require 'rubygems'
require 'protobuffo'

describe ProtoBuffo do
	let :search_response do
		%Q{
			message SearchResponse {
				message Result {
					required string url = 1;
					optional string title = 2;
					repeated string snippets = 3;
				}
				repeated Result result = 1;
			}
		}
	end

	describe '.to_sexp' do
		it 'handles message statement properly' do
			proto = ProtoBuffo.to_sexp(search_response)

			proto.first.sexp_type.should == :message
		end
	end
end
