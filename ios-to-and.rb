require 'colorize'
module Converter
  def Converter.run(path)
    File.open("strings.xml","w") { |f|
      f.write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n")
      f.write("<resources>\n")

      File.open(path, 'r').each do |line|
        if (line =~ /\"(.*)\"\s*=\s*\"(.*)\"/)
          tag = $1
          value = $2
          androidify(tag)
          value.gsub!(/&/, "&amp;")
          value.gsub!("'","\\\\'")
          value.gsub!("%@","%s")
          f.write("\t<string name=\"#{tag}\">#{value}</string>\n")
        end
      end

      f.write("</resources>")
      f.close()
      puts "Converted ios strings to android strings.".green
    }
  end


  def Converter.androidify(key)
    key[-1] = key[-1].gsub(/[^a-zA-Z0-9]/, "")
    key.gsub!(/[^a-zA-Z0-9]/, "_")
    key.downcase!
    key
  end

end
