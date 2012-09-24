#--
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#++

require 'parslet'
require 'sexp_processor'

module ProtoBuffo

class Parser < Parslet::Parser
	rule(:expression) {
		comment | import | package | option | extend | enum | message | str(';')
	}

	rule(:expressions) {
		(expression | space).repeat
	}

	root :expressions

	rule(:comment) {
		str('//') >> (match['\r\n'].absnt? >> any).repeat.as(:comment)
	}

	rule(:import) {
		str('import') >> space? >> string.as(:import) >> space? >> str(';')
	}

	rule(:package) {
		str('package') >> space >> identifiers.as(:package) >> space? >> str(';')
	}

	rule(:option) {
		str('option') >> space >> (
			identifiers.as(:name) >> space? >> str('=') >> space? >> constant.as(:value)
		).as(:option) >> str(';')
	}

	rule(:extend) {
		str('extend') >> space >> (user_type.as(:name) >> space? >> str('{') >>
			(field | str(';') | space).repeat.as(:body) >>
		str('}')).as(:extend)
	}

	rule(:message) {
		str('message') >> space >> (identifier.as(:name) >> space? >> str('{') >> (
			comment | field | enum | message | extend | extensions | option | str(';') | space
		).repeat.as(:body) >> str('}')).as(:message)
	}

	rule(:field) {
		(label >> space? >> type >> space? >> identifier >>
			space? >> str('=') >> space? >> integer.as(:tag) >>
			(space? >> str('[') >> space? >> field_option.repeat(1, 1) >>
			 (space? >> str(',') >> space? >> field_option).repeat.maybe >>
			space? >> str(']')).maybe).as(:field) >> space? >> str(';')
	}

	rule(:field_option) { (
		(str('default') | str('packed') | str('deprecated') | identifiers).as(:name) >> space? >> str('=') >> space? >> constant.as(:value)
	).as(:field_option) }

	rule(:enum) {
		str('enum') >> space >> (identifier.as(:name) >> space? >> str('{') >> (
			option | enum_field | space | str(';')
		).repeat.as(:body) >> str('}')).as(:enum)
	}

	rule(:enum_field) { (
		identifier.as(:name) >> space? >> str('=') >> space? >> integer.as(:value) >> space? >> str(';')
	).as(:enum_field) }

	rule(:extensions) {
		str('extensions') >> space >> (extension.repeat(1, 1) >>
			(space? >> str(',') >> space? >> extension).repeat.maybe).as(:extensions) >> space? >> str(';')
	}

	rule(:extension) { (
		integer.as(:from) >> (space? >> str('to') >> space? >> (integer | str('max')).as(:to)).maybe
	).as(:extension) }

	rule(:identifier) {
		(match('[A-Za-z_]') >> match('[\w_]').repeat).as(:identifier)
	}

	rule(:identifiers) {
		identifier.repeat(1, 1) >> (str('.') >> identifier).repeat
	}

	rule(:user_type) {
		(str('.').maybe.as(:fully_qualified) >> identifiers).as(:user_type)
	}

	rule(:label) {
		(str('required') | str('optional') | str('repeated')).as(:label)
	}

	rule(:type) { (
		str('double') | str('float') | str('int32') | str('int64') | str('uint32') | str('uint64') |
		str('sint32') | str('sint64') | str('fixed32') | str('fixed64') | str('sfixed32') |
		str('sfixed64') | str('bool') | str('string') | str('bytes') | user_type
	).as(:type) }

	rule(:integer) {
		decimal | hexadecimal | octal
	}

	rule(:decimal) { (
		(match('[1-9]') >> match('\d').repeat) |
		(str('0') >> match('[xX0-7]').absnt?)
	).as(:decimal) }

	rule(:hexadecimal) {
		(str('0') >> (str('x') | str('X')) >> match('[A-Fa-f0-9]').repeat(1)).as(:hexadecimal)
	}

	rule(:octal) {
		(str('0') >> match('[0-7]').repeat(1)).as(:octal)
	}

	rule(:float) { (
		match('\d').repeat(1) >>
		(str('.') >> match('\d').repeat(1)).maybe >>
		((str('e') | str('E')) >> (str('+') | str('-')).maybe >> match('\d').repeat(1)).maybe
	).as(:float) }

	rule(:string) {
		(str('"') >> (
			str('\\') >> any |
			str('"').absent? >> any
		).repeat.as(:string) >> str('"')) |

		(str("'") >> (
			str('\\') >> any |
			str("'").absent? >> any
		).repeat.as(:string) >> str("'")) >> space?
	}

	rule(:bool) {
		(str('true') | str('false')).as(:bool)
	}

	rule(:constant) {
		user_type | integer | float | string | bool
	}

	rule(:space)  { match('\s').repeat(1) }
	rule(:space?) { space.maybe }
end

class Transform < Parslet::Transform
	rule(:comment => simple(:text)) {
		s(:comment, text.to_s)
	}

	rule(:import => simple(:text)) {
		s(:import, text.to_s)
	}

	rule(:package => subtree(:identifiers)) {
		s(:package, Identifier.new(identifiers.pop, identifiers, true))
	}

	rule(:option => subtree(:descriptor)) {
		s(:option, Identifier.new(descriptor[:name].pop, descriptor[:name]), descriptor[:value])
	}

	rule(:extend => subtree(:descriptor)) {
		s(:extend, Identifier.new(descriptor[:name]), *descriptor[:body])
	}

	rule(:message => subtree(:descriptor)) {
		if descriptor[:body].is_a?(Array)
			s(:message, Identifier.new(descriptor[:name]), *descriptor[:body])
		else
			s(:message, Identifier.new(descriptor[:name]))
		end
	}

	rule(:extensions => subtree(:extensions)) {
		s(:extensions, *extensions)
	}

	rule(:extension => subtree(:descriptor)) {
		if descriptor[:to]
			s(:extension, descriptor[:from], descriptor[:to] == 'max' ? 536_870_911 : descriptor[:to])
		else
			s(:extension, descriptor[:from])
		end
	}

	rule(:enum => subtree(:descriptor)) {
		s(:enum, Identifier.new(descriptor[:name]), *descriptor[:body])
	}

	rule(:enum_field => subtree(:descriptor)) {
		[Identifier.new(descriptor[:name].to_s), descriptor[:value]]
	}

	rule(:field => subtree(:payload)) {
		descriptor, *options = payload
		type                 = descriptor[:type].is_a?(Identifier) ? descriptor[:type] : descriptor[:type].to_sym

		s(:field, Identifier.new(descriptor[:identifier].to_s), type, descriptor[:label].to_sym, descriptor[:tag], options)
	}

	rule(:field_option => subtree(:descriptor)) {
		name = %w(default packed deprecated).member?(descriptor[:name]) ?
			descriptor[:name].to_sym : Identifier.new(descriptor[:name].pop, descriptor[:name])

		[name, descriptor[:value]]
	}

	rule(:identifier => simple(:text)) {
		text.to_s
	}

	rule(:tag => simple(:text)) {
		text.to_s.to_i.tap {|x|
			if x == 0 || x >= 2 ** 29 || !(x < 19000 && x > 19999)
				raise RuntimeError, 'invalid tag number'
			end
		}
	}

	rule(:user_type => subtree(:descriptor)) {
		fully_qualified = descriptor.shift[:fully_qualified]
		name            = descriptor.pop
		namespace       = descriptor

		Identifier.new(name, namespace, fully_qualified)
	}

	rule(:decimal => simple(:text)) {
		text.to_i
	}

	rule(:hexadecimal => simple(:text)) {
		text.to_i(16)
	}

	rule(:octal => simple(:text)) {
		text.to_i(8)
	}

	rule(:float => simple(:text)) {
		text.to_f
	}

	rule(:string => simple(:text)) {
		text.to_s
	}

	rule(:bool => simple(:text)) {
		text == 'true'
	}
end

end
