#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

module ProtoBuffo
	autoload :Wire, 'protobuffo/wire'

	autoload :Parser, 'protobuffo/parser'
	autoload :Transform, 'protobuffo/parser'
	autoload :Compiler, 'protobuffo/compiler'

	autoload :Identifier, 'protobuffo/identifier'
	autoload :Enum, 'protobuffo/enum'
	autoload :Unknown, 'protobuffo/unknown'
	autoload :Field, 'protobuffo/field'
	autoload :Message, 'protobuffo/message'

	def self.compile (what)
		Compiler.new.compile(if what.respond_to? :to_io
			what.to_io
		elsif File.readable?(what)
			File.read(what)
		else
			what.to_s
		end)
	end

	def self.to_sexp (what)
		Transform.new.apply(Parser.new.parse(if what.respond_to? :to_io
			what.to_io
		elsif File.readable?(what)
			File.read(what)
		else
			what.to_s
		end))
	end
end
