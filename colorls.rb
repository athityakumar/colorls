require 'yaml'
require 'facets'
require 'terminfo'

require_relative 'monkey_patching'
require_relative 'helper'
require_relative 'core'

ColorLS::Core.new(*ARGV).ls
true
