require File.join(File.dirname(__FILE__), 'parser.rb')

# IOS Localizable.strings parser
class IosParser
  include Parser

  def initialize(file)
    @file = file
  end

  private

  def extract
    File.readlines(@file).each_with_object({}) do |line, result|
      translation_line = match_line(line)
      if translation_line
        translation = parse_key_and_value(translation_line)
        result[translation[:key]] = translation[:value]
      end
    end
  end

  def match_line(line)
    /"((?:[^"\\]|\\.)+)"\s*=\s*"((?:[^"\\]|\\.)*)"/.match(line)
  end

  def parse_key_and_value(match)
    key = match[1].tr(' ', '_').strip.downcase
    value = match[2]
    value.gsub!('\\"', '"')
    value.gsub!("'") { |value_to_replace| '\\' + value_to_replace }
    value.gsub!('%@', '%s')
    value.gsub!('\n', ' ')
    { key: key.strip, value: value.strip }
  end
end
