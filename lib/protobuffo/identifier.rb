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

class Identifier
	def self.new (name, *args)
		return name if name.is_a?(Identifier)

		super
	end

	attr_reader :namespace, :name

	def initialize (name, namespace = [], fully_qualified = false)
		@name            = name.freeze
		@namespace       = namespace.freeze
		@fully_qualified = fully_qualified
	end

	def fully_qualified?
		@fully_qualified
	end

	def hash
		to_s.hash
	end

	def == (other)
		to_s == other.to_s
	end

	alias eql? ==

	def to_a
		namespace + [@name]
	end

	def to_str
		to_a.join '.'
	end

	alias to_s to_str

	def to_sym
		to_s.to_sym
	end

	def to_constant
		result = fully_qualified? ? '::' : ''

		namespace.each {|ns|
			result << "#{ns[0].upcase}#{ns[1 .. -1]}::"
		}

		result << "#{name[0].upcase}#{name[1 .. -1]}"

		result
	end
end

end
