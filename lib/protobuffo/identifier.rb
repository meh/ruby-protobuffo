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
	def self.new (*args)
		return args.first if args.length == 1 && args.first.is_a?(Identifier)

		super
	end

	attr_reader :namespace, :name, :type

	def initialize (*args)
		if args.last === true || args.last === false
			@fully_qualified = args.pop
		end

		identifier = args.flatten.compact.join('.')

		fully_qualified! if identifier.start_with? '.'

		identifier.split('.').reject(&:empty?).tap {|args|
			@name      = args.pop
			@namespace = args
		}
	end

	def fully_qualified!
		@fully_qualified = true

		self
	end

	def unqualified!
		@fully_qualified = false
	end

	def fully_qualified?
		@fully_qualified
	end

	def hash
		to_s.hash
	end

	def == (other)
		to_s == other.to_s
	end

	alias eql? ==

	def add (name)
		Identifier.new(to_a, name, fully_qualified?)
	end

	def to_a
		namespace + [@name]
	end

	def to_str
		(fully_qualified? ? '.' : '') << to_a.join('.')
	end

	alias to_s to_str

	def to_sym
		to_s.to_sym
	end
end

end
