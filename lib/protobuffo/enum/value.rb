#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

module ProtoBuffo; class Enum

class Value
	attr_reader :name, :value, :options

	def initialize (name, value, options = [])
		@name    = name
		@value   = value
		@options = Options.new(self, options)
	end

	def to_sym
		name.to_sym
	end

	def to_i
		@value
	end
end

end; end
