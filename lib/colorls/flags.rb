require 'optparse'
require 'colorls/version'
require 'ostruct'

module ColorLS
  class Flags
    def initialize(*args)
      @args = args
      @light_colors = false

      @opts = {
        show: false,
        sort: true,
        reverse: false,
        group: nil,
        mode: STDOUT.tty? || :one_per_line,
        all: false,
        almost_all: false,
        report: false,
        git_status: false,
        colors: []
      }

      parse_options

      return unless @opts[:mode] == :tree

      # FIXME: `--all` and `--tree` do not work together, use `--almost-all` instead
      @opts[:almost_all] = true if @opts[:all]
      @opts[:all] = false

      # `--tree` does not support reports
      @opts[:report] = false
    end

    def process
      # initialize locale from environment
      CLocale.setlocale(CLocale::LC_COLLATE, '')

      @args = [Dir.pwd] if @args.empty?
      @args.sort!.each_with_index do |path, i|
        begin
          next STDERR.puts "\n   Specified path '#{path}' doesn't exist.".colorize(:red) unless File.exist?(path)
          puts '' if i > 0
          puts "\n#{path}:" if Dir.exist?(path) && @args.size > 1
          Core.new(path, @opts).ls
        rescue SystemCallError => e
          STDERR.puts "#{path}: #{e}".colorize(:red)
        end
      end
    end

    def options
      list = @parser.top.list + @parser.base.list

      result = list.collect do |o|
        next unless o.respond_to? 'desc'

        flags = o.short + o.long
        next if flags.empty?

        args = o.pattern.keys if Hash === o.pattern
        OpenStruct.new(flags: flags, desc: o.desc, args: args)
      end

      result.compact
    end

    private

    def add_sort_options(options)
      options.separator ''
      options.separator 'sorting options:'
      options.separator ''
      options.on('--sd', '--sort-dirs', '--group-directories-first', 'sort directories first') { @opts[:group] = :dirs }
      options.on('--sf', '--sort-files', 'sort files first')                                  { @opts[:group] = :files }
      options.on('-t', 'sort by modification time, newest first')                             { @opts[:sort] = :time }
      options.on('-U', 'do not sort; list entries in directory order')                        { @opts[:sort] = false }
      options.on('-S', 'sort by file size, largest first')                                    { @opts[:sort] = :size }
      options.on(
        '--sort=WORD',
        %w[none time size],
        'sort by WORD instead of name: none, size (-S), time (-t)'
      ) do |word|
        @opts[:sort] = case word
                       when 'none' then false
                       when 'time' then :time
                       when 'size' then :size
                       end
      end

      options.on('-r', '--reverse', 'reverse order while sorting') { @opts[:reverse] = true }
    end

    def add_common_options(options)
      options.on('-a', '--all', 'do not ignore entries starting with .')  { @opts[:all] = true }
      options.on('-A', '--almost-all', 'do not list . and ..')            { @opts[:almost_all] = true }
      options.on('-l', '--long', 'use a long listing format')             { @opts[:mode] = :long }
      options.on('--tree', 'shows tree view of the directory')            { @opts[:mode] = :tree }
      options.on('--report', 'show brief report')                         { @opts[:report] = true }
      options.on('-1', 'list one file per line')                          { @opts[:mode] = :one_per_line }
      options.on('-d', '--dirs', 'show only directories')                 { @opts[:show] = :dirs }
      options.on('-f', '--files', 'show only files')                      { @opts[:show] = :files }
      options.on('--gs', '--git-status', 'show git status for each file') { @opts[:git_status] = true }
    end

    def add_general_options(options)
      options.separator ''
      options.separator 'general options:'

      options.separator ''
      options.on('--light', 'use light color scheme') { @light_colors = true }
      options.on('--dark', 'use dark color scheme') { @light_colors = false }
    end

    def show_examples
      puts <<EXAMPLES.gsub(/^  /, '')

  examples:

    * show the given file:

      #{'colorls README.md'.colorize(:green)}

    * show matching files and list matching directories:

      #{'colorls *'.colorize(:green)}

    * filter output by a regular expression:

      #{'colorls | grep PATTERN'.colorize(:green)}

    * several short options can be combined:

      #{'colorls -d -l -a'.colorize(:green)}
      #{'colorls -dla'.colorize(:green)}

EXAMPLES
    end

    def parse_options
      @parser = OptionParser.new do |opts|
        opts.banner = 'Usage:  colorls [OPTION]... [FILE]...'
        opts.separator ''

        add_common_options(opts)
        add_sort_options(opts)
        add_general_options(opts)

        opts.separator ''
        opts.on_tail('-h', '--help', 'prints this help') do
          puts @parser
          show_examples
          exit
        end
        opts.on_tail('--version', 'show version') do
          puts ColorLS::VERSION
          exit
        end
      end

      @parser.parse!(@args)

      set_color_opts
    end

    def set_color_opts
      color_scheme_file = @light_colors ? 'light_colors.yaml' : 'dark_colors.yaml'
      @opts[:colors] = ColorLS::Yaml.new(color_scheme_file).load(aliase: true)
    end
  end
end
