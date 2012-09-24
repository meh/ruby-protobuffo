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

	autoload :Identifier, 'protobuffo/identifier'
	autoload :Parser, 'protobuffo/parser'
	autoload :Transform, 'protobuffo/parser'
	autoload :Compiler, 'protobuffo/compiler'

	autoload :Unknown, 'protobuffo/unknown'
	autoload :Repeated, 'protobuffo/repeated'
	autoload :Enum, 'protobuffo/enum'
	autoload :Field, 'protobuffo/fields'
	autoload :Fields, 'protobuffo/fields'
	autoload :Message, 'protobuffo/message'

	class << self
		def compile (what)
			Compiler.new.compile(if what.respond_to? :to_io
				what.to_io
			elsif File.readable?(what)
				File.read(what)
			else
				what.to_s
			end)
		end

		def to_sexp (what)
			Transform.new.apply(Parser.new.parse(if what.respond_to? :to_io
				what.to_io.read
			elsif File.readable?(what)
				File.read(what)
			else
				begin
					import(what)
				rescue LoadError
					what.to_s
				end
			end))
		end

		def import (path, base = $:, &block)
			unless path.end_with? '.proto'
				path = "#{path}.proto"
			end

			base.each {|base|
				file = "#{base}/#{path}"

				if File.readable?(file)
					return block ? File.open(file, &block) : File.read(file)
				end
			}

			raise LoadError, "cannot load such file -- #{path}"
		end

		def require_proto (path, options = {})

		end
	end
end

module Kernel
	def require_proto (*args)
		ProtoBuffo.require_proto(*args)
	end
end
