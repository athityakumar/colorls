# frozen_string_literal: true

require 'optparse'
require 'colorls/version'
require 'ostruct'

module ColorLS
  class Flags
    def initialize(*args)
      @args = args
      @light_colors = false

      @opts = default_opts
      @show_report = false
      @exit_status_code = 0

      parse_options

      return unless @opts[:mode] == :tree

      # FIXME: `--all` and `--tree` do not work together, use `--almost-all` instead
      @opts[:almost_all] = true if @opts[:all]
      @opts[:all] = false
    end

    def process
      init_locale

      @args = ['.'] if @args.empty?

      process_args
    end

    def options
      list = @parser.top.list + @parser.base.list

      result = list.collect do |o|
        next unless o.respond_to? :desc

        flags = o.short + o.long
        next if flags.empty?

        args = o.pattern.keys if Hash === o.pattern
        OpenStruct.new(flags: flags, desc: o.desc, args: args)
      end

      result.compact
    end

    private

    def init_locale
      # initialize locale from environment
      CLocale.setlocale(CLocale::LC_COLLATE, '')
    rescue RuntimeError => e
      warn "WARN: #{e}, check your locale settings"
    end

    def group_files_and_directories
      infos = @args.flat_map do |arg|
        FileInfo.info(arg)
      rescue Errno::ENOENT
        $stderr.puts "colorls: Specified path '#{arg}' doesn't exist.".colorize(:red)
        @exit_status_code = 2
        []
      rescue SystemCallError => e
        $stderr.puts "#{path}: #{e}".colorize(:red)
        @exit_status_code = 2
        []
      end

      infos.group_by(&:directory?).values_at(true, false)
    end

    def process_args
      core = Core.new(**@opts)

      directories, files = group_files_and_directories

      core.ls_files(files) unless files.nil?

      directories&.sort_by! do |a|
        CLocale.strxfrm(a.name)
      end&.each do |dir|
        puts "\n#{dir.show}:" if @args.size > 1

        core.ls_dir(dir)
      rescue SystemCallError => e
        $stderr.puts "#{dir}: #{e}".colorize(:red)
      end

      core.display_report if @show_report

      @exit_status_code
    end

    def default_opts
      {
        show: false,
        sort: true,
        reverse: false,
        group: nil,
        mode: STDOUT.tty? ? :vertical : :one_per_line, # rubocop:disable Style/GlobalStdStream
        all: false,
        almost_all: false,
        git_status: false,
        colors: [],
        tree_depth: 3,
        show_group: true,
        show_user: true,
        indicator_style: 'slash',
        time_style: ''
      }
    end

    def add_sort_options(options)
      options.separator ''
      options.separator 'sorting options:'
      options.separator ''
      options.on('--sd', '--sort-dirs', '--group-directories-first', 'sort directories first') { @opts[:group] = :dirs }
      options.on('--sf', '--sort-files', 'sort files first')                               { @opts[:group] = :files }
      options.on('-t', 'sort by modification time, newest first')                          { @opts[:sort] = :time }
      options.on('-U', 'do not sort; list entries in directory order')                     { @opts[:sort] = false }
      options.on('-S', 'sort by file size, largest first')                                 { @opts[:sort] = :size }
      options.on('-X', 'sort by file extension')                                           { @opts[:sort] = :extension }
      options.on(
        '--sort=WORD',
        %w[none time size extension],
        'sort by WORD instead of name: none, size (-S), time (-t), extension (-X)'
      ) do |word|
        @opts[:sort] = case word
                       when 'none' then false
                       else word.to_sym
                       end
      end

      options.on('-r', '--reverse', 'reverse order while sorting') { @opts[:reverse] = true }
    end

    def add_common_options(options)
      options.on('-a', '--all', 'do not ignore entries starting with .')  { @opts[:all] = true }
      options.on('-A', '--almost-all', 'do not list . and ..')            { @opts[:almost_all] = true }
      options.on('-d', '--dirs', 'show only directories')                 { @opts[:show] = :dirs }
      options.on('-f', '--files', 'show only files')                      { @opts[:show] = :files }
      options.on('--gs', '--git-status', 'show git status for each file') { @opts[:git_status] = true }
      options.on('--report', 'show brief report')                         { @show_report = true }
      options.on('-p', 'append / indicator to directories')               { @opts[:indicator_style] = 'slash' }
      options.on(
        '--indicator-style=[STYLE]',
        %w[none slash], 'append indicator with style STYLE to entry names: none, slash (-p) (default)'
      ) do |style|
        @opts[:indicator_style] = style
      end
    end

    def add_format_options(options)
      options.on(
        '--format=WORD', %w[across horizontal long single-column],
        'use format: across (-x), horizontal (-x), long (-l), single-column (-1), vertical (-C)'
      ) do |word|
        case word
        when 'across', 'horizontal' then @opts[:mode] = :horizontal
        when 'vertical' then @opts[:mode] = :vertical
        when 'long' then @opts[:mode] = :long
        when 'single-column' then @opts[:mode] = :one_per_line
        end
      end
      options.on('-1', 'list one file per line') { @opts[:mode] = :one_per_line }
      options.on('--tree=[DEPTH]', Integer, 'shows tree view of the directory') do |depth|
        @opts[:tree_depth] = depth
        @opts[:mode] = :tree
      end
      options.on('-x', 'list entries by lines instead of by columns')     { @opts[:mode] = :horizontal }
      options.on('-C', 'list entries by columns instead of by lines')     { @opts[:mode] = :vertical }
    end

    def add_long_style_options(options)
      options.on('-l', '--long', 'use a long listing format')             { @opts[:mode] = :long }
      options.on('-o', 'use a long listing format without group information') do
        @opts[:mode] = :long
        @opts[:show_group] = false
      end
      options.on('-g', 'use a long listing format without owner information') do
        @opts[:mode] = :long
        @opts[:show_user] = false
      end
      options.on('-G', '--no-group', 'show no group information in a long listing') { @opts[:show_group] = false }
      options.on('--time-style=FORMAT', String, 'use time display format') do |time_style|
        @opts[:time_style] = time_style
      end
    end

    def add_general_options(options)
      options.separator ''
      options.separator 'general options:'
      options.separator ''

      options.on(
        '--color=[WHEN]', %w[always auto never],
        'colorize the output: auto, always (default if omitted), never'
      ) do |word|
        # let Rainbow decide in "auto" mode
        Rainbow.enabled = (word != 'never') unless word == 'auto'
      end
      options.on('--light', 'use light color scheme') { @light_colors = true }
      options.on('--dark', 'use dark color scheme') { @light_colors = false }
      options.on('--hyperlink') { @opts[:hyperlink] = true }
    end

    def add_compatiblity_options(options)
      options.separator ''
      options.separator 'options for compatiblity with ls (ignored):'
      options.separator ''
      options.on('-h', '--human-readable') {} # always active
    end

    def show_help
      puts @parser
      show_examples
      exit
    end

    def add_help_option(opts)
      opts.separator ''
      opts.on_tail('--help', 'prints this help') { show_help }
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

    def assign_each_options(opts)
      add_common_options(opts)
      add_format_options(opts)
      add_long_style_options(opts)
      add_sort_options(opts)
      add_compatiblity_options(opts)
      add_general_options(opts)
      add_help_option(opts)
    end

    def parse_options
      @parser = OptionParser.new do |opts|
        opts.banner = 'Usage:  colorls [OPTION]... [FILE]...'
        opts.separator ''

        assign_each_options(opts)

        opts.on_tail('--version', 'show version') do
          puts ColorLS::VERSION
          exit
        end
      end

      # show help and exit if the only argument is -h
      show_help if !@args.empty? && @args.all?('-h')

      @parser.parse!(@args)

      set_color_opts
    rescue OptionParser::ParseError => e
      warn "colorls: #{e}\nSee 'colorls --help'."
      exit 2
    end

    def set_color_opts
      color_scheme_file = @light_colors ? 'light_colors.yaml' : 'dark_colors.yaml'
      @opts[:colors] = ColorLS::Yaml.new(color_scheme_file).load(aliase: true)
    end
  end
end
