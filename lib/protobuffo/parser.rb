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

class ProtoBuffo

class Parser < Parslet::Parser
	rule(:expression) {
		import | package | option | extend | message
	}

	rule(:expressions) {
		(expression | space).repeat
	}

	root :expressions

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
			(field | enum | message | extend | extensions | option | str(';') | space).repeat.as(:body) >>
		str('}')).as(:message)
	}

	rule(:field) {
		(label >> space? >> type >> space? >> identifier >>
			(space? >> str('=') >> space? >> integer.as(:tag)).maybe).as(:field)
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
		str('"') >> (
			str('\\') >> any |
			str('"').absent? >> any
		).repeat.as(:string) >> str('"') >> space?
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

end

end
