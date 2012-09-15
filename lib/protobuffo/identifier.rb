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
	attr_reader :namespace

	def initialize (name, namespace = [], fully_qualified = false)
		@name            = name
		@namespace       = namespace
		@fully_qualified = fully_qualified
	end

	def fully_qualified?
		@fully_qualified
	end

	def to_str
		@name
	end

	alias to_s to_str
end

end
