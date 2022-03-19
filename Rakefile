# frozen_string_literal: true

require 'bundler/setup'
require 'rubygems/tasks'
Gem::Tasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--warnings'
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new

desc 'Build the manual'
file 'man/colorls.1' => ['man/colorls.1.ronn', 'lib/colorls/flags.rb'] do
  require 'colorls'
  require 'date'
  require 'ronn'

  flags = ColorLS::Flags.new
  attributes = {
    date: Date.iso8601(`git log -1 --pretty=format:%cI -- lib/colorls/flags.rb`),
    manual: 'colorls Manual',
    organization: "colorls #{ColorLS::VERSION}"
  }
  doc = Ronn::Document.new(nil, attributes) do
    template = File.read('man/colorls.1.ronn')

    section = ''
    flags.options.each do |o|
      section += <<OPTION
  * `#{o.flags.join('`, `')}`:
     #{o.desc.join("<br>\n")}

OPTION
    end
    template.sub('{{ OPTIONS }}', section)
  end
  File.write('man/colorls.1', doc.convert('roff'))
end

directory 'zsh'

desc 'Build the Zsh completion file'
file 'zsh/_colorls' => %w[zsh lib/colorls/flags.rb] do
  ruby "exe/colorls '--*-completion-zsh=colorls' > zsh/_colorls"
end

task default: %w[spec rubocop man/colorls.1 zsh/_colorls]
