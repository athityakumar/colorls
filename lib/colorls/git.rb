# frozen_string_literal: true

require 'pathname'
require 'set'

module ColorLS
  module Git
    EMPTY_SET = Set.new.freeze
    private_constant :EMPTY_SET

    def self.status(repo_path)
      prefix, success = git_prefix(repo_path)

      return unless success

      prefix_path = Pathname.new(prefix)

      git_status = Hash.new { |hash, key| hash[key] = Set.new }
      git_status_default = EMPTY_SET

      git_subdir_status(repo_path) do |mode, file|
        if file == prefix
          git_status_default = Set[mode].freeze
        else
          path = Pathname.new(file).relative_path_from(prefix_path)
          git_status[path.descend.first.cleanpath.to_s].add(mode)
        end
      end

      warn "git status failed in #{repo_path}" unless $CHILD_STATUS.success?

      git_status.default = git_status_default
      git_status.freeze
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
          IO.popen(['git', '-C', repo_path, 'rev-parse', '--show-prefix'], err: File::NULL, &:gets)&.chomp,
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
