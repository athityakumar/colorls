# frozen_string_literal: true

module ColorLS
  module Git
    def self.status(repo_path)
      prefix = IO.popen(['git', '-C', repo_path, 'rev-parse', '--show-prefix'], err: :close, &:gets)

      return unless $CHILD_STATUS.success?

      prefix.chomp!
      git_status = {}

      IO.popen(['git', '-C', repo_path, 'status', '--porcelain', '-z', '-unormal', '--ignored', '.']) do |output|
        while (status_line = output.gets "\x0")
          mode, file = status_line.chomp("\x0").split(' ', 2)

          git_status[file.delete_prefix(prefix)] = mode

          # skip the next \x0 separated original path for renames, issue #185
          output.gets("\x0") if mode.start_with? 'R'
        end
      end
      warn "git status failed in #{repo_path}" unless $CHILD_STATUS.success?

      git_status
    end

    def self.colored_status_symbols(modes, colors)
      modes = modes.rjust(3).ljust(4)

      modes
        .gsub('?', '?'.colorize(colors[:untracked]))
        .gsub('A', 'A'.colorize(colors[:addition]))
        .gsub('M', 'M'.colorize(colors[:modification]))
        .gsub('D', 'D'.colorize(colors[:deletion]))
        .tr('!', ' ')
    end
  end
end
