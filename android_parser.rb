require "cgi"
require "colorize"
require './ios-to-and.rb'


module Parser
  class Analyser
    @@count_map = {}
    PRE_QUOTE_WITH_SPACE = " \""
    POST_QUOTE_WITH_SPACE = "\" "


    def processAndTrack(original_key, key, value)
      key.gsub!(/[^a-zA-Z0-9]/, '')
      key.strip!
      source_map[key] = {:key => original_key, :value => value}
      @@count_map[key] = @@count_map[key].to_i + 1
    end

    def self.count_map
      @@count_map
    end

    def self.generate_report(android_string, ios_string)
      android_parser = Parser::AndroidParser.new
      ios_parser = Parser::IosParser.new
      android_map = android_parser.read(android_string)
      ios_map = ios_parser.read(ios_string)



      mismatch_count = 0

      count_map.select { |key, value| value == 1 }.each { |key, value|
        unless android_parser.has_extra_keys_issue(key)
          ios_parser.raise_extra_keys_issue(key)
          android_parser.generate_xml_for(ios_map[key][:key], ios_map[key][:value])
        end
      }

      ios_map.each { |key, hash|
        if android_map.include?(key) && !android_map[key][:value].eql?(PRE_QUOTE_WITH_SPACE + hash[:value] + POST_QUOTE_WITH_SPACE)
          mismatch_count += 1
          puts "ISSUE: [#{hash[:key]} => #{hash[:value]}] in iOS is different from [#{android_map[key][:key]} => #{android_map[key][:value]}] in Android".red
        end
      }

      puts "\n\nTotal number of keys in android:  #{android_map.count}"
      puts "Total number of keys in iOS:  #{ios_map.count}"

      puts "Number of value mismatches: #{mismatch_count}"
      puts "Number of extra keys in android: #{android_parser.extra_keys_count}"
      puts "Number of extra keys in ios: #{ios_parser.extra_keys_count}"

      if !android_parser.get_android_strings.empty?
        puts "\n Please include the following line in strings.xml".green
        android_parser.get_android_strings.each do |line|
          puts line
        end
      end

      if mismatch_count == 0 && ios_parser.extra_keys_count == 0
        puts "SUCCESS".green
      else
        puts "FAILURE".red
        raise "Mismatch found"
      end
    end
  end

  class AndroidParser < Analyser

    def initialize
      super
      @strings_map = {}
      @android_extra_keys_count = 0
      @android_strings = []
    end

    def source_map
      @strings_map
    end

    def match_line(line)
      key_regex = /<string name="(\w+)">/
      key_regex.match(line)
    end

    def getKeyAndValue(key_match, line)
      value_regex = /<string name="\w+">(.*)<\/string>/
      original_key, key = key_match[1], key_match[1]
      key.downcase!
      value_match = value_regex.match(line)
      if value_match
        value = value_match[1]
        value = CGI.unescapeHTML(value)
        value.gsub!('\\\'', '\'')
        value.gsub!('\\"', '"')
        value.gsub!(/(\\u0020)*|(\\u0020)*\z/) { |spaces| ' ' * (spaces.length / 6) }
      else
        value = ""
      end
      return original_key, key, value
    end


    def read(path)
      resources_regex = /<resources(?:[^>]*)>(.*)<\/resources>/m
      comment_regex = /<!-- (.*) -->/
      original_key = nil
      key = nil
      value = nil
      File.open(path, 'r:UTF-8') do |f|
        content_match = resources_regex.match(f.read)
        if content_match
          for line in content_match[1].split(/\r?\n/)
            key_match = match_line(line)
            if key_match
              original_key, key, value = getKeyAndValue(key_match, line)
              processAndTrack(original_key, key, value)
            end
          end
        end
      end
      @strings_map
    end

    def extra_keys_count
      @android_extra_keys_count
    end

    def has_extra_keys_issue(key)
      if source_map.has_key?(key)
        puts "ISSUE: Key \"#{source_map[key][:key]}\" is absent in iOS resource file".red
        @android_extra_keys_count += 1
        return true
      end
      return false
    end

    def generate_xml_for(key, value)
      output_key = Converter::androidify(key)
      output_string = "<string name=\"#{output_key}\"> \"#{value}\" </string>"
      @android_strings << output_string
    end

    def get_android_strings
      @android_strings
    end
  end

  class IosParser < Analyser
    def initialize
      super
      @ios_map = {}
      @ios_extra_keys_count = 0
    end

    def source_map
      @ios_map
    end

    def extra_keys_count
      @ios_extra_keys_count
    end

    def match_line(line)
      /"((?:[^"\\]|\\.)+)"\s*=\s*"((?:[^"\\]|\\.)*)"/.match(line)
    end

    def getKeyAndValue(match)
      original_key, key = match[1], match[1]
      key.downcase!
      value = match[2]
      value.gsub!('\\"', '"')
      return original_key, key, value
    end

    def read(path)
      sep = "\n"
      ios_map = {}
      File.open(path, 'r:UTF-8') do |f|
        while line = (sep) ? f.gets(sep) : f.gets
          match = match_line(line)
          if match
            original_key, key, value = getKeyAndValue(match)
            processAndTrack(original_key, key, value)
          end
        end
      end
      @ios_map
    end


    def raise_extra_keys_issue(key)
      if source_map.has_key?(key)
        puts "ISSUE: Key \"#{source_map[key][:key]}\" is absent in Android resource file".red
        @ios_extra_keys_count += 1
      end
    end

  end




  def Parser.run(android_string, ios_string)
    Analyser.generate_report(android_string, ios_string)
  end
end
