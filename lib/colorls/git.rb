module ColorLS
  class Git < Core
    def self.status(repo_path)
      @git_status = {}

      IO.popen(['git', '-C', repo_path, 'status', '--porcelain', '-z', '-unormal', '--ignored']) do |output|
        output.read.split("\x0").map { |x| x.split(' ', 2) }.each do |mode, file|
          @git_status[file] = mode
        end
      end
      warn "git status failed in #{repo_path}" unless $CHILD_STATUS.success?

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
        .tr('!', ' ')
    end
  end
end
