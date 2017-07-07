module ColorLS
  class Flags
    def initialize(*args)
      @args = args
      @opts = {
        show: fetch_show_opts,
        sort: fetch_sort_opts,
        all: flag_given?(%w[-a --all]),
        report: flag_given?(%w[-r --report]),
        one_per_line: flag_given?(%w[-1])
      }

      return if @opts[:show].nil? || @opts[:sort].nil?

      @args.keep_if { |arg| !arg.start_with?('-') }
    end

    def process
      return Core.new(@opts).ls if @args.empty?

      @args.each do |path|
        next STDERR.puts "\n  Specified directory '#{path}' doesn't exist.".colorize(:red) unless Dir.exist?(path)
        Core.new(path, @opts).ls
      end
    end

    private

    def flag_given?(flags)
      flags.each { |flag| return true if @args.include?(flag) }
      false
    end

    def fetch_show_opts
      show_dirs_only   = flag_given? %w[-d --dirs]
      show_files_only  = flag_given? %w[-f --files]

      if show_files_only && show_dirs_only
        STDERR.puts "\n  Restrain from using -d and -f flags together."
          .colorize(:red)
        return nil
      else
        return :files if show_files_only
        return :dirs  if show_dirs_only
        false
      end
    end

    def fetch_sort_opts
      sort_dirs_first  = flag_given? %w[-sd --sort-dirs]
      sort_files_first = flag_given? %w[-sf --sort-files]

      if sort_dirs_first && sort_files_first
        STDERR.puts "\n  Restrain from using -sd and -sf flags together."
          .colorize(:red)
        return nil
      else
        return :files if sort_files_first
        return :dirs  if sort_dirs_first
        false
      end
    end
  end
end
