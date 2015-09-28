require './lib/report.rb'

desc 'Compare iOS and Android strings'
task :compare, [:ios, :android, :ignored, :language] do |_t, args|
  report_file = "report_#{args[:language]}.html"
  report = Report.new(
    android_file: args[:android],
    ios_file: args[:ios],
    ignored_file: args[:ignored]
  )
  result = report.generate report_file
  error = result[:mismatches].count > 0
  report.print error
  fail "Mismatch found, for more info check #{report_file}" if error
end

desc 'Generate Android strings from iOS resource'
task :convert do
  puts 'hi'
end
