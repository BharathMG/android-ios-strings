require File.join(File.dirname(__FILE__), 'parser.rb')

# Reads translation to be ignored
class IgnoredParser
  include Parser

  def initialize(file)
    @file = file
  end

  private

  def extract
    File.readlines(@file, &:strip)
  end
end
