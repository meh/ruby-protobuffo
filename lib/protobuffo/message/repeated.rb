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

class Repeated < Array
	attr_reader :field

	def initialize (field)
		@field = field
	end

	undef_method :map!
	undef_method :collect!
	undef_method :fill

	def << (obj)
		super(field.validate!(obj))
	end

	def []= (*args, obj)
		super(*args, field.validate!(obj))
	end

	def insert (index, *obj)
		super(index, *obj.map { |o| field.validate!(o) })
	end

	def push (*obj)
		super(*obj.map { |o| field.validate!(o) })
	end

	def replace (other)
		super(other.map { |o| field.validate!(o) })
	end

	def unshift (*obj)
		super(*obj.map { |o| field.validate!(o) })
	end
end

end; end
