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

class Message
	autoload :Field, 'protobuffo/message/field'
	autoload :Fields, 'protobuffo/message/fields'
	autoload :Unknown, 'protobuffo/message/unknown'
	autoload :Repeated, 'protobuffo/message/repeated'

	class << self
		def identifier (value = nil)
			value ? @identifier : @identifier = Identifier.new(value)
		end

		def options
			@options ||= Options.new(self)
		end

		def option (name, value, custom = false)
			options.add(name, value, custom)
		end

		def fields
			@fields ||= Fields.new(self)
		end

		def field (rule, type, name, tag, options = [])
			fields.add(rule, type, name, tag, options, @extension).tap {|field|
				instance_variable_name = "@#{name}".to_sym

				if field.repeated?
					define_method name do |&block|
						unless instance_variable_defined? instance_variable_name
							instance_variable_set instance_variable_name, Repeated.new(field)
						end

						instance_variable_get(instance_variable_name)
					end
				else
					attr_reader name

					define_method "#{name}=" do |value|
						if value.nil?
							instance_variable_set instance_variable_name, value

							return
						end

						if field.deprecated? && !instance_variable_defined?(instance_variable_name)
							warn "#{name} is deprecated for #{self.class.name} in #{self.class.package}"
						end

						instance_variable_set instance_variable_name, field.validate!(value)
					end
				end
			}
		end

		def required (*args)
			field :required, *args
		end

		def optional (*args)
			field :optional, *args
		end

		def repeated (*args)
			field :repeated, *args
		end

		def extensions (what)
			fields.add_extensions(what)
		end

		def extension (&block)
			@extension = true

			yield
		ensure
			@extension = false
		end

		def unpack (io, options = {})
			wire    = Wire.new(io)
			message = new

			until wire.to_io.eof?
				tag, type = wire.read_info

				if field = fields.find { |f| f.tag == tag }
					unless type == Wire.type_for(:bytes) && field.repeated? || field.type.is_a?(Class)
						raise "wrong type for #{field.name} for #{name} in #{package}" if type != Wire.type_for(field.type)
					end

					if field.repeated?
						if type == Wire.type_for(:bytes)
							tmp = Wire.new(wire.read_bytes)

							until tmp.to_io.eof?
								message[field.name].push(tmp.read(field.type))
							end
						else
							message[field.name].push(wire.read(field.type))
						end
					elsif field.type.is_a?(Enum)
						message[field.name] = wire.read_int32
					elsif field.type.is_a?(Class)
						message[field.name] = wire.read_bytes
					else
						message[field.name] = wire.read(field.type)
					end
				else
					message.unknown << Unknown.new(tag, type, wire.read_type(type))
				end

				break if options[:until_complete] && message.complete?
			end

			fields.each {|field|
				message[field.name] ||= field.default
			}

			message.validate!

			message
		end
	end

	def initialize (values = {})
		set(values)
	end

	def set (values = {})
		values.each {|name, value|
			next unless field = self.class.fields[name]

			if field.repeated?
				unless value.respond_to? :each
					raise ArgumentError, "#{value.inspect} has to be Enumerable"
				end

				value.each {|value|
					self[name].push(value)
				}
			else
				self[name] = value
			end
		}

		self
	end

	def package
		self.class.package
	end

	def [] (name)
		__send__ name
	end

	def []= (name, value)
		__send__ "#{name}=", value
	end

	def unknown
		@unknown || []
	end

	def validate!
		self.class.fields.each {|field|
			if field.required? && self[field.name].nil?
				raise "#{field.name} is a required field but has no value"
			end
		}
	end

	def complete?
		self.class.fields.each {|field|
			return false if field.required? && self[field.name].nil?
		}

		true
	end

	def pack (io = nil)
		validate!

		wire = Wire.new(io)

		self.class.fields.each {|field|
			if field.repeated?
				if field.packed?
					wire.write_info(field.tag, :bytes)
					wire.write_bytes(Wire.new.tap {|w|
						self[field.name].each {|value|
							w.write(field.type, value)
						}
					}.to_io.string)
				else
					self[field.name].each {|value|
						wire.write_info(field.tag, field.type)
						wire.write(field.type, value)
					}
				end
			else
				case field.type
				when Class
					wire.write_info field.tag, :bytes
					wire.write_bytes self[field.name].pack.string

				when Enum
					wire.write_info field.tag, :int32
					wire.write_int32 field.type.to_i(self[field.name])

				else
					wire.write_info field.tag, field.type
					wire.write field.type, self[field.name]
				end
			end
		}

		unknown.each {|unknown|
			wire.write_info unknown.tag, unknown.type
			wire.write_type unknown.type, unknown.value
		}

		wire.to_io
	end
end

end
