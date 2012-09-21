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

	def to_str
		(namespace + [@name]).join '.'
	end

	alias to_s to_str
end

end
