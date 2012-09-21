#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

begin
	require 'backports/1.9.2'
rescue LoadError
	retry if require 'rubygems'
end

module ProtoBuffo

class Field
	include Comparable

	attr_reader :rule, :type, :name, :tag, :options

	def initialize (rule, type, name, tag, options = {})
		@rule    = rule.freeze
		@type    = type.freeze
		@name    = name.freeze
		@tag     = tag.freeze
		@options = options.freeze

		freeze
	end

	def required?; rule == :required; end
	def optional?; rule == :optional; end
	def repeated?; rule == :repeated; end

	def default;       options[:default];    end
	def packed?;     !!options[:packed];     end
	def deprecated?; !!options[:deprecated]; end
	def extension?;  !!options[:extension];  end

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
			when Class                                then value.is_a?(String) || value.is_a?(type)
		end

		case type
			when Enum  then type.to_sym(value)
			when Class then value.is_a?(String) ? type.unpack(value) : value
			else            value
		end
	end
end

class Fields
	include Enumerable

	attr_reader :message

	def initialize (message)
		@message    = message
		@fields     = []
		@extensions = []
	end

	def add_extensions (what)
		unless what.is_a?(Integer) || (what.is_a?(Range) && what.begin.is_a?(Integer) && what.end.is_a?(Integer))
			raise ArgumentError, "#{what.inspect} is not an Integer or a Range made of Integers"
		end

		@extensions << what
	end

	def add (rule, type, name, tag, options)
		Field.new(rule, type, name, tag, options).tap {|field|
			if self[field.tag]
				raise ArgumentError, "#{field.tag} is already present"
			end

			if field.extension? && !extension?(field.tag)
				raise ArgumentError, "#{field.tag} isn't available as an extension"
			end

			if field.type.is_a?(Class) && !field.type.ancestors.member?(Message)
				raise ArgumentError, "#{field.type} has to be a subclass of Message"
			end

			@fields << field
			@fields.sort_by!(&:tag)
		}
	end

	def each (&block)
		return enum_for :each unless block

		@fields.each(&block)

		self
	end

	def [] (what)
		find { |f| what === f.name || what === f.tag }
	end

	def extension? (tag)
		@extensions.any? { |n| n === tag }
	end
end

end
