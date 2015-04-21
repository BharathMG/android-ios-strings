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
    keys_count = count_map[:keys]
    values_count = count_map[:values]
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
    keys_count = count_map[:keys]
    values_count = count_map[:values]
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


end

count_map = { :keys => {}, :values => {}}
android_map = Parser::read_android(ARGV[0], count_map)
ios_map = Parser::read_ios(ARGV[1], count_map)


count_map.select { |key, value| value == 1  }.each  { |key, value|
  if android_map.has_key?(key)
    puts "#{key} is absent in iOS resource file"
  else
    puts "#{key} is absent in Android resource file"
  end
}

count = 0
ios_map.each { |key, value|
  if !android_map[key].eql?(value)
    count += 1
    puts "[#{key} => #{value}] on iOS is different from [#{key} => #{android_map[key]}] on Android"
  end
}

puts "Total number of keys in android:  #{android_map.count}"
puts "Total number of keys in iOS:  #{ios_map.count}"
puts "Number of mismatches: #{count}"