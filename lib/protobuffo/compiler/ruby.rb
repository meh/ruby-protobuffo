#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

module ProtoBuffo; class Compiler < SexpProcessor

class Ruby < Compiler
	def initialize (configuration = {})
		super({ indentation: '  ', path: $:, map: {} }.merge(configuration))

		self.auto_shift_type = true
		self.strict          = true
		self.expected        = BasicObject

		@indent = 0
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
			env[:top]         = Identifier.new

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
			line (['end'] * (env[:package].to_namespace(configuration[:map]).count(';') + 1)).join('; ')
		end

		if env[:package] = exp.shift
			line env[:package].to_namespace(configuration[:map])

			env[:top] = env[:package]
		end
	end

	def process_option (exp)
		name, value = exp.shift(2)

		env[:options][name] = value
	end

	def process_message (exp)
		name, *rest = exp.slice!(0 .. -1)
		top         = env[:top].add(name)

		line "class #{Identifier.new(name).to_constant(configuration[:map])} < ProtoBuffo::Message"

		indent {
			line "identifier #{env[:top].to_s.inspect}"
			line

			scope {
				env.current[:top] = top

				rest.each { |e| process e }
			}
		}

		line 'end'
	end

	def process_extend (exp)
		name, *rest = exp.slice!(0 .. -1)

		line "class #{name.to_constant(configuration[:map])} < ProtoBuffo::Message"

		indent {
			scope {
				env[:extend] = true

				rest.each { |e| process e }
			}
		}

		line 'end'
	end

	def process_enum (exp)
		name, *rest = exp.slice!(0 .. -1)

		line "#{Identifier.new(name).to_constant(configuration[:map])} = ProtoBuffo::Enum.new(#{
			rest.map {|name, value|
				":'#{name.to_s}' => #{value.inspect}"
			}.join ', '
		})"
	end

	def process_field (exp)
		name, type, rule, tag, options = exp.shift(5)

		if env[:extend]
			options[:extension] = true
		end

		line "#{rule} #{type.inspect}, #{name.to_sym.inspect}, #{tag}#{
			unless options.empty?
				', ' + options.map {|name, value|
					"#{name.to_s.inspect} => #{value}"
				}.join(', ')
			end
		}"
	end
end

end; end
