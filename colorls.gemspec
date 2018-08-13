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
).freeze

# rubocop:disable Metrics/BlockLength
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

  spec.post_install_message = POST_INSTALL_MESSAGE

  spec.add_runtime_dependency 'clocale', '~> 0'
  spec.add_runtime_dependency 'filesize', '~> 0'
  spec.add_runtime_dependency 'manpages', '~> 0'
  spec.add_runtime_dependency 'rainbow', '>= 2.2', '< 4.0'

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'diffy', '~> 3'
  spec.add_development_dependency 'rake', '~> 12'
  spec.add_development_dependency 'ronn', '~> 0'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'rspec-its', '~> 1.2'
  spec.add_development_dependency 'rubocop', '~> 0.57.2'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.27'
  spec.add_development_dependency 'rubygems-tasks', '~> 0'
  spec.add_development_dependency 'simplecov', '~> 0.16.1'
end
# rubocop:enable Metrics/BlockLength
