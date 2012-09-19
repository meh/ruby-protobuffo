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
	class << self
		def package (value = nil)
			value ? @package = value : @package
		end

		def name (value = nil)
			value ? @name = value : @name || super
		end

		def fields
			@fields ||= []
		end

		# TODO: implement proper checking for repeated fields
		def field (rule, type, name, tag, options = {})
			fields << Field.new(rule, type, name, tag, options).tap {|field|
				instance_variable_name = "@#{name}".to_sym

				if field.repeated?
					define_method name do |&block|
						return enum_for name unless block

						return unless instance_variable_defined? instance_variable_name

						instance_variable_get(instance_variable_name).each(&block)

						self
					end

					define_method "add_#{name}" do |value|
						field.verify_value!(value)

						unless instance_variable_defined? instance_variable_name
							instance_variable_set instance_variable_name, []
						end

						instance_variable_get(instance_variable_name).push(value)

						self
					end

					define_method "clear_#{name}" do
						unless instance_variable_defined? instance_variable_name
							instance_variable_set instance_variable_name, []
						end

						instance_variable_get(instance_variable_name).clear

						self
					end

					define_method "delete_#{name}" do |value|
						unless instance_variable_defined? instance_variable_name
							instance_variable_set instance_variable_name, []
						end

						instance_variable_get(instance_variable_name).delete(value)
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

						field.verify_value!(value)

						instance_variable_set instance_variable_name, value
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

		def unpack (io, options = {})
			wire    = Wire.new(io)
			message = new

			until wire.to_io.eof?
				tag, type = wire.read_info

				if field = fields.find { |f| f.tag == tag }
					if type != Wire.type_for(field.type) && !(field.repeated? && type == Wire.type_for(:bytes))
						raise "wrong type for #{field.name} for #{name} in #{package}"
					end

					if field.repeated?
						if type == Wire.type_for(:bytes)
							tmp = Wire.new(wire.read_bytes)

							until tmp.to_io.eof?
								message.add(field.name, tmp.read(field.type))
							end
						else
							message.add(field.name, wire.read(field.type))
						end
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
			next unless field = self.class.fields.find { |f| f.name == name }

			if field.repeated?
				value.each {|value|
					add(name, value)
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

	def add (name, value)
		__send__ "add_#{name}", value
	end

	def delete (name, value)
		__send__ "delete_#{name}", value
	end

	def clear (name)
		__send__ "clear_#{name}"
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

		self.class.fields.sort_by(&:tag).each {|field|
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
