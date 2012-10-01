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

class Option
	include Comparable

	attr_reader :name, :value

	def initialize (name, value, custom = true)
		@name   = name
		@value  = value
		@custom = custom
	end

	def custom?
		@custom
	end
end

class Options
	include Enumerable

	attr_reader :for

	def initialize (what, options = [])
		@for     = what
		@options = options.map {|what|
			what.is_a?(Option) ? what : Option.new(*what)
		}
	end

	def add (name, value, custom = false)
		Option.new(name, value, custom).tap {|option|
			@options << option
		}
	end

	def each (&block)
		return enum_for :each unless block

		@options.each(&block)

		self
	end

	def normal (&block)
		each { |o| block.call o unless o.custom? }
	end

	def custom (&block)
		each { |o| block.call o if o.custom? }
	end

	def has? (what)
		!!self[what]
	end

	def [] (what)
		find { |o| what === o.name || what.to_s == o.name.to_s }
	end
end

end
