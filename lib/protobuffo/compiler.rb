#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'sexp_processor'

module ProtoBuffo

class Compiler < SexpProcessor
	attr_reader :options

	def initialize (options = {})
		@options = { indentation: '  ' }.merge(options)
	end
end

end
