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
      STDERR.puts "\n   #{incompatible}".colorize(:red) if incompatible

      if @args.empty?
        Core.new(@opts).ls 
      else
        @args.each do |path|
          next STDERR.puts "\n   Specified path '#{path}' doesn't exist.".colorize(:red) unless File.exist?(path)
          Core.new(path, @opts).ls
        end
      end
    end

    private

    def flag_given?(flags)
      flags.any? { |flag| @args.include?(flag) }
    end

    def set_color_opts
      light_colors = flag_given? %w[--light]
      dark_colors  = flag_given? %w[--dark]

      if light_colors && dark_colors
        color_scheme = 'dark_colors.yaml'
        STDERR.puts "\n Restrain from using --light and --dark flags together."
          .colorize(@colors[:error])
      elsif light_colors
        color_scheme = 'light_colors.yaml'
      else # default colors
        color_scheme = 'dark_colors.yaml'
      end

      @colors = ColorLS.load_from_yaml(color_scheme, true)
    end

    def fetch_show_opts
      show_dirs_only   = flag_given? %w[-d --dirs]
      show_files_only  = flag_given? %w[-f --files]

      if show_files_only && show_dirs_only
        STDERR.puts "\n  Restrain from using -d and -f flags together."
          .colorize(@colors[:error])
      elsif show_files_only
        :files
      elsif show_dirs_only 
        :dirs
      else
        false
      end
    end

    def fetch_sort_opts
      sort_dirs_first  = flag_given? %w[-sd --sort-dirs --group-directories-first]
      sort_files_first = flag_given? %w[-sf --sort-files]

      if sort_dirs_first && sort_files_first
        STDERR.puts "\n  Restrain from using -sd and -sf flags together."
          .colorize(@colors[:error])
      elsif sort_files_first
        :files 
      elsif sort_dirs_first
        :dirs
      else
        false
      end
    end

    def report_incompatible_flags
      if @opts[:show].nil? || @opts[:sort].nil? 
        ''
      elsif @opts[:tree] && @opts[:report]
        'Restrain from using -t (--tree) and -r (--report) flags together.'
      elsif @opts[:tree] && @opts[:all]
        'Restrain from using -t (--tree) and -a (--all) flags together.'
      else
        nil
      end
    end
  end
end
