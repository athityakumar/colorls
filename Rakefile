require 'bundler/setup'
require 'rubygems/tasks'
Gem::Tasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rubocop/rake_task'
RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-rspec'
end

desc 'Build the manual'
file 'man/colorls.1' => ['man/colorls.1.ronn', 'lib/colorls/flags.rb'] do
  require 'colorls'
  require 'ronn'

  flags = ColorLS::Flags.new
  attributes = {
    date: Time.now,
    manual: 'colorls Manual',
    organization: "colorls #{ColorLS::VERSION}"
  }
  doc = Ronn::Document.new(nil, attributes) do
    template = IO.read('man/colorls.1.ronn')

    section = ''
    flags.options.each do |o|
      section += <<OPTION
  * `#{o.flags.join('`, `')}`:
     #{o.desc.join("<br>\n")}

OPTION
    end
    template.sub('{{ OPTIONS }}', section)
  end
  IO.write('man/colorls.1', doc.convert('roff'))
end

desc 'Build the Zsh completion file'
file 'zsh/_colorls' => ['lib/colorls/flags.rb'] do
  ruby "exe/colorls '--*-completion-zsh=colorls' > zsh/_colorls"
end

task default: %w[spec rubocop]
