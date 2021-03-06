# frozen_string_literal: true

require 'yaml'
require 'etc'
require 'English'
require 'filesize'
require 'io/console'
require 'io/console/size'
require 'rainbow/ext/string'
require 'clocale'
require 'unicode/display_width'
require 'addressable/uri'

require_relative 'colorls/core'
require_relative 'colorls/fileinfo'
require_relative 'colorls/flags'
require_relative 'colorls/layout'
require_relative 'colorls/yaml'
require_relative 'colorls/monkeys'
require_relative 'colorls/git'
