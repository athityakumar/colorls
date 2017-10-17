require 'optparse'
require 'colorls/version'

module ColorLS
  class Flags
    def initialize(*args)
      @args = args
      @light_colors = false
      @opts = {
        show: false,
        sort: false,
        all: false,
        almost_all: false,
        report: false,
        one_per_line: !STDOUT.tty?,
        long: false,
        tree: false,
        git_status: false,
        colors: []
      }

      parse_options
    end

    def process
      return STDERR.puts "\n   #{incompatible_flags?}".colorize(:red) if incompatible_flags?

      return Core.new(@opts).ls if @args.empty?
      @args.each do |path|
        next STDERR.puts "\n   Specified path '#{path}' doesn't exist.".colorize(:red) unless File.exist?(path)
        Core.new(path, @opts).ls
      end
    end

    private

    def add_sort_options(options)
      options.separator ''
      options.separator 'sorting options:'
      options.separator ''
      options.on('--sd', '--sort-dirs', '--group-directories-first', 'sort directories first') { @opts[:sort] = :dirs }
      options.on('--sf', '--sort-files', 'sort files first')                                   { @opts[:sort] = :files }
    end

    def add_common_options(options)
      options.on('-a', '--all', 'do not ignore entries starting with .')  { @opts[:all] = true }
      options.on('-A', '--almost-all', 'do not list . and ..')            { @opts[:almost_all] = true }
      options.on('-l', '--long', 'use a long listing format')             { @opts[:long] = true }
      options.on('-t', '--tree', 'shows tree view of the directory')      { @opts[:tree] = true }
      options.on('-r', '--report', 'show brief report')                   { @opts[:report] = true }
      options.on('-1', 'list one file per line')                          { @opts[:one_per_line] = true }
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

    def incompatible_flags?
      return '' if @opts[:show].nil? || @opts[:sort].nil?

      [
        ['-t (--tree)', @opts[:tree], '-r (--report)', @opts[:report]],
        ['-t (--tree)', @opts[:tree], '-l (--long)',   @opts[:long]],
        ['-t (--tree)', @opts[:tree], '-a (--all)',    @opts[:all]]
      ].each do |flag1, hasflag1, flag2, hasflag2|
        return "Restrain from using #{flag1} and #{flag2} flags together." if hasflag1 && hasflag2
      end

      nil
    end
  end
end
