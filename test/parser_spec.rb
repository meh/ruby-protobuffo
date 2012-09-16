#! /usr/bin/env ruby
require 'rubygems'
require 'protobuffo'

describe ProtoBuffo do
	describe '.to_sexp' do
		let :a do
			ProtoBuffo.to_sexp(%q{
				message A { }
			})
		end

		let :b do
			ProtoBuffo.to_sexp(%q{
				message A {
					message B { }
				}
			})
		end

		let :c do
			ProtoBuffo.to_sexp(%q{
				message A {
					required int32 a;
					optional int32 b;
					repeated int32 c;
				}
			})
		end

		let :d do
			ProtoBuffo.to_sexp(%q{
				message A {
					required double   a;
					required float    a;
					required int32    a;
					required int64    a;
					required uint32   a;
					required uint64   a;
					required sint32   a;
					required sint64   a;
					required fixed32  a;
					required fixed64  a;
					required sfixed32 a;
					required sfixed64 a;
					required bool     a;
					required string   a;
					required bytes    a;

					required LOL wat;
				}
			})
		end

		let :e do
			ProtoBuffo.to_sexp(%q{
				message A {
					// comment
				}
			})
		end

		it 'handles message statements' do
			a.first.sexp_type.should == :message
			a.first.sexp_body.first.should == 'A'
		end

		it 'handles nested messages' do
			b.first.sexp_body.last.sexp_type.should == :message
			b.first.sexp_body.last.sexp_body.first.should == 'B'
		end

		it 'handles field attributes' do
			c.first.sexp_body[1].sexp_body[2].should == :required
			c.first.sexp_body[2].sexp_body[2].should == :optional
			c.first.sexp_body[3].sexp_body[2].should == :repeated
		end

		it 'handles types' do
			d.first.sexp_body[1].sexp_body[1].should === :double
			d.first.sexp_body[2].sexp_body[1].should === :float
			d.first.sexp_body[3].sexp_body[1].should === :int32
			d.first.sexp_body[4].sexp_body[1].should === :int64
			d.first.sexp_body[5].sexp_body[1].should === :uint32
			d.first.sexp_body[6].sexp_body[1].should === :uint64
			d.first.sexp_body[7].sexp_body[1].should === :sint32
			d.first.sexp_body[8].sexp_body[1].should === :sint64
			d.first.sexp_body[9].sexp_body[1].should === :fixed32
			d.first.sexp_body[10].sexp_body[1].should === :fixed64
			d.first.sexp_body[11].sexp_body[1].should === :sfixed32
			d.first.sexp_body[12].sexp_body[1].should === :sfixed64
			d.first.sexp_body[13].sexp_body[1].should === :bool
			d.first.sexp_body[14].sexp_body[1].should === :string
			d.first.sexp_body[15].sexp_body[1].should === :bytes

			d.first.sexp_body[16].sexp_body[1].should_not be(Symbol)
		end

		it 'parses comments' do
			e.first.sexp_body.last.sexp_type.should == :comment
			e.first.sexp_body.last.sexp_body.first.should == ' comment'
		end
	end
end
