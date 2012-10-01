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
	autoload :Value, 'protobuffo/enum/value'
	autoload :Values, 'protobuffo/enum/values'

	class << self
		def options
			@options ||= Options.new(self)
		end

		def option (name, value, custom = false)
			options.add(name, value, custom)
		end

		def values
			@values ||= []
		end

		def value (name, value, options = [])
			Value.new(name, value, options).tap {|v|
				values << v
			}
		end

		def [] (what)
			values.find { |v| what === v.name || what.to_s == v.name.to_s }
		end

		def const_missing (name)
			self[name]
		end
	end
end

end
