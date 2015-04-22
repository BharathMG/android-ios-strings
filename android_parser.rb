require "cgi"

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

            key = key_match[1]
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
            strings_map[key] = value
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
          key = match[1]
          key.downcase!
          value = match[2]
          value.gsub!('\\"', '"')
          key.gsub!(/[^a-zA-Z0-9]/, '')
          key.strip!
          ios_map[key] =value
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


  count_map.select { |key, value| value == 1  }.each  { |key, value|
    if android_map.has_key?(key)
      puts "ISSUE: Key #{key} is absent in iOS resource file"
      android_extra_keys_count += 1
    else
      puts "ISSUE: Key #{key} is absent in Android resource file"
      ios_extra_keys_count += 1
    end
  }


  ios_map.each { |key, value|
    if android_map.include?(key) && !android_map[key].eql?(value)
      mismatch_count += 1
      puts "ISSUE: [#{key} => #{value}] on iOS is different from [#{key} => #{android_map[key]}] on Android"
    end
  }

  puts "\n\nAndroid la motham :  #{android_map.count} key"
  puts "IOS la :  #{ios_map.count} key"

  puts "Athula #{mismatch_count} mismatchuuu"
  puts "Itha thavara android la egstra #{android_extra_keys_count}  key"
  puts "IOS la #{ios_extra_keys_count} key"

  if mismatch_count == 0 && android_extra_keys_count == 0 && ios_extra_keys_count == 0
    puts "he he.. AAGA MOTHATHULA VETRI..."
  else
    puts "AAAGA MOTHATHULA FAILURUUUU.."
  end
  puts "VARATUMA...AAGN"
end

end
