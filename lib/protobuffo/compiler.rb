#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'sexp_processor'

module ProtoBuffo

class Compiler < SexpProcessor
	autoload :Identifiers, 'protobuffo/compiler/identifiers'

	attr_reader :configuration

	def initialize (configuration = {})
		super()

		self.auto_shift_type = true
		self.strict          = true
		self.expected        = BasicObject

		@configuration = { indentation: '  ', path: $:, map: { } }.merge(configuration)
		@env           = SexpProcessor::Environment.new
		@indent        = 0
	end

	def line (text = nil)
		if text
			env[:output].write(configuration[:indentation] * @indent)
			env[:output].write(text)
		end

		env[:output].puts

		self
	end

	def indent
		@indent += 1

		yield
	ensure
		@indent -= 1
	end

	def import (path, &block)
		ProtoBuffo.import(path, (File.readable?(env[:source]) ? [File.dirname(env[:source])] : []) +
			configuration[:path], &block)
	end

	def compile (what, output = nil)
		scope {
			env[:source]      = what
			env[:output]      = output || StringIO.new
			env[:options]     = {}
			env[:identifiers] = Identifiers.new(configuration).get(what)
			env[:messages]    = Identifiers.new(configuration).get_messages(what)

			ProtoBuffo.to_sexp(what).each {|exp|
				process exp
			}

			process s(:package)

			output ? env[:output] : env[:output].string
		}
	end

	def process_import (exp)
		nil
	end

	def process_package (exp)
		if env[:package]
			line # TODO: implement it supporting map
		end

		if env[:package] = exp.shift
			line # TODO: implement it supporting map
		end
	end

	def process_option (exp)
		name, value = exp.shift(2)

		env[:options][name] = value
	end

	def process_message (exp)
		name, *rest = exp.slice!(0 .. -1)

		scope {
			line "class #{Identifier.new(name).to_constant} < ProtoBuffo::Message"

			indent {
				if env[:package]
					line "package #{env[:package].to_s.inspect}"
				end

				line "name #{name.inspect}"

				env[:package, shadow: true] = Identifier.new(name, env[:package].to_a, true)

				rest.each { |e| process e }
			}

			line 'end'
		}
	end

	def process_enum (exp)
		name, *rest = exp.slice!(0 .. -1)

		line "#{Identifier.new(name).to_constant} = ProtoBuffo::Enum.new("
		indent {
			rest.each {|name, value|
				line ":'#{name.to_s}' => #{value.inspect},"
			}
		}
		line ')'
	end

	def process_field (exp)
		name, type, rule, tag, options = exp.slice!(0 .. -1)

		line "#{rule} #{type.inspect}, #{name.to_sym.inspect}, #{tag}, { #{
			options.map {|name, value|
				"#{name.to_s.inspect} => #{value}"
			}.join ', '
		} }"
	end
end

end
