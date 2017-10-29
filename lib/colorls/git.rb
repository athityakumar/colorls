module ColorLS
  class Git < Core
    def self.status(repo_path)
      actual = Dir.pwd
      Dir.chdir(repo_path)

      @git_status = {}

      `git status --short`.split("\n").map { |x| x.split(' ') }.each do |mode, file|
        @git_status[file] = mode
      end

      Dir.chdir(actual)
      @git_status
    end

    def self.colored_status_symbols(modes, colors)
      modes =
        case modes.length
        when 1 then "  #{modes} "
        when 2 then " #{modes} "
        when 3 then "#{modes} "
        when 4 then modes
        end

      modes
        .gsub('?', '?'.colorize(colors[:untracked]))
        .gsub('A', 'A'.colorize(colors[:addition]))
        .gsub('M', 'M'.colorize(colors[:modification]))
        .gsub('D', 'D'.colorize(colors[:deletion]))
    end
  end
end
