module ColorLS
  class Flags
    def initialize(*args)
      @args = args
      set_color_opts

      @opts = {
        show: fetch_show_opts,
        sort: fetch_sort_opts,
        all: flag_given?(%w[-a --all]),
        almost_all: flag_given?(%w[-A --almost-all]),
        report: flag_given?(%w[-r --report]),
        one_per_line: flag_given?(%w[-1]) || !STDOUT.tty?,
        long: flag_given?(%w[-l --long]),
        tree: flag_given?(%w[-t --tree]),
        help: flag_given?(%w[-h --help]),
        git_status: flag_given?(%w[-gs --git-status]),
        colors: @colors
      }

      @args.keep_if { |arg| !arg.start_with?('-') }
    end

    def process
      incompatible = report_incompatible_flags
      return STDERR.puts "\n   #{incompatible}".colorize(:red) if incompatible

      return Core.new(@opts).ls if @args.empty?

      @args.each do |path|
        next STDERR.puts "\n   Specified path '#{path}' doesn't exist.".colorize(:red) unless File.exist?(path)
        Core.new(path, @opts).ls
      end
    end

    private

    def flag_given?(flags)
      flags.each { |flag| return true if @args.include?(flag) }
      false
    end

    def set_color_opts
      light_colors = flag_given? %w[--light]
      dark_colors  = flag_given? %w[--dark]

      if light_colors && dark_colors
        @colors = ColorLS.load_from_yaml('dark_colors.yaml', true)
        STDERR.puts "\n Restrain from using --light and --dark flags together."
          .colorize(@colors[:error])
      elsif light_colors
        @colors = ColorLS.load_from_yaml('light_colors.yaml', true)
      else # default colors
        @colors = ColorLS.load_from_yaml('dark_colors.yaml', true)
      end

      @colors
    end

    def fetch_show_opts
      show_dirs_only   = flag_given? %w[-d --dirs]
      show_files_only  = flag_given? %w[-f --files]

      if show_files_only && show_dirs_only
        STDERR.puts "\n  Restrain from using -d and -f flags together."
          .colorize(@colors[:error])
        return nil
      else
        return :files if show_files_only
        return :dirs  if show_dirs_only
        false
      end
    end

    def fetch_sort_opts
      sort_dirs_first  = flag_given? %w[-sd --sort-dirs --group-directories-first]
      sort_files_first = flag_given? %w[-sf --sort-files]

      if sort_dirs_first && sort_files_first
        STDERR.puts "\n  Restrain from using -sd and -sf flags together."
          .colorize(@colors[:error])
        return nil
      else
        return :files if sort_files_first
        return :dirs  if sort_dirs_first
        false
      end
    end

    def report_incompatible_flags
      return '' if @opts[:show].nil? || @opts[:sort].nil?

      return 'Restrain from using -t (--tree) and -r (--report) flags together.' if @opts[:tree] && @opts[:report]

      return 'Restrain from using -t (--tree) and -a (--all) flags together.' if @opts[:tree] && @opts[:all]

      nil
    end
  end
end
