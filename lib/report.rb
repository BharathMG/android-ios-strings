BASE_PATH = File.dirname(__FILE__)

require('erb')
require('colorize')
require File.join(BASE_PATH, 'android_parser.rb')
require File.join(BASE_PATH, 'ios_parser.rb')
require File.join(BASE_PATH, 'ignored_parser.rb')

# Generate comparision report
class Report
  def initialize(files)
    @android_parser = AndroidParser.new(files[:android_file])
    @ios_parser = IosParser.new(files[:ios_file])
    @ignored_string_parser = IgnoredParser.new(files[:ignored_file])
  end

  def generate(report_file)
    template_file = File.join(BASE_PATH, '..', 'templates', 'report.html.erb')
    File.open(File.join(BASE_PATH, '..', report_file), 'w') do |file|
      file.write ERB.new(File.read(template_file)).result(data)
    end
    { missing_in_android: @missing_in_android,
      missing_in_ios: @missing_in_ios,
      mismatches: @mismatches }
  end

  def print(error)
    unless error
      puts 'Looks good'.colorize(:green)
      return
    end
    puts 'Result'.colorize(:red).underline
    puts "Mismatch count: #{@mismatches.count}".colorize(:red)
    puts "Missing translations in Android: #{@missing_in_android.count}".colorize(:red)
    puts "Missing translations in ios: #{@missing_in_ios.count}".colorize(:red)
  end

  private

  def data
    translations = {
      android: valid_android_translations,
      ios: valid_ios_translations
    }
    @missing_in_android = translation_missing_in_android translations
    @missing_in_ios = translation_missing_in_ios translations
    @mismatches = android_translation_mismatches translations
    binding
  end

  def valid_android_translations
    ignored_translations = @ignored_string_parser.parse
    @android_parser.parse.select { |key| !ignored_translations.include? key }
  end

  def valid_ios_translations
    ignored_translations = @ignored_string_parser.parse
    @ios_parser.parse.select { |key| !ignored_translations.include? key }
  end

  def android_translation_mismatches(translations)
    translations[:android].each_with_object([]) do |(key, value), result|
      ios_translation = translations[:ios][key]
      next unless ios_translation
      next if ios_translation == value
      result << { key: key, android: value, ios: ios_translation }
    end
  end

  def translation_missing_in_android(translations)
    translations[:ios].each_with_object([]) do |(key, value), result|
      android_translation = translations[:android][key]
      next if android_translation
      result << { key: key, value: value }
    end
  end

  def translation_missing_in_ios(translations)
    translations[:android].each_with_object([]) do |(key, value), result|
      ios_translation = translations[:ios][key]
      next if ios_translation
      result << { key: key, value: value }
    end
  end
end
