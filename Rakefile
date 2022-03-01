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
    date: Date.iso8601(`git log -1 --pretty=format:%cI -- man/colorls.1`),
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

desc 'Build the Zsh completion file'
file 'zsh/_colorls' => ['lib/colorls/flags.rb'] do
  ruby "exe/colorls '--*-completion-zsh=colorls' > zsh/_colorls"
end

desc 'Build Fish completion file'
file 'colorls.fish' => ['lib/colorls/flags.rb'] do
  require 'colorls'
  require 'shellwords'

  flags = ColorLS::Flags.new
  flags.options.each do |o|
    short_and_long = o.flags.collect do |option|
      case option
      when /^--/ then "-l #{option[2..-1]}"
      else "-s #{option[1..-1]}"
      end
    end.join(' ')

    fixed_args = " -x -a #{Shellwords.escape o.args.join(' ')}" unless o.args.nil?

    puts "complete -c colorls #{short_and_long} -d #{Shellwords.escape o.desc.first}#{fixed_args}"
  end
end

task default: %w[spec rubocop]
