# frozen_string_literal: true

require 'pathname'
require 'set'

module ColorLS
  module Git
    def self.status(repo_path)
      prefix, success = git_prefix(repo_path)

      return unless success

      prefix = Pathname.new(prefix)

      git_status = Hash.new { |hash, key| hash[key] = Set.new }

      git_subdir_status(repo_path) do |mode, file|
        path = Pathname.new(file).relative_path_from(prefix)

        git_status[path.descend.first.cleanpath.to_s].add(mode)
      end
      warn "git status failed in #{repo_path}" unless $CHILD_STATUS.success?

      git_status
    end

    def self.colored_status_symbols(modes, colors)
      if modes.empty?
        return '  ✓ '
               .encode(Encoding.default_external, undef: :replace, replace: '=')
               .colorize(colors[:unchanged])
      end

      modes.to_a.join.uniq.delete('!').rjust(3).ljust(4)
           .sub('?', '?'.colorize(colors[:untracked]))
           .sub('A', 'A'.colorize(colors[:addition]))
           .sub('M', 'M'.colorize(colors[:modification]))
           .sub('D', 'D'.colorize(colors[:deletion]))
    end

    class << self
      private

      def git_prefix(repo_path)
        [
          IO.popen(['git', '-C', repo_path, 'rev-parse', '--show-prefix'], err: :close, &:gets)&.chomp,
          $CHILD_STATUS.success?
        ]
      rescue Errno::ENOENT
        [nil, false]
      end

      def git_subdir_status(repo_path)
        IO.popen(
          ['git', '-C', repo_path, 'status', '--porcelain', '-z', '-unormal', '--ignored', '.'],
          external_encoding: Encoding::ASCII_8BIT
        ) do |output|
          while (status_line = output.gets "\x0")
            mode, file = status_line.chomp("\x0").split(' ', 2)

            yield mode, file

            # skip the next \x0 separated original path for renames, issue #185
            output.gets("\x0") if mode.start_with? 'R'
          end
        end
      end
    end
  end
end
