require File.join(File.dirname(__FILE__), 'parser.rb')
require('oga')

# Android strings xml parser
class AndroidParser
  include Parser

  def initialize(file)
    @file = file
  end

  private

  def extract
    document = Oga.parse_xml(File.open(@file, 'rb:UTF-8'))
    document.xpath('//string').each_with_object({}) do |node, result|
      result[node.attribute(:name).value] = node.text
    end
  end
end
