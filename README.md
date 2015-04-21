# android-ios-strings
Tool to compare Android and iOS Strings resources. Inspired from Twine repo.

## Usage
###Convert ios strings to android
execute `ruby ios-to-android "ios string resource name"`

the output will be stored in a file named "strings.xml" in the current working directory

###Compare ios strings to android
execute `ruby android_parser.rb "android string resource name" "ios string resource name"`

the output will be printed in the console
