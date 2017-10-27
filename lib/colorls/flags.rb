require 'optparse'
require 'colorls/version'

module ColorLS
  class Flags
    def initialize(*args)
      @args = args
      @light_colors = false
      @mode = :one_per_line unless STDOUT.tty?

      @opts = {
        show: false,
        sort: true,
        group: nil,
        all: false,
        almost_all: false,
        report: false,
        git_status: false,
        colors: []
      }

      parse_options

      # handle mutual exclusive options
      %i[tree long one_per_line].each do |value|
        @opts[value] = @mode == value
      end

      return unless @mode == :tree

      # FIXME: `--all` and `--tree` do not work together, use `--almost-all` instead
      @opts[:almost_all] = true if @opts[:all]
      @opts[:all] = false

      # `--tree` does not support reports
      @opts[:report] = false
    end

    def process
      return Core.new(@opts).ls if @args.empty?
      @args.sort!.each_with_index do |path, i|
        next STDERR.puts "\n   Specified path '#{path}' doesn't exist.".colorize(:red) unless File.exist?(path)
        puts '' if i > 0
        puts "#{path}:" if Dir.exist?(path) && @args.size > 1
        Core.new(path, @opts).ls
      end
    end

    private

    def add_sort_options(options)
      options.separator ''
      options.separator 'sorting options:'
      options.separator ''
      options.on('--sd', '--sort-dirs', '--group-directories-first', 'sort directories first') { @opts[:group] = :dirs }
      options.on('--sf', '--sort-files', 'sort files first')                                  { @opts[:group] = :files }
      options.on('-t', 'sort by modification time, newest first')                             { @opts[:sort] = :time }
      options.on('--sort=WORD', %w[none time], 'sort by WORD instead of name: none, time (-t)') do |word|
        @opts[:sort] = case word
                       when 'none' then false
                       when 'time' then :time
                       end
      end
    end

    def add_common_options(options)
      options.on('-a', '--all', 'do not ignore entries starting with .')  { @opts[:all] = true }
      options.on('-A', '--almost-all', 'do not list . and ..')            { @opts[:almost_all] = true }
      options.on('-l', '--long', 'use a long listing format')             { @mode = :long }
      options.on('-t', '--tree', 'shows tree view of the directory')      { @mode = :tree }
      options.on('-r', '--report', 'show brief report')                   { @opts[:report] = true }
      options.on('-1', 'list one file per line')                          { @mode = :one_per_line }
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
      parser = OptionParser.new do |opts|
        opts.banner = 'Usage:  colorls [OPTION]... [FILE]...'
        opts.separator ''

        add_common_options(opts)
        add_sort_options(opts)
        add_general_options(opts)

        opts.separator ''
        opts.on_tail('-h', '--help', 'prints this help') do
          puts parser
          show_examples
          exit
        end
        opts.on_tail('--version', 'show version') do
          puts ColorLS::VERSION
          exit
        end
      end

      parser.parse!(@args)

      set_color_opts
    end

    def set_color_opts
      color_scheme_file = @light_colors ? 'light_colors.yaml' : 'dark_colors.yaml'
      @opts[:colors] = ColorLS.load_from_yaml(color_scheme_file, true)
    end
  end
end
