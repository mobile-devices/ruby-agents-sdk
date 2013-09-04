YARD::Parser::SourceParser.parser_type = :ruby18



class GeneratedCodeHandler < YARD::Tags::Directive

  def call
    raise TagFormatError if tag.name.nil? && tag.text.to_s.empty?
    raise TagFormatError if object.nil?

   object.name(nil)

  end



end

YARD::Tags::Library.define_directive("generated", nil, GeneratedCodeHandler)