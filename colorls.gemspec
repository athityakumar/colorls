# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'colorls/version'

Gem::Specification.new do |spec|
  spec.name          = 'colorls'
  spec.version       = ColorLS::VERSION
  spec.authors       = ['Athitya Kumar']
  spec.email         = ['athityakumar@gmail.com']

  spec.summary       = "A Ruby CLI gem that beautifies the terminal's ls command, with color and font-awesome icons."
  spec.homepage      = 'https://github.com/athityakumar/colorls'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = 'colorls'
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'colorize'
  spec.add_runtime_dependency 'facets'
  spec.add_runtime_dependency 'ruby-terminfo'
  spec.add_runtime_dependency 'filesize'
  spec.add_runtime_dependency 'git'

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'diffy'
end
