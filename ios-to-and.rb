File.open("strings.xml","w") { |f|
  f.write("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n")
  f.write("<resources>\n")

  ARGF.each do |line|
    if (line =~ /\"(.*)\"\s*=\s*\"(.*)\"/)
      tag = $1
      value = $2

      tag.gsub!(/[^a-zA-Z0-9]/, "_")
      tag.downcase!

      value.gsub!(/&/, "&amp;")
      f.write("\t<string name=\"#{tag}\">#{value}</string>\n")
    end
  end

  f.write("</resources>")
  f.close()
}
