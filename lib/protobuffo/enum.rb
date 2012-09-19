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

class Enum
	include Enumerable

	def initialize (values = {})
		@values = values
	end

	def each (&block)
		@values.each(&block)
	end

	def has? (what)
		!to_i(what).nil? && !to_sym(what).nil?
	end

	def to_i (sym)
		@values[sym]
	end

	def to_sym (num)
		@values.key(num)
	end
end

end
