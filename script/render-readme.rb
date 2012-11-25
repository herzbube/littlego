#/usr/bin/env ruby

# Run this script with the following command line
#   ruby -rubygems script/render-readme.rb >README.html
# in the project's top-level folder. View the resulting README.html in a browser
# to see how GitHub will render README.mediawiki once it has been pushed.
#
# To install the "github/markup" Ruby gem:
#   git clone git://github.com/github/markup.git
#   cd markup
#   gem install github-markup
#   gem install wikicloth
#
# See: https://github.com/github/markup

require 'github/markup'
file = "README.mediawiki"
renderedOutput = GitHub::Markup.render(file, File.read(file))
print renderedOutput
