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

class Field
	include Comparable

	attr_reader :rule, :type, :name, :tag, :options

	def initialize (rule, type, name, tag, options = {})
		@rule    = rule
		@type    = type
		@name    = name
		@tag     = tag
		@options = options
	end

	def required?; rule == :required; end
	def optional?; rule == :optional; end
	def repeated?; rule == :repeated; end

	def default;       options[:default];    end
	def packed?;     !!options[:packed];     end
	def deprecated?; !!options[:deprecated]; end

	def <=> (other)
		tag <=> other.tag
	end

	def validate! (value)
		raise ArgumentError, "#{value.inspect} is invalid for #{type}" unless case type
			when :bool                                then value.is_a?(TrueClass) || value.is_a?(FalseClass)
			when :int32, :sint32, :fixed32, :sfixed32 then value.is_a?(Integer) && value >= Wire::MIN_INT32 && value <= Wire::MAX_INT32
			when :uint32                              then value.is_a?(Integer) && value >= Wire::MIN_UINT32 && value <= Wire::MAX_UINT32
			when :int64, :sint64, :fixed64, :sfixed64 then value.is_a?(Integer) && value >= Wire::MIN_INT64 && value <= Wire::MAX_INT64
			when :uint64                              then value.is_a?(Integer) && value >= Wire::MIN_UINT64 && value <= Wire::MAX_UINT64
			when :float, :double                      then value.is_a?(Numeric)
			when :bytes, :string                      then value.is_a?(String)
			when Enum                                 then type.has?(value)
			when Class                                then value.is_a?(type)
		end
	end
end

end
