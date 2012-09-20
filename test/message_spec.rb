#! /usr/bin/env ruby
require 'rubygems'
require 'protobuffo'

describe ProtoBuffo::Message do
	class Test1 < ProtoBuffo::Message
		required :int32, :a, 1
	end

	class Test2 < ProtoBuffo::Message
		required :string, :b, 2
	end

	class Test3 < ProtoBuffo::Message
		required Test1, :c, 3
	end

	class Test4 < ProtoBuffo::Message
		repeated :int32, :d, 4, :packed => true
	end

	describe '#pack' do
		it 'packs correctly the first encoding example' do
			Test1.new(a: 150).pack.string.should == "\x08\x96\x01"
		end

		it 'packs correctly the second encoding example' do
			Test2.new(b: 'testing').pack.string.should == "\x12\x07\x74\x65\x73\x74\x69\x6e\x67"
		end

		it 'packs correctly the third encoding example' do
			Test3.new(c: Test1.new(a: 150)).pack.string.should == "\x1a\x03\x08\x96\x01"
		end

		it 'packs correctly the fourth encoding example' do
			Test4.new(d: [3, 270, 86942]).pack.string.should == "\x22\x06\x03\x8E\x02\x9E\xA7\x05"
		end
	end

	describe '.unpack' do
		it 'unpacks correctly the first encoded example' do
			Test1.unpack("\x08\x96\x01").a.should == 150
		end

		it 'unpacks correctly the second encoded example' do
			Test2.unpack("\x12\x07\x74\x65\x73\x74\x69\x6e\x67").b.should == 'testing'
		end

		it 'unpacks correctly the third encoded example' do
			Test3.unpack("\x1a\x03\x08\x96\x01").c.a.should == 150
		end

		it 'unpacks correctly the fourth encoded example' do
			Test4.unpack("\x22\x06\x03\x8E\x02\x9E\xA7\x05").d.to_a.should == [3, 270, 86942]
		end
	end
end
