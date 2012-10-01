#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

module ProtoBuffo; class Message

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

	def add (rule, type, name, tag, options, extension = false)
		Field.new(rule, type, name, tag, options, extension).tap {|field|
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
		find { |f| what === f.name || what.to_s == f.name.to_s || what == f.tag }
	end

	def extension? (tag)
		@extensions.any? { |n| n === tag }
	end
end

end; end
