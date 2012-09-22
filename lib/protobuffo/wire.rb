#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'stringio'

module ProtoBuffo

class Wire
	MIN_UINT32 = 0
	MAX_UINT32 = (1 << 32) - 1

	MIN_INT32 = -(1 << 31)
	MAX_INT32 =  (1 << 32) - 1

	MIN_UINT64 = 0
	MAX_UINT64 = (1 << 64) - 1

	MIN_INT64 = -(1 << 63)
	MAX_INT64 =  (1 << 64) - 1

	def self.type_for (name)
		case name
			when :int32, :sint32, :uint32, :int64, :sint64, :uint64, :bool then 0
			when :fixed64, :sfixed64, :double                              then 1
			when :string, :bytes                                           then 2
			when :fixed32, :sfixed32, :float                               then 5

			else raise ArgumentError, "#{name} is an unknown type"
		end
	end

	def initialize (io = nil)
		if io.nil? || io.is_a?(String)
			@io = StringIO.new(*io)
			@io.set_encoding 'BINARY'
		else
			@io = io
		end
	end

	def write (type, *args)
		__send__ "write_#{type}", *args
	end

	def write_raw (data)
		@io.write(data.is_a?(Integer) ? data.chr : data)
	end

	def write_type (type, value)
		case type.is_a?(Integer) ? type : Wire.type_for(type)
			when 0 then write_uint64(value)
			when 1 then write_fixed64(value)
			when 2 then write_bytes(value)
			when 5 then write_fixed32(value)

			else raise ArgumentError, "#{type} is an unknown wire type"
		end
	end

	def write_info (tag, type)
		write_uint32((tag << 3) | (type.is_a?(Integer) ? type : Wire.type_for(type)))
	end

	def write_fixed32 (n)
		if n < MIN_UINT32 || n > MAX_UINT32
			raise ArgumentError, "#{n} isn't between #{MIN_UINT32} and #{MAX_UINT32}"
		end

		write_raw([n].pack('V'))

		self
	end

	def write_sfixed32 (n)
		write_fixed32(encode_zigzag(n, 32))
	end

	def write_fixed64 (n)
		if n < MIN_UINT64 || n > MAX_UINT64
			raise ArgumentError, "#{n} isn't between #{MIN_UINT64} and #{MAX_UINT64}"
		end

		write_raw([n & 0xFFFFFFFF, n >> 32].pack('VV'))

		self
	end

	def write_sfixed64 (n)
		write_fixed64(encode_zigzag(n, 64))

		self
	end

	def write_int32 (n)
		if n < MIN_INT32 || n > MAX_INT32
			raise ArgumentError, "#{n} isn't between #{MIN_INT32} and #{MAX_INT32}"
		end

		write_int64(n)
	end

	def write_sint32 (n)
		write_uint32(encode_zigzag(n, 32))
	end

	def write_uint32 (n)
		if n < MIN_UINT32 || n > MAX_UINT32
			raise ArgumentError, "#{n} isn't between #{MIN_UINT32} and #{MAX_UINT32}"
		end

		write_uint64(n)
	end

	def write_int64 (n)
		if n < MIN_INT64 || n > MAX_INT64
			raise ArgumentError, "#{n} isn't between #{MIN_INT64} and #{MAX_INT64}"
		end

		write_uint64(n < 0 ? n + (1 << 64) : n)
	end

	def write_sint64 (n)
		write_uint64(encode_zigzag(n, 64))
	end

	def write_uint64 (n)
		if n < MIN_UINT64 || n > MAX_UINT64
			raise ArgumentError, "#{n} isn't between #{MIN_UINT64} and #{MAX_UINT64}"
		end

		until n == 0
			bits   = n & 0x7F
			n    >>= 7

			write_raw(n == 0 ? bits : (bits | 0x80))
		end

		self
	end

	def write_float (n)
		write_raw([n].pack('e'))
		
		self
	end

	def write_double (n)
		write_raw([n].pack('E'))

		self
	end

	def write_bool (n)
		write_uint64(n ? 1 : 0)

		self
	end

	def write_string (string)
		write_uint64(string.bytesize)
		write_raw(string)

		self
	end

	alias write_bytes write_string

	def read (type)
		__send__ "read_#{type}"
	end

	def read_raw (size)
		@io.read(size)
	end

	def read_type (type)
		case type.is_a?(Integer) ? type : Wire.type_for(type)
			when 0 then read_uint64
			when 1 then read_fixed64
			when 2 then read_bytes
			when 5 then read_fixed32

			else raise ArgumentError, "#{type} is an unknown wire type"
		end
	end

	def read_info
		n    = read_uint64
		tag  = n >> 3
		type = n & 0x7

		[tag, type]
	end

	def read_fixed32
		read_raw(4).unpack('V').first
	end

	def read_sfixed32
		decode_zigzag(read_fixed32)
	end

	def read_fixed64
		a, b = read_raw(8).unpack('VV')

		a + (b << 32)
	end

	def read_sfixed64
		decode_zigzag(read_fixed64)
	end

	def read_int32
		n = read_uint64

		n > MAX_INT32 ? (n - (1 << 32)) : n
	end

	def read_sint32
		decode_zigzag(read_uint32)
	end

	def read_uint32
		read_uint64
	end

	def read_int64
		n = read_uint64

		n > MAX_INT64 ? (n - (1 << 64)) : n
	end

	def read_sint64
		decode_zigzag(read_uint64)
	end

	def read_uint64
		n     = 0
		shift = 0
		b     = 0xff

		until (b & 0x80) == 0
			if shift >= 64
				raise BufferOverflowError, "varint"
			end

			b      = read_raw(1).ord
			n     |= ((b & 0x7F) << shift)
			shift += 7
		end

		n
	end

	def read_float
		read_raw(4).unpack('e').first
	end

	def read_double
		read_raw(8).unpack('E').first
	end

	def read_string
		read_raw(read_uint64).force_encoding('UTF-8')
	end

	def read_bytes
		read_raw(read_uint64).force_encoding('BINARY')
	end

	def to_io
		@io
	end

private
	def encode_zigzag (n, bits)
		(n << 1) ^ (n >> (bits - 1))
	end

	def decode_zigzag (n)
		(n >> 1) ^ -(n & 1)
	end
end

end
