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
		comment | import | package | option | extend | message
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
		str('extend') >> space >> (user_type.as(:name) >> str('{') >>
			(field | str(';') | space).repeat.as(:body) >>
		str('{')).as(:extend)
	}

	rule(:message) {
		str('message') >> space >> (identifier.as(:name) >> space? >> str('{') >>
			(comment | field | enum | message | extend | extensions | option | str(';') | space).repeat.as(:body) >>
		str('}')).as(:message)
	}

	rule(:field) {
		(label >> space? >> type >> space? >> identifier >>
			(space? >> str('=') >> space? >> integer.as(:tag)).maybe >>
			(space? >> str('[') >> space? >> field_option.repeat(1, 1).as(:option) >>
			 (space? >> str(',') >> space? >> field_option).repeat.maybe.as(:option) >>
			space? >> str(']')).maybe).as(:field) >> space? >> str(';')
	}

	rule(:field_option) {
		(str('default') | identifiers).as(:name) >> space? >> str('=') >> space? >> constant.as(:value)
	}

	rule(:enum) {
		str('enum') >> space >> (identifier.as(:name) >> str('{') >>
			(option | (
				identifier.as(:name) >> space? >> str('=') >> space? >> integer.as(:value) >> space? >> str(';')
			).as(:field) | str(';')).repeat.as(:body) >>
		str('}')).as(:enum)
	}

	rule(:extensions) {
		str('extensions') >> space >> (integer.as(:from) >>
			(space? >> str('to') >> space? >> (integer | str('max')).as(:to)).maybe).as(:extensions)
	}

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

	rule(:decimal) {
		(match('[1-9]') >> match('\d').repeat).as(:decimal)
	}

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
		identifier | integer | float | string | bool
	}

	rule(:space)  { match('\s').repeat(1) }
	rule(:space?) { space.maybe }
end

class Transform < Parslet::Transform
	rule(:comment => simple(:text)) {
		s(:comment, text.to_s)
	}

	rule(:package => subtree(:identifiers)) {
		s(:package, Identifier.new(identifiers.pop, identifiers))
	}

	rule(:message => subtree(:descriptor)) {
		s(:message, Identifier.new(descriptor[:name]), *descriptor[:body])
	}

	rule(:field => subtree(:descriptor)) {
		type = descriptor[:type].is_a?(Identifier) ? descriptor[:type] : descriptor[:type].to_sym

		s(:field, Identifier.new(descriptor[:identifier].to_s), type, descriptor[:label].to_sym, descriptor[:tag])
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
