module ColorLS
  class Flags
    def initialize(*args)
      @args = args
      set_color_opts

      @opts = {
        show:         fetch_show_opts,
        sort:         fetch_sort_opts,
        all:          flag_given?(%w[-a --all]),
        almost_all:   flag_given?(%w[-A --almost-all]),
        report:       flag_given?(%w[-r --report]),
        one_per_line: flag_given?(%w[-1]) || !STDOUT.tty?,
        long:         flag_given?(%w[-l --long]),
        tree:         flag_given?(%w[-t --tree]),
        git_status:   flag_given?(%w[--gs --git-status]),
        colors: @colors
      }

      @args.keep_if { |arg| !arg.start_with?('-') }
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

    def flag_given?(flags)
      return true if flags.any? { |flag| @args.include?(flag) }

      clubbable_flags = flags.reject { |flag| flag.start_with?('--') }
                             .map { |flag| flag[1..-1] }

      # Some flags should be not be able to be clubbed with other flags
      @args.select { |arg| !arg.start_with?('--') && arg.start_with?('-') }
           .any? { |arg| clubbable_flags.any? { |flag| arg.include?(flag) } }
    end

    def set_color_opts
      light_colors = flag_given? %w[--light]
      dark_colors  = flag_given? %w[--dark]

      if light_colors && dark_colors
        STDERR.puts "\n Restrain from using --light and --dark flags together."
          .colorize(@colors[:error])
      end

      color_scheme_file = light_colors ? 'light_colors.yaml' : 'dark_colors.yaml'
      @colors = ColorLS.load_from_yaml(color_scheme_file, true)
    end

    def fetch_show_opts
      show_dirs_only   = flag_given? %w[-d --dirs]
      show_files_only  = flag_given? %w[-f --files]

      if show_files_only && show_dirs_only
        STDERR.puts "\n  Restrain from using -d and -f flags together."
          .colorize(@colors[:error])
      else
        return :files if show_files_only
        return :dirs  if show_dirs_only
        false
      end
    end

    def fetch_sort_opts
      sort_dirs_first  = flag_given? %w[--sd --sort-dirs --group-directories-first]
      sort_files_first = flag_given? %w[--sf --sort-files]

      if sort_dirs_first && sort_files_first
        STDERR.puts "\n  Restrain from using --sd and -sf flags together."
          .colorize(@colors[:error])
      else
        return :files if sort_files_first
        return :dirs  if sort_dirs_first
        false
      end
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
