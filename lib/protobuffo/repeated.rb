#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'forwardable'

module ProtoBuffo

class Repeated < Array
	extend Forwardable

	attr_reader :field

	def initialize (field)
		@field = field
	end

	undef_method :map!
	undef_method :collect!
	undef_method :fill

	def << (obj)
		field.validate!(obj)

		super
	end

	def []= (*args, obj)
		field.validate!(obj)

		super
	end

	def insert (index, *obj)
		obj.each { |o| field.validate!(o) }

		super
	end

	def push (*obj)
		obj.each { |o| field.validate!(o) }

		super
	end

	def replace (other)
		other.each { |o| field.validate!(o) }

		super
	end

	def unshift (*obj)
		obj.each { |o| field.validate!(o) }

		super
	end
end

end
