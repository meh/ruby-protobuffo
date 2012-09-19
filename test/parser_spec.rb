#! /usr/bin/env ruby
require 'rubygems'
require 'protobuffo'

describe ProtoBuffo do
	describe '.to_sexp' do
		let :message do
			ProtoBuffo.to_sexp(%q{
				message A { }
			})
		end

		let :nested_message do
			ProtoBuffo.to_sexp(%q{
				message A {
					message B { }
				}
			})
		end

		let :field_labels do
			ProtoBuffo.to_sexp(%q{
				message A {
					required int32 a = 1;
					optional int32 b = 2;
					repeated int32 c = 3;
				}
			})
		end

		let :field_types do
			ProtoBuffo.to_sexp(%q{
				message A {
					required double   a = 1;
					required float    a = 1;
					required int32    a = 1;
					required int64    a = 1;
					required uint32   a = 1;
					required uint64   a = 1;
					required sint32   a = 1;
					required sint64   a = 1;
					required fixed32  a = 1;
					required fixed64  a = 1;
					required sfixed32 a = 1;
					required sfixed64 a = 1;
					required bool     a = 1;
					required string   a = 1;
					required bytes    a = 1;

					required LOL wat = 1;
				}
			})
		end

		let :field_options do
			ProtoBuffo.to_sexp(%q{
				message A {
					required int32 a = 1 [default = 23];
					required int32 b = 2 [lol = 23, wut = 42];
				}
			})
		end

		let :comments do
			ProtoBuffo.to_sexp(%q{
				// test
				message A { // test
					// comment
				} // test
			})
		end

		let :import do
			ProtoBuffo.to_sexp(%q{
				import "lolwut";
			})
		end

		let :package do
			ProtoBuffo.to_sexp(%q{
				package lol.wut;
			})
		end

		let :options do
			ProtoBuffo.to_sexp(%q{
				option lol.wut = 2;
			})
		end

		let :extend do
			ProtoBuffo.to_sexp(%q{
				extend A {
					required int32 a = 1;
				}
			})
		end

		let :extensions do
			ProtoBuffo.to_sexp(%q{
				message A {
					extensions 1 to 10;
					extensions 1, 3 to max;
				}
			})
		end

		let :enum do
			ProtoBuffo.to_sexp(%q{
				message A {
					enum B {
						LOL = 0;
						WUT = 1;
					}

					required B a = 1;
				}
			})
		end

		it 'handles message statements' do
			message.first.sexp_type.should == :message
			message.first.sexp_body.first.should == 'A'
		end

		it 'handles nested messages' do
			nested_message.first.sexp_body.last.sexp_type.should == :message
			nested_message.first.sexp_body.last.sexp_body.first.should == 'B'
		end

		it 'handles comments' do
			comments[1].sexp_body.last.sexp_type.should == :comment
			comments[1].sexp_body.last.sexp_body.first.should == ' comment'
		end

		it 'handles import statements' do
			import.first.sexp_type.should == :import
			import.first.sexp_body.first.should  == 'lolwut'
		end

		it 'handles package statements' do
			package.first.sexp_type.should == :package
			package.first.sexp_body.first.should == 'lol.wut'
		end

		it 'handles option statements' do
			options.first.sexp_type.should == :option
			options.first.sexp_body.first.should == 'lol.wut'
			options.first.sexp_body.last.should == 2
		end

		it 'handles extend statements' do
			extend.first.sexp_type.should == :extend
			extend.first.sexp_body.first.should == 'A'
		end

		it 'handles field attributes' do
			field_labels.first.sexp_body[1].sexp_body[2].should == :required
			field_labels.first.sexp_body[2].sexp_body[2].should == :optional
			field_labels.first.sexp_body[3].sexp_body[2].should == :repeated
		end

		it 'handles field types' do
			field_types.first.sexp_body[1].sexp_body[1].should === :double
			field_types.first.sexp_body[2].sexp_body[1].should === :float
			field_types.first.sexp_body[3].sexp_body[1].should === :int32
			field_types.first.sexp_body[4].sexp_body[1].should === :int64
			field_types.first.sexp_body[5].sexp_body[1].should === :uint32
			field_types.first.sexp_body[6].sexp_body[1].should === :uint64
			field_types.first.sexp_body[7].sexp_body[1].should === :sint32
			field_types.first.sexp_body[8].sexp_body[1].should === :sint64
			field_types.first.sexp_body[9].sexp_body[1].should === :fixed32
			field_types.first.sexp_body[10].sexp_body[1].should === :fixed64
			field_types.first.sexp_body[11].sexp_body[1].should === :sfixed32
			field_types.first.sexp_body[12].sexp_body[1].should === :sfixed64
			field_types.first.sexp_body[13].sexp_body[1].should === :bool
			field_types.first.sexp_body[14].sexp_body[1].should === :string
			field_types.first.sexp_body[15].sexp_body[1].should === :bytes

			field_types.first.sexp_body[16].sexp_body[1].should_not be(Symbol)
		end

		it 'handles field options' do
			field_options.first.sexp_body[1].sexp_body[4][0].should == [:default, 23]

			field_options.first.sexp_body[2].sexp_body[4][0].should == ['lol', 23]
			field_options.first.sexp_body[2].sexp_body[4][1].should == ['wut', 42]
		end

		it 'handles extensions statements' do
			extensions.first.sexp_body[1].sexp_type.should == :extensions
			extensions.first.sexp_body[1].sexp_body[0].sexp_body[0].should == 1
			extensions.first.sexp_body[1].sexp_body[0].sexp_body[1].should == 10

			extensions.first.sexp_body[2].sexp_type.should == :extensions
			extensions.first.sexp_body[2].sexp_body[0].sexp_body[0].should == 1

			extensions.first.sexp_body[2].sexp_type.should == :extensions
			extensions.first.sexp_body[2].sexp_body[1].sexp_body[0].should == 3
			extensions.first.sexp_body[2].sexp_body[1].sexp_body[1].should == 536870911
		end

		it 'handles enums' do
			enum.first.sexp_body[1].sexp_type.should == :enum
			enum.first.sexp_body[1].sexp_body[0].should == 'B'
			enum.first.sexp_body[1].sexp_body[1].should == ['LOL', 0]
			enum.first.sexp_body[1].sexp_body[2].should == ['WUT', 1]
		end
	end
end
