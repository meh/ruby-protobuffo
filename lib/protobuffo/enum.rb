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
		@values.has_key?(what) || @values.has_value?(what)
	end

	def to_i (sym)
		raise ArgumentError, "#{sym} is not present" unless has?(sym)

		return sym if sym.is_a?(Integer)

		@values[sym]
	end

	def to_sym (num)
		raise ArgumentError, "#{num} is not present" unless has?(num)

		return num if num.is_a? Symbol

		@values.key(num)
	end
end

end
