require "cgi"
require "colorize"
require './ios-to-and.rb'


module Parser
  def Parser.read_android(path, count_map)
    resources_regex = /<resources(?:[^>]*)>(.*)<\/resources>/m
    key_regex = /<string name="(\w+)">/
    comment_regex = /<!-- (.*) -->/
    value_regex = /<string name="\w+">(.*)<\/string>/
    key = nil
    value = nil
    strings_map = {}
    File.open(path, 'r:UTF-8') do |f|
      content_match = resources_regex.match(f.read)
      if content_match
        for line in content_match[1].split(/\r?\n/)
          key_match = key_regex.match(line)
          if key_match

            original_key,key = key_match[1], key_match[1]
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
            key.gsub!(/[^a-zA-Z0-9]/, '')
            key.strip!
            strings_map[key] = { :key => original_key, :value => value }
            count_map[key] = count_map[key].to_i + 1
          end
        end
      end
    end
    strings_map
  end


  def Parser.read_ios(path, count_map)
    sep = "\n"
    ios_map = {}
    File.open(path, 'r:UTF-8') do |f|
      while line = (sep) ? f.gets(sep) : f.gets
        match = /"((?:[^"\\]|\\.)+)"\s*=\s*"((?:[^"\\]|\\.)*)"/.match(line)
        if match
          original_key, key = match[1], match[1]
          key.downcase!
          value = match[2]
          value.gsub!('\\"', '"')
          key.gsub!(/[^a-zA-Z0-9]/, '')
          key.strip!
          ios_map[key] = { :key => original_key, :value => value }
          count_map[key] = count_map[key].to_i + 1
        end
      end
    end
    ios_map
  end




def Parser.run(android_string, ios_string)
  count_map = {}
  android_map = Parser::read_android(android_string, count_map)
  ios_map = Parser::read_ios(ios_string, count_map)

  mismatch_count = 0
  android_extra_keys_count = 0
  ios_extra_keys_count = 0

  android_strings = []
  count_map.select { |key, value| value == 1  }.each  { |key, value|
    if android_map.has_key?(key)
      puts "ISSUE: Key \"#{android_map[key][:key]}\" is absent in iOS resource file".red
      android_extra_keys_count += 1
    else
      puts "ISSUE: Key \"#{ios_map[key][:key]}\" is absent in Android resource file".red
      android_strings << "<string name=\"#{Converter::androidify(ios_map[key][:key])}\"> \"#{ios_map[key][:value]}\" </string>".green
      ios_extra_keys_count += 1
    end
  }


  ios_map.each { |key, hash|
    if android_map.include?(key) && !android_map[key][:value].eql?(hash[:value])
      mismatch_count += 1
      puts "ISSUE: [#{hash[:key]} => #{hash[:value]}] in iOS is different from [#{android_map[key][:key]} => #{android_map[key][:value]}] in Android".red
    end
  }

  puts "\n\nTotal number of keys in android:  #{android_map.count}"
  puts "Total number of keys in iOS:  #{ios_map.count}"

  puts "Number of value mismatches: #{mismatch_count}"
  puts "Number of extra keys in android: #{android_extra_keys_count}"
  puts "Number of extra keys in ios: #{ios_extra_keys_count}"

  if !android_strings.empty?
    puts "\n Please include the following line in strings.xml".green
    android_strings.each do |line|
      puts line
    end
  end

  if mismatch_count == 0 && android_extra_keys_count == 0 && ios_extra_keys_count == 0
    puts "SUCCESS".green
  else
    puts "FAILURE".red
    raise "Mismatch found"
  end


end

end
