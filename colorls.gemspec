# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'colorls/version'

POST_INSTALL_MESSAGE = %(
  *******************************************************************
    Changes introduced in colorls

    Sort by dirs  : -sd flag has been renamed to --sd
    Sort by files : -sf flag has been renamed to --sf
    Git status    : -gs flag has been renamed to --gs

    Clubbed flags : `colorls -ald` works
    Help menu     : `colorls -h` provides all possible flag options

    Tab completion enabled for flags

    -t flag : Previously short for --tree, has been re-allocated to sort results by time
    -r flag : Previously short for --report, has been re-allocated to reverse sort results

    Man pages have been added. Checkout `man colorls`.

  *******************************************************************
)

Gem::Specification.new do |spec|
  is_tagged = ENV['GITHUB_REF'] == "refs/tags/v#{ColorLS::VERSION}"
  is_origin = ENV['GITHUB_REPOSITORY_OWNER'] == 'athityakumar'
  build_number = ENV.fetch('GITHUB_RUN_NUMBER', nil)

  spec.name          = 'colorls'
  spec.version       = if build_number && is_origin && !is_tagged
                         # Prereleasing on Github
                         digits = ColorLS::VERSION.to_s.split '.'
                         digits[-1] = digits[-1].to_s.succ

                         digits.join('.') + ".pre.#{build_number}"
                       else
                         ColorLS::VERSION
                       end
  spec.authors       = ['Athitya Kumar']
  spec.email         = ['athityakumar@gmail.com']
  spec.summary       = "A Ruby CLI gem that beautifies the terminal's ls command, with color and font-awesome icons."
  spec.homepage      = 'https://github.com/athityakumar/colorls'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.6.0'

  spec.files = %w[man/colorls.1 man/colorls.1 zsh/_colorls] + IO.popen(
    %w[git ls-files -z], external_encoding: Encoding::ASCII_8BIT
  ).read.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|[.]github)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = 'colorls'
  spec.require_paths = ['lib']

  spec.post_install_message = POST_INSTALL_MESSAGE

  spec.add_runtime_dependency 'addressable', '~> 2.7'
  spec.add_runtime_dependency 'clocale', '~> 0'
  spec.add_runtime_dependency 'filesize', '~> 0'
  spec.add_runtime_dependency 'manpages', '~> 0'
  spec.add_runtime_dependency 'rainbow', '>= 2.2', '< 4.0'
  spec.add_runtime_dependency 'unicode-display_width', '>= 1.7', '< 3.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'codecov', '~> 0.1'
  spec.add_development_dependency 'diffy', '3.4.2'
  spec.add_development_dependency 'rake', '~> 13'
  spec.add_development_dependency 'rdoc', '~> 6.1'
  spec.add_development_dependency 'ronn', '~> 0'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'rspec-its', '~> 1.2'
  spec.add_development_dependency 'rubocop', '~> 1.50.1'
  spec.add_development_dependency 'rubocop-performance', '~> 1.17.1'
  spec.add_development_dependency 'rubocop-rake', '~> 0.5'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.20.0'
  spec.add_development_dependency 'rubygems-tasks', '~> 0'
  spec.add_development_dependency 'simplecov', '~> 0.22.0'
end
