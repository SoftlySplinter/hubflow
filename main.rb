# Load the bundled environment
require "rubygems"
require "bundler/setup"

# Require gems specified in the Gemfile
require "hubflow"

HubFlow::Runner.new(*ARGV)
