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

module ProtoBuffo; class Compiler < SexpProcessor

class Identifiers < SexpProcessor
	attr_reader :configuration

	def initialize (configuration = {})
		super()

		self.auto_shift_type = true
		self.strict          = false
		self.expected        = Array
		self.default_method  = :default
		self.warn_on_default = false

		@configuration = { path: $: }.merge(configuration)
		@env           = SexpProcessor::Environment.new
	end

	def import (path, &block)
		ProtoBuffo.import(path, (File.readable?(env[:source]) ? [File.dirname(env[:source])] : []) +
			configuration[:path], &block)
	end

	def get (what, type = :all)
		scope {
			env[:type]   = type
			env[:source] = what

			ProtoBuffo.to_sexp(what).map { |exp| process(exp) }.flatten.compact
		}
	end

	def get_messages (what)
		get(what, :message)
	end

	def default (exp)
		exp.clear
	end

	def process_import (exp)
		import(exp.shift) {|f|
			Identifiers.new(configuration).get(f, env[:type])
		}
	end

	def process_package (exp)
		env[:package] = exp.shift

		[]
	end

	def process_message (exp)
		name, *rest = exp.slice!(0 .. -1)
		result      = []

		scope {
			tmp, env[:package] = env[:package], Identifier.new(name, env[:package].to_a, true)

			if env[:type] == :all || env[:type] == :message
				result << env[:package]
			end

			rest and rest.each {|e|
				result << process(e)
			}

			env[:package] = tmp
		}

		result
	end

	def process_enum (exp)
		name, rest = exp.slice!(0 .. -1)

		if env[:type] == :all || env[:type] == :enum
			[Identifier.new(name, env[:package].to_a, true)]
		else
			[]
		end
	end
end

end; end
